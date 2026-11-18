-- =================================================================
-- SecretChecklistTabGuides.lua
-- Builds the Guides journal tab panel.
--
-- SC:BuildGuidesPanel(frame, L) is called by Initialize() in
-- SecretChecklistFrame.lua after the filter dropdown is configured.
--
-- Shared state access:
--   SC:GetShowCollected()  -- returns whether collected items are shown
--   SC:GetShowMissing()    -- returns whether missing items are shown
--   SC:GetFilterKinds()   -- returns the active kind-filter table
--   SC.onFilterChange     -- set here; called by OnFilterChanged in Frame.lua
--   SC.guidesSearchBox    -- set here; used by SwitchTab to anchor FilterDropdown
--   SC.guidesPanel        -- set here; used by SwitchTab to show/hide
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

local math_min, math_max = math.min, math.max
local math_rad = math.rad
local select = select

-- File-level locale accessor. BuildGuidesPanel also receives L as a parameter
-- (the same table); this one serves the module-scope helpers defined above it.
local L = _G.SecretChecklistLocale or {}

-- Colour used for each secret kind in tooltips and the detail pane kind label.
-- Defined once at module level so neither MakeReqLinkRow nor Guides_ShowDetail
-- allocate a new table on every call.
-- Sets a single waypoint, preferring TomTom when the player has it.
--
-- C_Map.SetUserWaypoint raises a Lua error for a map that does not accept user
-- waypoints -- instance interiors among them, and the step data contains
-- dungeon coordinates -- so the map has to be checked first. Previously four
-- copies of this logic called it unguarded.
--
-- Returns true if a waypoint was placed.
local function SetWaypoint(wp, label)
	if not (wp and wp.mapID and wp.x and wp.y) then return false end

	if TomTom and TomTom.AddWaypoint then
		TomTom:AddWaypoint(wp.mapID, wp.x, wp.y, { title = label or "", from = "Secret Checklist" })
		return true
	end

	if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(wp.mapID) then
		print("|cffffcc00SecretChecklist:|r " .. (L["GUIDES_WAYPOINT_UNSUPPORTED"]
			or "Blizzard's waypoint system does not support that location. "
			.. "Install TomTom for waypoints there."))
		return false
	end

	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(wp.mapID, wp.x, wp.y))
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)
	return true
end

-- Sets every waypoint in a list. Blizzard's user waypoint is a single pin, so
-- without TomTom only the first can be placed -- say so rather than silently
-- dropping the rest, which is what the previous code did.
local function SetWaypoints(list, label)
	if not list or #list == 0 then return false end

	if TomTom and TomTom.AddWaypoint then
		local placed = false
		for _, wp in ipairs(list) do
			local title = wp.label and ((label or "") .. ": " .. wp.label) or label
			placed = SetWaypoint(wp, title) or placed
		end
		return placed
	end

	local placed = SetWaypoint(list[1], label)
	if placed and #list > 1 then
		print("|cffffcc00SecretChecklist:|r " .. (L["GUIDES_WAYPOINT_PARTIAL"]
			or "Set the first of %d waypoints. Install TomTom to place them all at once.")
			:format(#list))
	end
	return placed
end

-- Status markers.
--
-- Collected/missing was signalled by a coloured dot and nothing else. Red and
-- green are indistinguishable to a substantial minority of players, so the
-- status of a row was simply unreadable for them. A glyph makes shape carry the
-- meaning and leaves colour as reinforcement.
--
-- The atlases are checked for existence rather than assumed: SetAtlas on a name
-- the client does not have fails silently and leaves a blank texture, which
-- would be worse than the coloured dot it replaced.
local STATUS_ATLAS = {
	collected = "common-icon-checkmark",
	missing   = "common-icon-redx",
}

local atlasAvailable = {}
local function HasAtlas(name)
	if atlasAvailable[name] == nil then
		atlasAvailable[name] = (C_Texture and C_Texture.GetAtlasInfo
			and C_Texture.GetAtlasInfo(name)) and true or false
	end
	return atlasAvailable[name]
end

-- Paints a status marker, falling back to the original coloured square when the
-- atlas is unavailable. `size` is the fallback dot size; glyphs get a little more
-- room so the shape is legible.
local function SetStatusMarker(tex, status, size, r, g, b)
	local atlas = STATUS_ATLAS[status]
	if atlas and HasAtlas(atlas) then
		tex:SetSize(size + 6, size + 6)
		tex:SetAtlas(atlas)
		tex:SetVertexColor(1, 1, 1, 1)
	else
		tex:SetSize(size, size)
		tex:SetColorTexture(r, g, b)
	end
end

local kindColors = {
	mount       = { 0.6, 0.8, 1 },
	pet         = { 0.6, 1, 0.6 },
	toy         = { 1, 0.6, 1 },
	achievement = { 1, 0.82, 0 },
	quest       = { 1, 0.7, 0.3 },
	transmog    = { 0.8, 0.6, 1 },
	housing     = { 1, 0.85, 0.5 },
	mystery     = { 0.7, 0.5, 1 },
}

function SC:BuildGuidesPanel(frame, L)
	-- ==============================================
	-- PANEL FRAME
	-- ==============================================

	SC.guidesPanel = CreateFrame("Frame", nil, frame.Inset)
	SC.guidesPanel:SetAllPoints(frame.Inset)
	SC.guidesPanel:Hide()
	local guidesPanel       = SC.guidesPanel -- local alias for readability

	-- ---- dimension constants ----
	local GP_LEFT_W         = 240   -- width of the list pane
	local GP_DIV_W          = 2     -- divider strip
	local GP_PAD            = 8     -- general padding
	local GP_ROW_H          = 44    -- height of each list row
	local GP_TOP_DRP        = GP_PAD + 20 -- total drop from panel top to list pane start
	local GP_SEARCH_H       = 20    -- search box height
	local GP_SEARCH_DROP    = GP_SEARCH_H + 6 -- list content starts this far below the pane top

	-- ---- per-panel state ----
	local guides_entries    = {} -- filtered entry list
	local guides_rowButtons = {} -- row button frames in scrollChild
	local guides_selected   = nil -- currently selected entry
	local guides_scrollPos  = 0  -- persists scroll position across tab switches (WoW resets GetVerticalScroll on hide)
	local scrollFrame, scrollBar -- scroll widgets assigned in Left Pane section below
	local currentNumSteps   = 0  -- step count for the currently displayed entry

	-- ==============================================
	-- FILTERING  (reads shared filter state via SC accessors)
	-- ==============================================

	-- Free-text search, applied on top of the shared filter state.
	local guides_searchText = ""

	-- Matches a search term against everything a player might reasonably type:
	-- the name, the kind, the source and description shown in the detail pane,
	-- and the step labels and notes. Searching only names would miss "Kosumoth"
	-- or "Tazavesh", which are how people actually refer to these secrets.
	-- Matches the term against the value and, on a translated client, against its
	-- translation too. Searching only the rendered text would leave a player
	-- unable to find a secret by a name they saw on Wowhead; searching only the
	-- English would make the search box useless in their own language.
	local function Matches(value, term)
		if type(value) ~= "string" then return false end
		if value:lower():find(term, 1, true) then return true end
		local translated = SC:T(value)
		return translated ~= value and translated:lower():find(term, 1, true) ~= nil
	end

	local function EntryMatchesSearch(entry, term)
		-- Both names matter. GetEntryName returns the game's own localised name
		-- ("Hungering Claw"), while entry.name is the data file's, which carries
		-- the disambiguators people actually search for -- "Hungering Claw
		-- (Kosumoth)".
		if Matches(SC:GetEntryName(entry), term) then return true end
		if Matches(entry.name, term) then return true end
		-- entry.kind is deliberately not searched here; see KindForTerm.
		if Matches(entry.source, term) then return true end
		if Matches(entry.desc, term) then return true end
		if Matches(entry.partOf, term) then return true end
		if Matches(entry.stepsRef, term) then return true end

		-- Checked one by one rather than by iterating a list of them: most of
		-- these fields are absent on most entries, and ipairs stops dead at the
		-- first nil. Collecting them into a table meant an entry with no `source`
		-- never had its `partOf` looked at -- which is exactly why searching
		-- "kosumoth" found Fathom Dweller but not Hungering Claw.
		for _, step in ipairs(entry.steps or {}) do
			if Matches(step.label, term) or Matches(step.note, term) then return true end
			for _, sub in ipairs(step.substeps or {}) do
				if Matches(sub.label, term) or Matches(sub.note, term) then return true end
			end
		end
		return false
	end

	-- Maps a search term that IS a type name onto that type.
	--
	-- entry.kind used to be searched as ordinary text, which meant "pet" matched
	-- every entry whose notes happened to mention a pet, and matched the kind
	-- itself only as an English substring -- so a Russian client got neither
	-- behaviour. Typing a type name is a request to see that type, not to find
	-- the word, so an exact match selects it: "pet", "pets" and the player's own
	-- localised "Питомцы" all filter to pets, while "petri" still searches text.
	--
	-- Built on first use rather than at file scope: the locale table is
	-- populated by then, and most sessions never search at all.
	local kindTerms
	local function KindForTerm(term)
		if not kindTerms then
			kindTerms = {}
			local KIND_KEYS = {
				mount       = { "KIND_MOUNT",       "KIND_MOUNTS" },
				pet         = { "KIND_PET",         "KIND_PETS" },
				toy         = { "KIND_TOY",         "KIND_TOYS" },
				achievement = { "KIND_ACHIEVEMENT", "KIND_ACHIEVEMENTS" },
				quest       = { "KIND_QUEST",       "KIND_QUESTS" },
				transmog    = { "KIND_TRANSMOG",    "KIND_TRANSMOGS" },
				housing     = { "KIND_HOUSING",     "KIND_HOUSINGS" },
				mystery     = { "KIND_MYSTERY",     "KIND_MYSTERIES" },
			}
			for kind, keys in pairs(KIND_KEYS) do
				kindTerms[kind] = kind
				kindTerms[kind .. "s"] = kind
				for _, key in ipairs(keys) do
					local label = L[key]
					if type(label) == "string" and label ~= "" then
						kindTerms[label:lower()] = kind
					end
				end
			end
			-- English plurals the "+s" rule gets wrong.
			kindTerms["mysteries"] = "mystery"
		end
		return kindTerms[term]
	end

	local function Guides_ApplyFilter()
		local entries = SC:GetFilteredEntries()
		if guides_searchText == "" then
			guides_entries = entries
			return
		end
		local searchKind = KindForTerm(guides_searchText)
		local matched = {}
		for _, entry in ipairs(entries) do
			local hit
			if searchKind then
				hit = (entry.kind == searchKind)
			else
				hit = EntryMatchesSearch(entry, guides_searchText)
			end
			if hit then
				matched[#matched + 1] = entry
			end
		end
		guides_entries = matched
	end

	-- forward declarations for mutual recursion
	local Guides_RefreshList
	local Guides_ShowDetail

	-- Called by OnFilterChanged (user changed a filter) -- resets scroll to top.
	SC.onFilterChange = function()
		guides_scrollPos = 0
		if scrollFrame then scrollFrame:SetVerticalScroll(0) end
		if scrollBar then scrollBar:SetValue(0) end
		Guides_ApplyFilter()
		Guides_RefreshList()
	end

	-- Called by background collection events -- preserves scroll position.
	SC.onCollectionRefresh = function()
		Guides_ApplyFilter()
		Guides_RefreshList()
	end

	-- ==============================================
	-- LEFT LIST PANE
	-- (starts GP_TOP_DRP px below panel top)
	-- ==============================================

	local listPane = CreateFrame("Frame", nil, guidesPanel)
	listPane:SetPoint("TOPLEFT", guidesPanel, "TOPLEFT", GP_PAD, -GP_TOP_DRP)
	listPane:SetPoint("BOTTOMLEFT", guidesPanel, "BOTTOMLEFT", GP_PAD, GP_PAD)
	listPane:SetWidth(GP_LEFT_W)

	-- Search box, at the top of the list column.
	--
	-- Entries in a fixed-height list with no way to jump to one: finding "Uuna"
	-- meant scrolling and reading. SearchBoxTemplate gives the magnifier, the
	-- placeholder and the clear button for free, and matches the search boxes in
	-- Blizzard's own journals.
	--
	-- It sits INSIDE the list pane. It used to be anchored above it, in the strip
	-- between the panel top and the list -- which is the strip the shared
	-- progress counters live in ("40 / 54 Secrets" is drawn from the left there)
	-- and the strip PortraitFrameTemplate draws its circle over. So on the
	-- Default theme the counter text showed through the box and the portrait
	-- covered its left end. EllesmereUI and ElvUI hid the collision rather than
	-- avoiding it: both fade the portrait to alpha 0.
	local searchBox = CreateFrame("EditBox", nil, guidesPanel, "SearchBoxTemplate")
	searchBox:SetPoint("TOPLEFT", listPane, "TOPLEFT", 4, -2)
	searchBox:SetPoint("TOPRIGHT", listPane, "TOPRIGHT", 0, -2)
	searchBox:SetHeight(GP_SEARCH_H)
	-- Never steal keyboard focus when the tab opens.
	searchBox:SetAutoFocus(false)
	searchBox:SetScript("OnTextChanged", function(self)
		-- The template's own handler drives the placeholder text and the clear
		-- button; SetScript replaces it, so it has to be called explicitly.
		if SearchBoxTemplate_OnTextChanged then
			SearchBoxTemplate_OnTextChanged(self)
		end
		local text = (self:GetText() or ""):lower()
		if text == guides_searchText then return end
		guides_searchText = text
		-- Reuse the filter-changed path: it resets scroll to the top, which is
		-- what you want when the result set changes underneath you.
		SC.onFilterChange()
	end)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	SC.guidesSearchBox = searchBox

	-- ScrollFrame: clips the list rows and handles vertical scrolling
	scrollFrame = CreateFrame("ScrollFrame", nil, listPane)
	scrollFrame:SetPoint("TOPLEFT", listPane, "TOPLEFT", 0, -GP_SEARCH_DROP)
	scrollFrame:SetPoint("BOTTOMRIGHT", listPane, "BOTTOMRIGHT", 0, 0)

	-- Export top-right of listPane so SwitchTab can anchor FilterDropdown here
	SC.guidesListPane = listPane

	-- ScrollChild: all row buttons live here; height is set per filter result
	local scrollChild = CreateFrame("Frame")
	scrollChild:SetWidth(GP_LEFT_W)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	-- Scrollbar: plain Slider (no UIPanelScrollBarTemplate = no SetVerticalScroll callback)
	scrollBar = CreateFrame("Slider", nil, guidesPanel)
	scrollBar:SetOrientation("VERTICAL")
	scrollBar:SetWidth(6)
	-- Top follows the scroll area, not the pane, so the bar does not run up
	-- alongside the search box.
	scrollBar:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 4, -(GP_SEARCH_DROP + 8))
	scrollBar:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 4, 16)
	scrollBar:SetMinMaxValues(0, 0)
	scrollBar:SetValueStep(GP_ROW_H)
	scrollBar:SetObeyStepOnDrag(true)
	scrollBar:SetThumbTexture("Interface\\ChatFrame\\ChatFrameBackground")
	local sbThumb = scrollBar:GetThumbTexture()
	if sbThumb then
		local dThumb = SC:ThemeColor("divider")
		sbThumb:SetColorTexture(dThumb[1], dThumb[2], dThumb[3], dThumb[4])
		sbThumb:SetWidth(6)
		sbThumb:SetHeight(20)
	end
	scrollBar:SetValue(0)
	scrollBar:SetScript("OnValueChanged", function(self, val)
		guides_scrollPos = val
		scrollFrame:SetVerticalScroll(val)
	end)

	-- Vertical divider
	local divider = guidesPanel:CreateTexture(nil, "BACKGROUND")
	divider:SetWidth(GP_DIV_W)
	divider:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 16, 0)      -- 6 (scrollbar) + 10
	divider:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 16, 0)
	local dC = SC:ThemeColor("divider")
	divider:SetColorTexture(dC[1], dC[2], dC[3], dC[4])
	SC.themeTargets           = SC.themeTargets or {}
	SC.themeTargets.divider   = divider
	SC.themeTargets.scrollBar = scrollBar

	-- ==============================================
	-- RIGHT DETAIL PANE
	-- ==============================================

	local DP_SCROLL_W         = 8            -- width of the text-section scrollbar
	local DP_LINK_AREA        = GP_PAD + 22 + GP_PAD -- vertical room for linkBtn (padding + height + padding)
	local DP_TAB_H            = 26           -- height of the Info / Model sub-tab bar
	local DP_TAB_TOP          = 8            -- gap above the tab bar

	-- "horizontal" = Info/Model bar across the top of the detail pane
	-- "sidetabs"   = SpellBook-style CheckButtons on the right edge (ManuscriptsJournal look)
	local guidesStyle         = "sidetabs"

	-- ---- v2: ManuscriptsJournal / SpellBook skill-line tab builder ----
	local function MakeSkillLineTab(iconID, tooltipText)
		local btn = CreateFrame("CheckButton", nil, guidesPanel)
		btn:SetSize(32, 32)
		local bgTex = btn:CreateTexture(nil, "BACKGROUND")
		bgTex:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
		bgTex:SetSize(64, 64)
		bgTex:SetPoint("TOPLEFT", btn, "TOPLEFT", -3, 11)
		btn.bgTex = bgTex
		-- OVERLAY so the icon stays visible when the button is checked
		local iconTex = btn:CreateTexture(nil, "OVERLAY")
		iconTex:SetTexture(iconID)
		iconTex:SetAllPoints(btn)
		iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		btn.iconTex = iconTex
		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		btn:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
		local ct = btn:GetCheckedTexture()
		if ct then ct:SetBlendMode("ADD") end
		btn.tooltip = tooltipText
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltip)
		end)
		btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		return btn
	end

	local detailPane = CreateFrame("Frame", nil, guidesPanel)
	detailPane:SetPoint("TOPLEFT", divider, "TOPRIGHT", GP_PAD, 0)
	detailPane:SetPoint("BOTTOMRIGHT", guidesPanel, "BOTTOMRIGHT", -15, GP_PAD)

	-- ---- Info / Model sub-tab bar ----
	local detailTabBar = CreateFrame("Frame", nil, detailPane)
	detailTabBar:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, -DP_TAB_TOP)
	detailTabBar:SetPoint("TOPRIGHT", detailPane, "TOPRIGHT", 0, -DP_TAB_TOP)
	detailTabBar:SetHeight(DP_TAB_H)

	local function MakeDetailTab(label)
		local btn = CreateFrame("Button", nil, detailTabBar)
		local bg = btn:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.10, 0.10, 0.14, 0.70)
		btn.bg = bg
		local hl = btn:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, 0.06)
		btn:SetHighlightTexture(hl)
		local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		lbl:SetAllPoints()
		lbl:SetJustifyH("CENTER")
		lbl:SetText(label)
		btn.lbl = lbl
		return btn
	end

	local infoTab  = MakeDetailTab(L["GUIDES_TAB_INFO"] or "Info")
	local modelTab = MakeDetailTab(L["GUIDES_TAB_MODEL"] or "Model")
	-- Split tab bar in half: "BOTTOM" anchor = horizontal center of parent
	infoTab:SetPoint("TOPLEFT", detailTabBar, "TOPLEFT", 0, 0)
	infoTab:SetPoint("BOTTOMRIGHT", detailTabBar, "BOTTOM", 0, 0)
	modelTab:SetPoint("TOPLEFT", detailTabBar, "TOP", 0, 0)
	modelTab:SetPoint("BOTTOMRIGHT", detailTabBar, "BOTTOMRIGHT", 0, 0)

	-- Vertical divider between tabs and horizontal line below bar
	local tabMidLine = detailTabBar:CreateTexture(nil, "BORDER")
	tabMidLine:SetWidth(1)
	tabMidLine:SetPoint("TOPLEFT", infoTab, "TOPRIGHT", 0, 0)
	tabMidLine:SetPoint("BOTTOMLEFT", infoTab, "BOTTOMRIGHT", 0, 0)
	tabMidLine:SetColorTexture(0.3, 0.25, 0.15, 0.6)
	local tabBarLine = detailTabBar:CreateTexture(nil, "BORDER")
	tabBarLine:SetHeight(1)
	tabBarLine:SetPoint("BOTTOMLEFT", detailTabBar, "BOTTOMLEFT", 0, 0)
	tabBarLine:SetPoint("BOTTOMRIGHT", detailTabBar, "BOTTOMRIGHT", 0, 0)
	tabBarLine:SetColorTexture(0.3, 0.25, 0.15, 0.5)

	-- ---- Skill-line side-tab buttons (sidetabs style; shown/hidden by ApplyGuideStyle) ----
	-- Icons: inv-misc-notescript1d (Info) and inv-misc-notepicture1a (Model)
	local infoSkBtn       = MakeSkillLineTab(1505956, L["GUIDES_TAB_INFO"] or "Info")
	local modelSkBtn      = MakeSkillLineTab(1505947, L["GUIDES_TAB_MODEL"] or "Model")
	SC.guidesSkillTabBtns = { infoSkBtn, modelSkBtn }
	infoSkBtn:SetPoint("TOPLEFT", detailPane, "TOPRIGHT", 22, -36)
	modelSkBtn:SetPoint("TOPLEFT", infoSkBtn, "BOTTOMLEFT", 0, -17)
	-- Hidden until ApplyGuideStyle("sidetabs") activates them
	infoSkBtn:Hide()
	modelSkBtn:Hide()

	-- Sub-panes: both sit below the tab bar, above the Wowhead link button
	local infoPane = CreateFrame("Frame", nil, detailPane)
	infoPane:SetPoint("TOPLEFT", detailTabBar, "BOTTOMLEFT", 0, -2)
	infoPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
	local modelPane = CreateFrame("Frame", nil, detailPane)
	modelPane:SetPoint("TOPLEFT", detailTabBar, "BOTTOMLEFT", 0, -2)
	modelPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
	modelPane:Hide()

	-- Tab switching logic (branches on guidesStyle; set by ApplyGuideStyle)
	local activeDetailTab = "info"
	local SwitchDetailTab -- forward declaration so SetModelTabEnabled can call it
	local SetModelTabEnabled
	SetModelTabEnabled = function(enabled)
		if guidesStyle == "sidetabs" then
			modelSkBtn.hasModel = enabled
			infoSkBtn:SetShown(enabled)
			modelSkBtn:SetShown(enabled)
			if not enabled and activeDetailTab == "model" then
				SwitchDetailTab("info")
			end
		else -- "horizontal"
			modelTab.hasModel = enabled
			if enabled then
				-- Show the tab bar and anchor panes below it
				detailTabBar:Show()
				infoPane:ClearAllPoints()
				infoPane:SetPoint("TOPLEFT", detailTabBar, "BOTTOMLEFT", 0, -2)
				infoPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
				modelPane:ClearAllPoints()
				modelPane:SetPoint("TOPLEFT", detailTabBar, "BOTTOMLEFT", 0, -2)
				modelPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
			else
				-- No model: hide the tab bar but preserve the same top margin as when it is shown
				detailTabBar:Hide()
				local noTabTop = -(DP_TAB_TOP + DP_TAB_H + 2)
				infoPane:ClearAllPoints()
				infoPane:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, noTabTop)
				infoPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
				modelPane:ClearAllPoints()
				modelPane:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, noTabTop)
				modelPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
				if activeDetailTab == "model" then
					SwitchDetailTab("info")
				end
			end
		end
	end
	SwitchDetailTab = function(which)
		activeDetailTab = which
		infoPane:SetShown(which == "info")
		modelPane:SetShown(which == "model")
		if guidesStyle == "sidetabs" then
			infoSkBtn:SetChecked(which == "info")
			if modelSkBtn:IsShown() then
				modelSkBtn:SetChecked(which == "model")
			end
		else -- "horizontal"
			-- Active tab: brighter bg + gold text; inactive: darker + grey (dimmer if disabled)
			infoTab.bg:SetColorTexture(which == "info" and 0.20 or 0.10, which == "info" and 0.20 or 0.10,
				which == "info" and 0.28 or 0.14, 0.95)
			modelTab.bg:SetColorTexture(which == "model" and 0.20 or 0.10, which == "model" and 0.20 or 0.10,
				which == "model" and 0.28 or 0.14, 0.95)
			if which == "info" then
				infoTab.lbl:SetTextColor(1, 0.82, 0)
				local g = modelTab.hasModel and 0.6 or 0.35
				modelTab.lbl:SetTextColor(g, g, g)
			else
				infoTab.lbl:SetTextColor(0.6, 0.6, 0.6)
				modelTab.lbl:SetTextColor(1, 0.82, 0)
			end
		end
	end
	SwitchDetailTab("info")
	infoTab:SetScript("OnClick", function() SwitchDetailTab("info") end)
	modelTab:SetScript("OnClick", function()
		if modelTab.hasModel then SwitchDetailTab("model") end
	end)
	infoSkBtn:SetScript("OnClick", function() SwitchDetailTab("info") end)
	modelSkBtn:SetScript("OnClick", function()
		if modelSkBtn.hasModel then SwitchDetailTab("model") end
	end)

	-- ---- Scrollable text section (fills infoPane entirely) ----
	local detailScroll = CreateFrame("ScrollFrame", nil, infoPane)
	detailScroll:SetPoint("TOPLEFT", infoPane, "TOPLEFT", 0, 0)
	detailScroll:SetPoint("BOTTOMRIGHT", infoPane, "BOTTOMRIGHT", -(DP_SCROLL_W + 4), 0)

	local detailContent = CreateFrame("Frame")
	detailContent:SetWidth(300) -- corrected to match scroll width each time an entry is shown
	detailContent:SetHeight(500) -- overwritten by Guides_UpdateDetailScroll
	detailScroll:SetScrollChild(detailContent)

	local detailScrollBar = CreateFrame("Slider", nil, infoPane)
	detailScrollBar:SetOrientation("VERTICAL")
	detailScrollBar:SetWidth(DP_SCROLL_W)
	detailScrollBar:SetPoint("TOPLEFT", detailScroll, "TOPRIGHT", 4, 0)
	detailScrollBar:SetPoint("BOTTOMLEFT", detailScroll, "BOTTOMRIGHT", 4, 0)
	detailScrollBar:SetMinMaxValues(0, 0)
	detailScrollBar:SetThumbTexture("Interface\\ChatFrame\\ChatFrameBackground")
	local dsbThumb = detailScrollBar:GetThumbTexture()
	if dsbThumb then
		local dT = SC:ThemeColor("divider")
		dsbThumb:SetColorTexture(dT[1], dT[2], dT[3], dT[4])
		dsbThumb:SetWidth(DP_SCROLL_W)
		dsbThumb:SetHeight(20)
	end
	detailScrollBar:SetValue(0)
	detailScrollBar:SetShown(false)
	detailScrollBar:SetScript("OnValueChanged", function(_, val)
		detailScroll:SetVerticalScroll(val)
	end)
	detailScroll:SetScript("OnMouseWheel", function(_, delta)
		local _, maxV = detailScrollBar:GetMinMaxValues()
		local newVal  = math_max(0, math_min(maxV, detailScrollBar:GetValue() - delta * 30))
		detailScrollBar:SetValue(newVal)
	end)

	-- All text/step widgets are children of detailContent so they scroll with detailScroll.

	-- Icon (plain, no collection border)
	local detailIcon = detailContent:CreateTexture(nil, "ARTWORK")
	detailIcon:SetSize(48, 48)
	detailIcon:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 0, -GP_PAD)
	detailIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Entry name (right of icon, vertically centered with icon)
	local detailName = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	detailName:SetPoint("LEFT", detailIcon, "RIGHT", 10, 0)
	detailName:SetPoint("RIGHT", detailContent, "RIGHT", -6, 0)
	detailName:SetJustifyH("LEFT")
	detailName:SetWordWrap(false)

	-- Kind badge (below icon)
	local detailKind = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	detailKind:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0, -8)

	-- Collected / missing status
	local detailStatus = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailStatus:SetPoint("TOPLEFT", detailKind, "BOTTOMLEFT", 0, -4)
	detailStatus:SetJustifyH("LEFT")

	-- Source (gold, word-wrapped)
	local detailSource = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailSource:SetPoint("TOPLEFT", detailStatus, "BOTTOMLEFT", 0, -6)
	detailSource:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", -6, 0)
	detailSource:SetJustifyH("LEFT")
	detailSource:SetTextColor(1, 0.82, 0)
	detailSource:SetWordWrap(true)

	-- Description (grey, word-wrapped)
	local detailDesc = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailDesc:SetPoint("TOPLEFT", detailSource, "BOTTOMLEFT", 0, -6)
	detailDesc:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", -6, 0)
	detailDesc:SetJustifyH("LEFT")
	detailDesc:SetTextColor(0.8, 0.8, 0.8)
	detailDesc:SetWordWrap(true)

	-- ---- Requirement cross-reference links (shown between description and steps) ----
	-- reqLastWidget tracks the bottommost visible widget above the steps header;
	-- updated in Guides_ShowDetail each time an entry is displayed.
	local reqLastWidget = detailDesc

	local function MakeReqLinkRow()
		local row = CreateFrame("Frame", nil, detailContent)
		row:SetHeight(20)
		row:Hide()

		local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
		lbl:SetPoint("TOP", row, "TOP", 0, 0)
		lbl:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
		lbl:SetTextColor(0.55, 0.55, 0.55)
		row.lbl = lbl

		local btn = CreateFrame("Button", nil, row)
		local btnHL = btn:CreateTexture(nil, "HIGHLIGHT")
		btnHL:SetAllPoints()
		btnHL:SetColorTexture(0.4, 0.78, 1, 0.06)
		btn:SetHighlightTexture(btnHL)
		local btnLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		btnLbl:SetAllPoints()
		btnLbl:SetJustifyH("LEFT")
		btnLbl:SetTextColor(0.4, 0.78, 1)
		btn.lbl = btnLbl
		btn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
		btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		btn:SetPoint("TOP", row, "TOP", 0, 0)
		btn:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
		btn:SetScript("OnEnter", function(self)
			if not self.targetEntry then return end
			local e  = self.targetEntry
			local kc = kindColors[e.kind] or { 0.8, 0.8, 0.8 }
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(e.name or "?", 1, 0.82, 0)
			local kindStr = e.kind and (e.kind:sub(1, 1):upper() .. e.kind:sub(2)) or ""
			GameTooltip:AddLine(kindStr, kc[1], kc[2], kc[3])
			local st = SC:GetEntryStatus(e) or "unknown"
			if st == "collected" then
				GameTooltip:AddLine(L["TOOLTIP_COLLECTED"] or "Collected", 0, 1, 0)
			elseif st == "missing" then
				GameTooltip:AddLine(L["TOOLTIP_NOT_COLLECTED"] or "Not collected", 1, 0, 0)
			end
			GameTooltip:AddLine(L["GUIDES_CLICK_VIEW"] or "Click to view", 0.55, 0.55, 0.55)
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		btn:SetScript("OnClick", function(self)
			local target = self.targetEntry
			if not target then return end
			-- Find and click the matching list row if it is visible in the current filter
			for _, r in pairs(guides_rowButtons) do
				if r.entry == target then
					r:Click()
					for i, e in ipairs(guides_entries) do
						if e == target then
							local visH       = scrollFrame:GetHeight() or 0
							local targetY    = (i - 1) * GP_ROW_H
							local scrollTo   = math_max(0, targetY - math_max(0, (visH - GP_ROW_H) / 2))
							local maxScroll  = math_max(0, #guides_entries * GP_ROW_H - visH)
							scrollTo         = math_min(scrollTo, maxScroll)
							guides_scrollPos = scrollTo
							scrollFrame:SetVerticalScroll(scrollTo)
							scrollBar:SetValue(scrollTo)
							break
						end
					end
					return
				end
			end
			-- Entry not in current filter; show its detail directly
			Guides_ShowDetail(target)
		end)
		row.btn = btn
		return row
	end

	local REQ_POOL_SIZE = 4
	local requiresRows, requiredForRows = {}, {}
	for i = 1, REQ_POOL_SIZE do
		requiresRows[i]    = MakeReqLinkRow()
		requiredForRows[i] = MakeReqLinkRow()
	end

	-- Wowhead guide link button — same visual template as the Filter dropdown
	-- DropdownButton + WowStyle1FilterDropdownTemplate gives the identical look.
	-- SetScript("OnClick") replaces the built-in dropdown-open handler entirely,
	-- so clicking shows our copy popup instead of a menu.
	local linkBtn = CreateFrame("DropdownButton", nil, detailPane, "WowStyle1FilterDropdownTemplate")
	linkBtn:SetSize(90, 22)
	linkBtn:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, GP_PAD)
	linkBtn:SetText(L["GUIDES_GUIDE_BUTTON"] or "Guide")
	linkBtn.currentURL = ""
	linkBtn:SetEnabled(false) -- greyed until a URL is present
	SC.guidesLinkBtn = linkBtn -- exported for theme skinning
	-- Hide the dropdown arrow — iterate regions to find it by texture path/atlas
	for _, region in ipairs({ linkBtn:GetRegions() }) do
		local rtype = region.GetObjectType and region:GetObjectType()
		if rtype == "Texture" then
			local atlas = region.GetAtlas and region:GetAtlas()
			local file  = region.GetTexture and region:GetTexture()
			if (atlas and atlas:lower():find("arrow")) or (type(file) == "string" and file:lower():find("arrow")) then
				region:Hide()
			end
		end
	end
	linkBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["GUIDES_GUIDE_BUTTON"] or "Guide", 1, 0.82, 0)
		if self.currentURL ~= "" then
			GameTooltip:AddLine(L["GUIDES_CLICK_COPY"] or "Click to copy link", 0.8, 0.8, 0.8)
		else
			GameTooltip:AddLine(L["GUIDES_NO_GUIDE_LINK"] or "No guide link yet", 0.6, 0.6, 0.6)
		end
		GameTooltip:Show()
	end)
	linkBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	linkBtn:SetScript("OnClick", function(self)
		SC:ShowCopyDialog(self, self.currentURL)
	end)

	-- ==============================================
	-- PROGRESS STEPS  (shown only for entries with a steps table)
	-- ==============================================

	local STEP_ROW_H = 18

	-- Forward-declare so step-row OnClick closures can reference these before they are defined below.
	local Guides_RelayoutSteps, Guides_UpdateDetailScroll
	local STEP_NOTE_INDENT = 14   -- note panels are indented; step headers stay flush left
	local STEP_NOTE_PAD    = 5    -- vertical padding inside note panel
	local stepsCollapsed   = false -- expanded by default; auto-collapsed for collected entries

	-- Step rows and their substep rows are built on demand and then reused.
	--
	-- This used to be a pre-allocated cross-product: the largest entry has 31
	-- steps and the largest single step has 13 substeps, so 31 step rows were
	-- built at load, each carrying 13 substep rows, each of those carrying a
	-- nested waypoint button -- roughly 2,900 frames and regions created before
	-- the window had ever been opened, for a data set where only 10 of 52 entries
	-- have substeps at all. It also grew quadratically: one new long secret moved
	-- the whole product.
	--
	-- Creating on demand means a session that browses five secrets builds a few
	-- dozen rows. It also removes the truncation bug in the old scheme, where the
	-- substep cap was measured from `substeps` only and silently dropped rows for
	-- any longer `factionSubsteps` list.
	local stepRows = {}

	local function CreateStepRow()
		-- ---- Header row ----
		local row = CreateFrame("Button", nil, detailContent)
		row:SetHeight(STEP_ROW_H)
		local rowHL = row:CreateTexture(nil, "HIGHLIGHT")
		rowHL:SetAllPoints()
		rowHL:SetColorTexture(1, 1, 1, 0.04)
		row:SetHighlightTexture(rowHL)

		local rowBg = row:CreateTexture(nil, "BACKGROUND")
		rowBg:SetAllPoints()
		rowBg:SetColorTexture(0.10, 0.10, 0.16, 0.55)

		local arrowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		arrowLbl:SetPoint("LEFT", row, "LEFT", 4, 0)
		arrowLbl:SetTextColor(0.4, 0.78, 1)
		arrowLbl:SetText("+")
		row.arrowLbl = arrowLbl

		local ico = row:CreateTexture(nil, "ARTWORK")
		ico:SetSize(10, 10)
		ico:SetPoint("LEFT", row, "LEFT", 20, 0)
		row.ico = ico

		local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		lbl:SetPoint("LEFT", ico, "RIGHT", 5, 0)
		lbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		lbl:SetJustifyH("LEFT")
		lbl:SetWordWrap(true)
		row.lbl = lbl

		-- ---- Note panel (shown below the header row when the step is expanded) ----
		local np = CreateFrame("Frame", nil, detailContent)
		np:Hide()
		local npBg = np:CreateTexture(nil, "BACKGROUND")
		npBg:SetAllPoints()
		npBg:SetColorTexture(0.07, 0.07, 0.11, 0.65)

		local noteLbl = np:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noteLbl:SetPoint("TOPLEFT", np, "TOPLEFT", 5, -STEP_NOTE_PAD)
		noteLbl:SetPoint("TOPRIGHT", np, "TOPRIGHT", -5, -STEP_NOTE_PAD)
		noteLbl:SetJustifyH("LEFT")
		noteLbl:SetTextColor(0.80, 0.80, 0.80)
		noteLbl:SetWordWrap(true)
		np.noteLbl = noteLbl

		-- Item hyperlink button (shown only when step.itemID is set and item is cached)
		local itemBtn = CreateFrame("Button", nil, np)
		itemBtn:SetHeight(16)
		local itemLbl = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemLbl:SetAllPoints()
		itemLbl:SetJustifyH("LEFT")
		itemBtn.lbl = itemLbl
		itemBtn:SetScript("OnEnter", function(self)
			if self.itemLink then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(self.itemLink)
				GameTooltip:Show()
			end
		end)
		itemBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
		itemBtn:RegisterForClicks("LeftButtonUp")
		itemBtn:SetScript("OnClick", function(self)
			if self.itemLink and IsModifiedClick("CHATLINK") then
				ChatEdit_InsertLink(self.itemLink)
			end
		end)
		itemBtn:Hide()
		np.itemBtn = itemBtn

		-- Waypoint button
		local wpBtn = CreateFrame("Button", nil, np)
		wpBtn:SetHeight(16)
		local wpHL = wpBtn:CreateTexture(nil, "HIGHLIGHT")
		wpHL:SetAllPoints()
		wpHL:SetColorTexture(0.4, 0.78, 1, 0.08)
		wpBtn:SetHighlightTexture(wpHL)
		local wpIco = wpBtn:CreateTexture(nil, "ARTWORK")
		wpIco:SetSize(14, 14)
		wpIco:SetPoint("LEFT", wpBtn, "LEFT", 0, 0)
		wpIco:SetAtlas("Waypoint-MapPin-Tracked")
		local wpLbl = wpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		wpLbl:SetPoint("LEFT", wpIco, "RIGHT", 3, 0)
		wpLbl:SetPoint("RIGHT", wpBtn, "RIGHT", 0, 0)
		wpLbl:SetPoint("TOP", wpBtn, "TOP", 0, 0)
		wpLbl:SetPoint("BOTTOM", wpBtn, "BOTTOM", 0, 0)
		wpLbl:SetJustifyH("LEFT")
		wpLbl:SetTextColor(0.4, 0.78, 1)
		wpLbl:SetText(L["GUIDES_SET_WAYPOINT"] or "Set Waypoint")
		wpBtn.lbl = wpLbl -- store reference for the rendering loop
		wpBtn:SetScript("OnClick", function(self)
			local label = row.lbl:GetText() or ""
			if self.waypoints then
				SetWaypoints(self.waypoints, label)
			else
				SetWaypoint(self.waypoint, label)
			end
		end)
		wpBtn:Hide()
		np.wpBtn = wpBtn

		-- Substep rows are created by GetSubstepRow below, the first time a step
		-- displayed in this row actually has that many substeps.
		np.substepRows      = {}
		np.numSubstepsShown = 0

		np.CreateSubstepRow = function()
			local sr = CreateFrame("Button", nil, np)
			sr:SetHeight(16)
			local srIco = sr:CreateTexture(nil, "ARTWORK")
			srIco:SetSize(8, 8)
			srIco:SetPoint("LEFT", sr, "LEFT", 4, 0)
			sr.ico = srIco
			local srLbl = sr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			srLbl:SetPoint("LEFT", srIco, "RIGHT", 5, 0)
			srLbl:SetPoint("RIGHT", sr, "RIGHT", -22, 0) -- leave room for waypoint pin
			srLbl:SetJustifyH("LEFT")
			srLbl:SetWordWrap(true)
			sr.lbl = srLbl
			-- Tiny waypoint pin (shown only when substep has a waypoint)
			local srWp = CreateFrame("Button", nil, sr)
			srWp:SetSize(16, 16)
			srWp:SetPoint("RIGHT", sr, "RIGHT", -2, 0)
			local srWpHL = srWp:CreateTexture(nil, "HIGHLIGHT")
			srWpHL:SetAllPoints()
			srWpHL:SetColorTexture(0.4, 0.78, 1, 0.15)
			srWp:SetHighlightTexture(srWpHL)
			local srWpIco = srWp:CreateTexture(nil, "ARTWORK")
			srWpIco:SetSize(14, 14)
			srWpIco:SetAllPoints()
			srWpIco:SetAtlas("Waypoint-MapPin-Tracked")
			srWp:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.waypoints
					and (L["GUIDES_SET_ALL_WAYPOINTS"] or "Set All Waypoints")
					or (L["GUIDES_SET_WAYPOINT"] or "Set Waypoint"))
				GameTooltip:Show()
			end)
			srWp:SetScript("OnLeave", function() GameTooltip:Hide() end)
			srWp:SetScript("OnClick", function(self)
				local label = self:GetParent().lbl:GetText() or ""
				if self.waypoints then
					SetWaypoints(self.waypoints, label)
				else
					SetWaypoint(self.waypoint, label)
				end
			end)
			srWp:Hide()
			sr.wpBtn = srWp
			sr:SetScript("OnEnter", function(self)
				if self.itemLink then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetHyperlink(self.itemLink)
					GameTooltip:Show()
				end
			end)
			sr:SetScript("OnLeave", function() GameTooltip:Hide() end)
			-- Shift-click puts the item in chat, the way shift-clicking a link
			-- anywhere else in the game does. The row shows the authored label
			-- rather than a real hyperlink, so that behaviour has to be wired by
			-- hand; without this the item is hoverable but not shareable.
			sr:RegisterForClicks("LeftButtonUp")
			sr:SetScript("OnClick", function(self)
				if self.itemLink and IsModifiedClick("CHATLINK") then
					ChatEdit_InsertLink(self.itemLink)
				end
			end)
			sr:Hide()
			return sr
		end

		row.notePanel       = np
		row.isOpen          = false
		row:SetScript("OnClick", function(self)
			if not self.hasNote then return end
			self.isOpen = not self.isOpen
			self.notePanel:SetShown(self.isOpen)
			self.arrowLbl:SetText(self.isOpen and "-" or "+")
			Guides_UpdateDetailScroll(currentNumSteps, detailSource:GetText() ~= "", detailDesc:GetText() ~= "", false)
		end)

		row:Hide()
		return row
	end

	-- Row TOPLEFT anchors are set dynamically by Guides_RelayoutSteps.
	local function GetStepRow(i)
		local row = stepRows[i]
		if not row then
			row = CreateStepRow()
			stepRows[i] = row
		end
		return row
	end

	local function GetSubstepRow(np, j)
		local sr = np.substepRows[j]
		if not sr then
			sr = np.CreateSubstepRow()
			np.substepRows[j] = sr
		end
		return sr
	end

	-- Steps header: "Progress  X / Y  steps" — clickable to expand/collapse all steps
	local stepsHeader = CreateFrame("Button", nil, detailContent)
	stepsHeader:SetHeight(20)
	stepsHeader:Hide()
	local stepsHdrBg = stepsHeader:CreateTexture(nil, "BACKGROUND")
	stepsHdrBg:SetAllPoints()
	stepsHdrBg:SetColorTexture(0.08, 0.08, 0.14, 0.90)
	local stepsHdrHL = stepsHeader:CreateTexture(nil, "HIGHLIGHT")
	stepsHdrHL:SetAllPoints()
	stepsHdrHL:SetColorTexture(1, 1, 1, 0.05)
	stepsHeader:SetHighlightTexture(stepsHdrHL)
	local stepsHdrLbl = stepsHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	stepsHdrLbl:SetPoint("LEFT", stepsHeader, "LEFT", 6, 0)
	stepsHdrLbl:SetPoint("RIGHT", stepsHeader, "RIGHT", -6, 0)
	stepsHdrLbl:SetJustifyH("LEFT")
	stepsHdrLbl:SetTextColor(0.7, 0.7, 0.7)
	stepsHeader.lbl = stepsHdrLbl
	stepsHeader:SetScript("OnClick", function()
		stepsCollapsed = not stepsCollapsed
		for i = 1, currentNumSteps do
			local row = stepRows[i]
			if not row then break end
			row:SetShown(not stepsCollapsed)
			-- Keep each note panel in step with its own row.isOpen flag.
			--
			-- Collapsing used to hide the panels without clearing isOpen, and
			-- expanding only re-showed the header rows -- so a step that had been
			-- opened came back with its arrow reading "-" but its panel still
			-- hidden, and clicking it then "closed" something already invisible.
			-- Restoring from isOpen preserves what the player had open.
			row.notePanel:SetShown(not stepsCollapsed and row.isOpen == true)
		end
		local label = stepsHeader.lbl:GetText() or ""
		stepsHeader.lbl:SetText((stepsCollapsed and "+" or "-") .. label:sub(2))
		Guides_UpdateDetailScroll(currentNumSteps, detailSource:GetText() ~= "", detailDesc:GetText() ~= "", false)
	end)

	-- ==============================================
	-- 3-D MODEL VIEWER  (fills modelPane — the Model sub-tab)
	-- DressUpModel / ModelScene frames cannot be clipped by a ScrollFrame,
	-- so they are intentionally kept outside detailScroll.
	-- ==============================================

	local detailModel = CreateFrame("DressUpModel", nil, modelPane)
	detailModel:SetAllPoints(modelPane)
	detailModel:SetFacing(0)

	local modelBg = detailModel:CreateTexture(nil, "BACKGROUND")
	modelBg:SetAllPoints()
	modelBg:SetColorTexture(0, 0, 0, 0)

	-- ModelScene for housing items only (asset is a numeric file ID, needs SetModelByFileID).
	-- Mounts and pets use detailModel (DressUpModel) via SetDisplayInfo which is simpler and reliable.
	local HOUSING_SCENE_ID = (Constants and Constants.HousingCatalogConsts
		and Constants.HousingCatalogConsts.HOUSING_CATALOG_DECOR_MODELSCENEID_DEFAULT) or 861
	local detailModelScene = CreateFrame("ModelScene", nil, modelPane, "PanningModelSceneMixinTemplate")
	detailModelScene:SetAllPoints(modelPane)
	detailModelScene:Hide()
	detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE,
		CAMERA_MODIFICATION_TYPE_DISCARD, true)

	-- Dedicated model for zoomed transmog slot view (mirrors AppearanceTooltip's .Zoomed model).
	-- SetKeepModelOnHide keeps the player loaded between views so TryOn can be called synchronously.
	local detailModelZoomed = CreateFrame("DressUpModel", nil, modelPane)
	detailModelZoomed:SetAllPoints(modelPane)
	detailModelZoomed:SetKeepModelOnHide(true)
	detailModelZoomed:SetUnit("player") -- pre-load player model at creation (mirrors AppearanceTooltip's PLAYER_LOGIN)
	detailModelZoomed:Hide()
	detailModelZoomed:SetScript("OnModelLoaded", function(self)
		-- Only re-apply camera (same as AppearanceTooltip – TryOn is called synchronously, not here)
		if self.cameraID and Model_ApplyUICamera then
			Model_ApplyUICamera(self, self.cameraID)
		end
	end)

	detailModel:EnableMouse(true)
	detailModel:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self.isRotating = true
			self.lastMouseX = GetCursorPosition()
		end
	end)
	detailModel:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self.isRotating = false
		end
	end)
	detailModel:SetScript("OnUpdate", function(self)
		if self.isRotating then
			local x         = GetCursorPosition()
			local dx        = x - (self.lastMouseX or x)
			self.lastMouseX = x
			if dx ~= 0 then
				self.modelFacing = (self.modelFacing or 0) + dx * 0.013
				self:SetFacing(self.modelFacing)
			end
		end
	end)
	detailModel:SetScript("OnMouseWheel", function(self, delta)
		self.camScale = math_max(0.3, math_min(5, (self.camScale or 1) - delta * 0.15))
		self:SetCamDistanceScale(self.camScale)
	end)
	-- Reapply transmog slot camera after async model load (same pattern as AppearanceTooltip)
	detailModel:SetScript("OnModelLoaded", function(self)
		if self.cameraID and Model_ApplyUICamera then
			Model_ApplyUICamera(self, self.cameraID)
		end
	end)

	-- ==============================================
	-- POPULATE DETAIL PANE
	-- ==============================================

	-- Reflows the TOPLEFT anchor chain for all visible step headers and open note panels.
	-- Returns the total pixel height consumed (for Guides_UpdateDetailScroll).
	Guides_RelayoutSteps = function()
		if currentNumSteps == 0 then return 0 end
		stepsHeader:ClearAllPoints()
		stepsHeader:SetPoint("TOPLEFT", reqLastWidget, "BOTTOMLEFT", 0, -12)
		stepsHeader:SetPoint("RIGHT", detailContent, "RIGHT", 0, 0)
		local totalH = 12 + 20 + 4 -- pre-gap + header height + gap after header
		if stepsCollapsed then
			for i = 1, currentNumSteps do
				stepRows[i]:Hide()
				stepRows[i].notePanel:Hide()
			end
			return totalH
		end
		local prevFrame = stepsHeader
		local contentW  = detailContent:GetWidth() or 280
		local lbl_avail = math_max(contentW - 39, 50) -- 20 (arrow) + 10 (ico) + 5 (gap) + 4 (right pad)
		for i = 1, currentNumSteps do
			local row = stepRows[i]
			local np  = row.notePanel
			row:Show()
			-- Size label width first so GetStringHeight returns the correct wrapped height
			row.lbl:SetWidth(lbl_avail)
			local lblH = row.lbl:GetStringHeight()
			local rowH = math_max(STEP_ROW_H, lblH > 0 and (lblH + 4) or STEP_ROW_H)
			row:SetHeight(rowH)
			-- Anchor header below previous frame, always flush with detailContent left
			row:ClearAllPoints()
			row:SetPoint("TOP", prevFrame, "BOTTOM", 0, -2)
			row:SetPoint("LEFT", detailContent, "LEFT", 0, 0)
			row:SetPoint("RIGHT", detailContent, "RIGHT", 0, 0)
			totalH    = totalH + rowH + 2
			prevFrame = row
			-- If this step's note panel is open, anchor and size it
			if np:IsShown() then
				-- Give noteLbl an explicit width so GetStringHeight is accurate
				np.noteLbl:SetWidth(math_max(contentW - STEP_NOTE_INDENT - 4 - 10, 50))
				local textH   = np.noteLbl:GetStringHeight()
				local numSubs = np.numSubstepsShown or 0
				-- Measure each substep row's actual wrapped height and resize it
				local subLblW = math_max(contentW - STEP_NOTE_INDENT - 54, 40)
				local subsH   = 0
				if numSubs > 0 then
					for j = 1, numSubs do
						local sr = np.substepRows[j]
						sr.lbl:SetWidth(subLblW)
						local srStrH = sr.lbl:GetStringHeight()
						local srH = math_max(16, srStrH > 0 and (srStrH + 4) or 16)
						sr:SetHeight(srH)
						subsH = subsH + srH + 2
					end
				end
				-- textH is the measured height of the note text, already 0 when the
				-- step has no note. The old expression substituted a hardcoded 46
				-- in that case (unless there were substeps), which is why a step
				-- whose panel holds only a Set Waypoint button rendered with ~46px
				-- of empty space above it.
				local panelH = STEP_NOTE_PAD + textH + STEP_NOTE_PAD
				if numSubs > 0 then panelH = panelH + subsH end
				if np.itemBtn:IsShown() then panelH = panelH + 4 + 16 end
				if np.wpBtn:IsShown() then panelH = panelH + 4 + 16 end
				panelH = panelH + STEP_NOTE_PAD -- bottom breathing room
				np:SetHeight(panelH)
				np:ClearAllPoints()
				np:SetPoint("TOPLEFT", row, "BOTTOMLEFT", STEP_NOTE_INDENT, 0)
				np:SetPoint("RIGHT", detailContent, "RIGHT", -4, 0)
				totalH    = totalH + panelH
				prevFrame = np
			end
		end
		return totalH
	end

	-- Recomputes detailContent height and updates the scrollbar.
	-- Pass resetScroll=false to preserve the current scroll position (e.g. when expanding a step note).
	Guides_UpdateDetailScroll = function(numSteps, hasSource, hasDesc, resetScroll)
		detailContent:SetWidth(detailScroll:GetWidth())
		local h = GP_PAD + 48 + 8                                                                         -- top padding + icon row + gap below icon
		h = h + 14 + 4                                                                                    -- kind badge
		h = h + 16 + 6                                                                                    -- status line
		-- Source and description are measured, not estimated.
		--
		-- These used to add a flat 40 and 60 px, annotated "~2 wrapped lines" and
		-- "~4 wrapped lines". Both are word-wrapped to the pane width, so the real
		-- height depends on the text, the font and the locale: a long mount
		-- description wrapped past the estimate and got clipped, a one-line source
		-- left a gap. The step labels a few lines down already use
		-- GetStringHeight, so this only makes the function consistent with itself.
		if hasSource then h = h + math_max(detailSource:GetStringHeight(), 14) + 6 end
		if hasDesc then h = h + math_max(detailDesc:GetStringHeight(), 14) + 6 end
		for i, r in ipairs(requiresRows) do if r:IsShown() then h = h + (i == 1 and 6 or 3) + 20 end end  -- requires link rows
		for i, r in ipairs(requiredForRows) do if r:IsShown() then h = h + (i == 1 and 4 or 3) + 20 end end -- requiredFor link rows
		if numSteps > 0 then
			h = h + Guides_RelayoutSteps()                                                                  -- pre-gap + header + step rows + open note panels
		end
		h = h + 20                                                                                        -- breathing room
		local scrollH = math_max(1, detailScroll:GetHeight() or 1)
		h = math_max(h, scrollH)
		detailContent:SetHeight(h)
		local maxScroll = math_max(0, h - scrollH)
		detailScrollBar:SetMinMaxValues(0, maxScroll)
		detailScrollBar:SetShown(maxScroll > 0)
		if resetScroll ~= false then
			detailScrollBar:SetValue(0)
			detailScroll:SetVerticalScroll(0)
		end
	end

	-- Sets up the 3-D viewers for an entry.
	--
	-- Three viewers share the model pane and exactly one is shown: detailModel
	-- (mounts, pets, floating weapons), detailModelZoomed (worn armour, needs a
	-- dressed player), and detailModelScene (housing decor, whose asset is a file
	-- id rather than a display id). Extracted from Guides_ShowDetail, where it was
	-- the last of eight unrelated jobs in one 560-line function.
	local function Guides_ShowModel(entry)
	-- Hide model strip for kinds that never have a 3-D model
	if entry.kind == "achievement" or entry.kind == "quest"
			or entry.kind == "toy" or entry.kind == "mystery" then
		detailModel:Hide()
		detailModelScene:Hide()
		detailModelZoomed:Hide()
		SetModelTabEnabled(false)
		return
	end

	-- Reset both viewers; each block below shows exactly one
	detailModelScene:ClearScene()
	detailModelScene:Hide()
	detailModelZoomed.cameraID = nil
	detailModelZoomed:Hide()
	detailModel:ClearModel()
	detailModel:SetUnit("none")
	detailModel:RefreshCamera()
	detailModel.cameraID    = nil
	detailModel.modelFacing = 0
	detailModel.camScale    = 1
	detailModel:SetFacing(0)
	detailModel:SetCamDistanceScale(1)
	detailModel:Hide()
	local modelSet = false

	if entry.kind == "mount" then
		local mountID = SC:GetMountID(entry)
		if mountID and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
			local creatureDisplayID = C_MountJournal.GetMountInfoExtraByID(mountID)
			if creatureDisplayID and creatureDisplayID > 0 then
				detailModel:SetDisplayInfo(creatureDisplayID)
				detailModel:SetCamera(1)
				detailModel:SetFacing(math_rad(30))
				if entry.camScale then
					detailModel:SetCamDistanceScale(entry.camScale)
				end
				modelSet = true
			end
		end
	elseif entry.kind == "pet" and C_PetJournal then
		local creatureDisplayID
		if entry.itemID and C_PetJournal.GetPetInfoByItemID then
			local _, _, _, _, _, _, _, _, _, _, _, displayID = C_PetJournal.GetPetInfoByItemID(entry.itemID)
			creatureDisplayID = displayID
		end
		if (not creatureDisplayID or creatureDisplayID == 0) and entry.speciesID and C_PetJournal.GetPetInfoBySpeciesID then
			local _, _, _, _, _, _, _, _, _, _, _, displayID = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
			creatureDisplayID = displayID
		end
		if creatureDisplayID and creatureDisplayID > 0 then
			detailModel:SetDisplayInfo(creatureDisplayID)
			detailModel.modelFacing = math_rad(20)
			detailModel.camScale    = 1.25
			detailModel:SetFacing(detailModel.modelFacing)
			detailModel:SetCamDistanceScale(detailModel.camScale)
			modelSet = true
		end
	elseif entry.kind == "transmog" and entry.itemID then
		-- Determine inventory type so weapons can be shown without a player body
		local invType = select(4, C_Item.GetItemInfoInstant(entry.itemID))
		local appearanceID = C_TransmogCollection and C_TransmogCollection.GetItemInfo(entry.itemID)
		local cameraID = appearanceID and C_TransmogCollection.GetAppearanceCameraID(appearanceID)
		if cameraID == 0 then cameraID = nil end -- 0 is truthy in Lua but means no camera
		local heldSlots = {
			INVTYPE_WEAPON = true,
			INVTYPE_2HWEAPON = true,
			INVTYPE_WEAPONMAINHAND = true,
			INVTYPE_WEAPONOFFHAND = true,
			INVTYPE_RANGED = true,
			INVTYPE_RANGEDRIGHT = true,
			INVTYPE_HOLDABLE = true,
			INVTYPE_SHIELD = true,
		}
		if heldSlots[invType] then
			-- Weapon/held: display the item floating alone, no player body
			detailModel.cameraID = cameraID
			if cameraID and Model_ApplyUICamera then
				Model_ApplyUICamera(detailModel, cameraID)
				detailModel:SetAnimation(0, 0)
			end
			if appearanceID then
				detailModel:SetItemAppearance(appearanceID)
			else
				detailModel:SetItem(entry.itemID)
			end
			modelSet = true
		else
			-- Worn armor: mirrors AppearanceTooltip's Zoomed model flow exactly.
			-- SetKeepModelOnHide keeps the player loaded so TryOn works synchronously.
			detailModelZoomed.cameraID = cameraID
			detailModelZoomed:SetUnit("player")
			detailModelZoomed:Dress()
			if cameraID and Model_ApplyUICamera then
				Model_ApplyUICamera(detailModelZoomed, cameraID)
				detailModelZoomed:SetAnimation(0, 0)
			end
			detailModelZoomed:TryOn("item:" .. entry.itemID)
			detailModelZoomed:Show()
			-- modelSet stays false; detailModel hidden, detailModelZoomed shown above
		end
	elseif entry.kind == "housing" and entry.itemID then
		if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
			local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, false)
			if info and info.asset and info.asset > 0 then
				detailModelScene:ClearScene()
				detailModelScene:SetViewInsets(0, 0, 0, 0)
				detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE,
					CAMERA_MODIFICATION_TYPE_DISCARD, true)
				local actor = detailModelScene:GetActorByTag("decor") or detailModelScene:CreateActor("decor")
				if actor then
					actor:SetPreferModelCollisionBounds(true)
					actor:SetModelByFileID(info.asset)
				end
				detailModelScene:Show()
			end
		end
	end

	detailModel:SetShown(modelSet)
	-- detailModelScene and detailModelZoomed visibility set explicitly in blocks above
	SetModelTabEnabled(modelSet or detailModelZoomed:IsShown() or detailModelScene:IsShown())
	end

	-- Renders the progress steps for an entry and returns how many there are.
	--
	-- Resolves stepsRef (an entry may delegate its steps to another), decides
	-- each step's state, fills the note panels, substep rows, item links and
	-- waypoint buttons, and sets the collapsible header.
	local function Guides_ShowSteps(entry)
	-- ---- Progress Steps ----
	-- Resolve stepsRef: if this entry delegates its steps to another entry, find that entry.
	local stepsEntry = entry
	if entry.stepsRef then
		for _, e in ipairs(SC.entries or {}) do
			if e.name == entry.stepsRef then
				stepsEntry = e; break
			end
		end
	end
	local steps = stepsEntry.steps
	local numSteps = steps and #steps or 0
	currentNumSteps = numSteps
	-- Force all steps green once the entry itself is complete (default behaviour for all entries).
	-- Set stepsOverrideOnDone = false on a specific entry to opt out of this behaviour.
	-- When debug mode is active the override is suppressed so individual step states remain visible.
	local entryDone = (entry.stepsOverrideOnDone ~= false) and not SecretChecklistDB.debugMode and SC.GetEntryStatus and
	(SC:GetEntryStatus(entry)) == "collected"
	-- sequential = true: the chain can only be done in order, so a done step
	-- implies every step before it. That covers steps the game leaves no trace
	-- of (talking to an NPC) and items a later step uses up, which would
	-- otherwise turn an earlier step red again. The furthest step is remembered
	-- per character (SC:GetChainProgress). Debug mode shows raw states.
	local doneThrough = 0
	if (entry.sequential or stepsEntry.sequential) and not SecretChecklistDB.debugMode then
		doneThrough = SC:GetChainProgress(stepsEntry.name, steps)
	end
	local doneCount = 0
	for i = 1, numSteps do
		local step = steps[i]
		local row  = GetStepRow(i)
		local np   = row.notePanel
		-- The loop used to run to a fixed MAX_STEPS with an `if step then`
		-- guard and an else-branch that hid the surplus. It now runs to
		-- numSteps, and the surplus is retired in a separate pass after this
		-- loop. This bare do-block is what the guard collapsed to; it is kept
		-- rather than dedented purely so the diff stays reviewable.
		do
			-- Pre-compute substep progress for label + substep row rendering
			local resolvedSubs = SC:ResolveSubsteps(step)
			local subsDone, subsTotal
			if resolvedSubs then
				subsDone, subsTotal = SC:GetSubstepProgress(step)
			end
			local st = (entryDone or i <= doneThrough) and "done" or (SC:GetStepStatus(step) or "missing")
			-- Status dot colour + label text colour
			if st == "done" then
				doneCount = doneCount + 1
				SetStatusMarker(row.ico, "collected", 10, 0, 1, 0)
				row.lbl:SetTextColor(0.53, 0.53, 0.53)
				row.lbl:SetText(SC:T(step.label))
			elseif st == "ready" then
				-- "ready" stays a gold square: it means the item is held but not
				-- yet used, which is a third state neither glyph expresses.
				SetStatusMarker(row.ico, nil, 10, 1, 0.82, 0)
				row.lbl:SetTextColor(1, 0.82, 0)
				row.lbl:SetText(SC:T(step.label))
			else
				SetStatusMarker(row.ico, "missing", 10, 1, 0, 0)
				row.lbl:SetTextColor(0.8, 0.8, 0.8)
				local labelText = SC:T(step.label)
				if step.mindseekerReq then
					local count = 0
					for _, e in ipairs(SC.entries or {}) do
						if e.mindSeeker and SC:GetEntryStatus(e) == "collected" then
							count = count + 1
						end
					end
					labelText = labelText .. "  " .. (L["GUIDES_MINDSEEKER_REQ"] or "(%d / %d secrets)")
						:format(count, step.mindseekerReq)
				elseif step.renownReq and C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel then
					local current = C_MajorFactions.GetCurrentRenownLevel(step.renownReq.factionID) or 0
					labelText = labelText .. "  (" .. current .. " / " .. step.renownReq.level .. ")"
				elseif step.repReq then
					local data = C_Reputation and C_Reputation.GetFactionDataByID and
					C_Reputation.GetFactionDataByID(step.repReq.factionID)
					local current = (data and data.reaction) or 0
					local target = step.repReq.standingName or step.repReq.standingID
					labelText = labelText .. "  " .. (L["GUIDES_RANK_REQ"] or "(Rank %d / %s)")
						:format(current, tostring(target))
				elseif resolvedSubs then
					labelText = labelText .. "  (" .. subsDone .. " / " .. subsTotal .. ")"
				end
				row.lbl:SetText(labelText)
			end
			-- Populate note panel
			np.noteLbl:SetText(SC:T(step.note) or "")
			-- Substep rows. No cap: rows are created as the list needs them, so a
			-- factionSubsteps list longer than any plain substeps list no longer
			-- gets silently truncated.
			local numSubstepsShown = 0
			local lastSubstepFrame = nil
			if resolvedSubs then
				local prevSRAnchor = np.noteLbl
				for j, sub in ipairs(resolvedSubs) do
					local sr = GetSubstepRow(np, j)
					local srDone, srReady = false, false
					if st == "done" then
						srDone = true
					elseif step.chain then
						if subsDone > 0 then
							if j < subsDone then
								srDone = true
							elseif j == subsDone then
								srReady = true
							end
						end
					else
						if sub.questID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
							srDone = C_QuestLog.IsQuestFlaggedCompleted(sub.questID)
						elseif sub.itemID then
							local have = C_Item.GetItemCount(sub.itemID, true, nil, nil, true)
							if sub.count then
								srDone = have >= sub.count
							else
								srDone = have >= 1
							end
						end
					end
					if srDone then
						SetStatusMarker(sr.ico, "collected", 8, 0, 0.8, 0)
						sr.lbl:SetTextColor(0.50, 0.50, 0.50)
					elseif srReady then
						SetStatusMarker(sr.ico, nil, 8, 1, 0.82, 0)
						sr.lbl:SetTextColor(1, 0.82, 0)
					else
						SetStatusMarker(sr.ico, "missing", 8, 0.8, 0.2, 0.2)
						sr.lbl:SetTextColor(0.80, 0.80, 0.80)
					end
					if sub.itemID then
						local _, itemLink, quality = C_Item.GetItemInfo(sub.itemID)
						-- Quality colour on every state except "ready".
						--
						-- This first excluded done and ready rows so their grey and
						-- gold could carry status. In practice most substeps on a
						-- collected secret are done, so the colour was almost never
						-- visible. Done rows are dimmed to half instead: still
						-- clearly finished, still recognisably the item's colour.
						--
						-- Ready keeps its gold. That one means "you can do this
						-- now", which is worth more than knowing the item is rare,
						-- and it is the only row of its kind on screen.
						-- Full quality colour, undimmed, on everything except a
						-- ready row.
						--
						-- Done rows were dimmed at first, carried over from when
						-- grey was the only signal that a substep was finished. It
						-- is not any more: the green check beside the row says so,
						-- and dimming only fought with the colour it was drawn on
						-- top of. Quality colours are muted to begin with, so there
						-- was little headroom to take away.
						--
						-- Ready still overrides to gold. "You can do this now" is
						-- worth more than rarity and there is only ever one.
						if quality and not srReady and ITEM_QUALITY_COLORS then
							local qc = ITEM_QUALITY_COLORS[quality]
							if qc then sr.lbl:SetTextColor(qc.r, qc.g, qc.b) end
						end
						-- The authored label wins over the item link.
						--
						-- This used to be `itemLink or label`, which made the text
						-- depend on whether the client had that item cached: the
						-- same substep read "[Glittering Phoenix Ember]" in one
						-- session and "Loot Glittering Phoenix Ember (x1)" in the
						-- next. The label is the better of the two anyway -- it
						-- carries the verb and the count, and it goes through SC:T
						-- so it translates, where a link is only ever a name.
						--
						-- Nothing is lost by not showing the link inline: sr.itemLink
						-- still drives the hover tooltip.
						local displayText = SC:T(sub.label) or itemLink
						-- The label does not need the item, but the hover tooltip
						-- does; request it so the tooltip is not silently absent.
						if not itemLink and C_Item.RequestLoadItemDataByID then
							C_Item.RequestLoadItemDataByID(sub.itemID)
						end
						if sub.count and sub.count > 1 then
							local have = C_Item.GetItemCount(sub.itemID, true, nil, nil, true)
							displayText = displayText .. "  (" .. math_min(have, sub.count) .. " / " .. sub.count .. ")"
						end
						sr.lbl:SetText(displayText)
						sr.itemLink = itemLink
					else
						sr.lbl:SetText(SC:T(sub.label))
						sr.itemLink = nil
					end
					-- Substep waypoint pin
					if sub.waypoints then
						sr.wpBtn.waypoints = sub.waypoints
						sr.wpBtn.waypoint  = nil
						sr.wpBtn:Show()
					else
						sr.wpBtn.waypoints = nil
						local resolvedSubWp = sub.waypoint
						if sub.factionWaypoint then
							local fkey = (UnitFactionGroup and UnitFactionGroup("player") == "Alliance") and "alliance" or "horde"
							resolvedSubWp = sub.factionWaypoint[fkey] or resolvedSubWp
						end
						if resolvedSubWp then
							sr.wpBtn.waypoint = resolvedSubWp
							sr.wpBtn:Show()
						else
							sr.wpBtn.waypoint = nil
							sr.wpBtn:Hide()
						end
					end
					sr:ClearAllPoints()
					sr:SetPoint("TOP", prevSRAnchor, "BOTTOM", 0, -2)
					sr:SetPoint("LEFT", np.noteLbl, "LEFT", 14, 0)
					sr:SetPoint("RIGHT", np, "RIGHT", -6, 0)
					sr:Show()
					prevSRAnchor = sr
					numSubstepsShown = numSubstepsShown + 1
					lastSubstepFrame = sr
				end
			end
			for j = numSubstepsShown + 1, #np.substepRows do
				np.substepRows[j]:Hide()
			end
			np.numSubstepsShown = numSubstepsShown
			-- Item hyperlink (only when item is cached; returns nil otherwise)
			local itemBtn = np.itemBtn
			local displayItemID = step.itemID
			if not displayItemID and step.itemIDs then
				displayItemID = step.itemIDs[#step.itemIDs] -- show the final/filled item
			end
			if displayItemID then
				local _, itemLink = C_Item.GetItemInfo(displayItemID)
				if itemLink then
					local display = itemLink
					if step.count and step.count > 1 then
						display = itemLink .. "  ×" .. step.count
					end
					itemBtn.lbl:SetText(display)
					itemBtn.itemLink = itemLink
					local itemBtnAnchor = lastSubstepFrame or np.noteLbl
					itemBtn:SetPoint("TOPLEFT", itemBtnAnchor, "BOTTOMLEFT", 0, -4)
					itemBtn:SetPoint("RIGHT", np, "RIGHT", -6, 0)
					itemBtn:Show()
				else
					-- Not cached yet. Ask for it; the handler below redraws when
					-- it lands, so the row stops being a coin flip on whether the
					-- player happened to have seen the item this session.
					if C_Item.RequestLoadItemDataByID then
						C_Item.RequestLoadItemDataByID(displayItemID)
					end
					itemBtn.itemLink = nil
					itemBtn:Hide()
				end
			else
				itemBtn.itemLink = nil
				itemBtn:Hide()
			end
			-- Waypoint button
			local wpBtn = np.wpBtn
			if step.waypoints then
				wpBtn.waypoints = step.waypoints
				wpBtn.waypoint  = nil
				wpBtn.lbl:SetText(L["GUIDES_SET_ALL_WAYPOINTS"] or "Set All Waypoints")
				local wpAnchor = itemBtn:IsShown() and itemBtn or (lastSubstepFrame or np.noteLbl)
				wpBtn:SetPoint("TOPLEFT", wpAnchor, "BOTTOMLEFT", 0, -4)
				wpBtn:SetPoint("RIGHT", np, "RIGHT", -6, 0)
				wpBtn:Show()
			elseif step.waypoint then
				wpBtn.waypoint  = step.waypoint
				wpBtn.waypoints = nil
				wpBtn.lbl:SetText(L["GUIDES_SET_WAYPOINT"] or "Set Waypoint")
				local wpAnchor = itemBtn:IsShown() and itemBtn or (lastSubstepFrame or np.noteLbl)
				wpBtn:SetPoint("TOPLEFT", wpAnchor, "BOTTOMLEFT", 0, -4)
				wpBtn:SetPoint("RIGHT", np, "RIGHT", -6, 0)
				wpBtn:Show()
			elseif step.factionWaypoint then
				local fkey      = (UnitFactionGroup and UnitFactionGroup("player") == "Alliance") and "alliance" or "horde"
				wpBtn.waypoint  = step.factionWaypoint[fkey]
				wpBtn.waypoints = nil
				wpBtn.lbl:SetText(L["GUIDES_SET_WAYPOINT"] or "Set Waypoint")
				local wpAnchor = itemBtn:IsShown() and itemBtn or (lastSubstepFrame or np.noteLbl)
				wpBtn:SetPoint("TOPLEFT", wpAnchor, "BOTTOMLEFT", 0, -4)
				wpBtn:SetPoint("RIGHT", np, "RIGHT", -6, 0)
				wpBtn:Show()
			else
				wpBtn.waypoint  = nil
				wpBtn.waypoints = nil
				wpBtn:Hide()
			end
			-- Show expand arrow only when there is something to reveal in the note panel
			local hasNote = (step.note and step.note ~= "")
					or (resolvedSubs and #resolvedSubs > 0)
					or itemBtn:IsShown()
					or wpBtn:IsShown()
			row.hasNote = hasNote
			row.arrowLbl:SetShown(hasNote)
			-- Always reset collapse state when loading a new entry
			row.isOpen = false
			row.arrowLbl:SetText("+")
			np:Hide()
			row:Hide() -- hidden until the steps header is expanded
		end
	end
	-- Retire rows left over from a previously displayed entry that had more steps.
	for i = numSteps + 1, #stepRows do
		local row = stepRows[i]
		row.hasNote = false
		row.isOpen  = false
		row.notePanel:Hide()
		row:Hide()
	end
	if numSteps > 0 then
		-- Collapse by default when the secret is already collected
		stepsCollapsed = (SC:GetEntryStatus(entry) == "collected")
		local prefix = stepsCollapsed and "+ " or "- "
		stepsHeader.lbl:SetText(prefix
				.. (L["GUIDES_PROGRESS"] or "Progress  %d / %d  steps"):format(doneCount, numSteps))
		stepsHeader:Show()
	else
		stepsHeader:Hide()
	end
	return numSteps
	-- ---- End Progress Steps ----
	end

	Guides_ShowDetail = function(entry)
		guides_selected = entry
		if not entry then
			detailIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			detailKind:SetText("")
			detailName:SetText("")
			detailStatus:SetText("")
			detailSource:SetText("")
			detailDesc:SetText("")
			for _, r in ipairs(requiresRows) do r:Hide() end
			for _, r in ipairs(requiredForRows) do r:Hide() end
			reqLastWidget = detailDesc
			linkBtn.currentURL = ""
			linkBtn:SetEnabled(false)
			SC:HideCopyDialog()
			for _, row in ipairs(stepRows) do
				row:Hide()
				row.notePanel:Hide()
				row.isOpen = false
			end
			-- Rows are now created on demand, so currentNumSteps is what tells the
			-- relayout and collapse paths how far into stepRows it is safe to index.
			-- Leaving it at the previous entry's count would let those walk past the
			-- rows that actually exist.
			currentNumSteps = 0
			stepsHeader:Hide()
			detailModel:Hide()
			detailModelScene:Hide()
			detailModelZoomed:Hide()
			detailScrollBar:SetValue(0)
			detailScrollBar:SetShown(false)
			detailScroll:SetVerticalScroll(0)
			SetModelTabEnabled(false)
			return
		end

		-- Always start on Info tab when switching entries; reset model tab state
		SwitchDetailTab("info")
		SetModelTabEnabled(false)
		linkBtn.currentURL = entry.guideURL or ""
		linkBtn:SetEnabled(linkBtn.currentURL ~= "")

		detailIcon:SetTexture(SC:GetEntryIcon(entry))

		local kc      = kindColors[entry.kind] or { 0.8, 0.8, 0.8 }
		local kindStr = entry.kind and (entry.kind:sub(1, 1):upper() .. entry.kind:sub(2)) or ""
		detailKind:SetText(kindStr)
		detailKind:SetTextColor(kc[1], kc[2], kc[3])

		detailName:SetText(SC:GetEntryName(entry))

		local status = SC:GetEntryStatus(entry) or "unknown"
		if status == "collected" then
			detailName:SetTextColor(1, 0.82, 0)
		else
			detailName:SetTextColor(0.6, 0.6, 0.6)
		end

		if status == "collected" then
			detailStatus:SetText(L["TOOLTIP_COLLECTED"] or "Collected")
			detailStatus:SetTextColor(0, 1, 0)
		elseif status == "missing" then
			detailStatus:SetText(L["TOOLTIP_NOT_COLLECTED"] or "Not collected")
			detailStatus:SetTextColor(1, 0, 0)
		else
			detailStatus:SetText("")
		end

		local sourceText, descText = "", ""
		if entry.kind == "mount" then
			local mountID = SC:GetMountID(entry)
			if mountID and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
				local _, desc, src = C_MountJournal.GetMountInfoExtraByID(mountID)
				sourceText         = src or ""
				descText           = desc or ""
			end
		elseif entry.kind == "pet" then
			if entry.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
				local _, _, _, _, src, desc = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
				sourceText                  = src or ""
				descText                    = desc or ""
			end
		elseif entry.kind == "achievement" and entry.achievementID then
			local _, _, _, _, _, _, _, desc = GetAchievementInfo(entry.achievementID)
			descText = desc or ""
		elseif entry.kind == "toy" and entry.itemID then
			local _, spellID = C_Item.GetItemSpell(entry.itemID)
			if spellID and C_Spell and C_Spell.GetSpellDescription then
				descText = C_Spell.GetSpellDescription(spellID) or ""
			end
		elseif entry.kind == "housing" and entry.itemID and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
			local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, false)
			if info then
				sourceText = info.sourceText or ""
			end
		end
		-- Entry-level overrides (for toys and any entry with hand-authored data)
		if type(entry.source) == "string" and entry.source ~= "" then sourceText = SC:T(entry.source) end
		if type(entry.desc) == "string" and entry.desc ~= "" then descText = SC:T(entry.desc) end
		-- "Part of" cross-reference shown at top of the source field
		if type(entry.partOf) == "string" and entry.partOf ~= "" then
			local prefix = (L["GUIDES_PART_OF"] or "Part of: %s"):format(SC:T(entry.partOf))
			sourceText = sourceText ~= "" and (prefix .. "\n" .. sourceText) or prefix
		end
		detailSource:SetText(sourceText)
		detailDesc:SetText(descText)
		-- ---- Requirement cross-reference links ----
		for _, r in ipairs(requiresRows) do r:Hide() end
		for _, r in ipairs(requiredForRows) do r:Hide() end
		reqLastWidget       = detailDesc
		local prevReqWidget = detailDesc
		-- Normalise: accept both a plain string and a table of strings.
		local reqList       = type(entry.requires) == "table" and entry.requires
				or (type(entry.requires) == "string" and entry.requires ~= "" and { entry.requires }) or {}
		local reqForList    = type(entry.requiredFor) == "table" and entry.requiredFor
				or (type(entry.requiredFor) == "string" and entry.requiredFor ~= "" and { entry.requiredFor }) or {}
		for i, name in ipairs(reqList) do
			local row = requiresRows[i]
			if not row then break end
			local target
			for _, e in ipairs(SC.entries or {}) do
				if e.name == name then
					target = e; break
				end
			end
			row.lbl:SetText(i == 1 and (L["GUIDES_REQUIRES"] or "Requires:") or "")
			row.btn.targetEntry = target
			row.btn.lbl:SetText(name)
			if target then
				row.btn.lbl:SetTextColor(0.4, 0.78, 1)
				row.btn:SetEnabled(true)
			else
				row.btn.lbl:SetTextColor(0.55, 0.55, 0.55)
				row.btn:SetEnabled(false)
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", prevReqWidget, "BOTTOMLEFT", 0, i == 1 and -6 or -3)
			row:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", -6, 0)
			row:Show()
			prevReqWidget = row
			reqLastWidget = row
		end
		for i, name in ipairs(reqForList) do
			local row = requiredForRows[i]
			if not row then break end
			local target
			for _, e in ipairs(SC.entries or {}) do
				if e.name == name then
					target = e; break
				end
			end
			row.lbl:SetText(i == 1 and (L["GUIDES_REQUIRED_FOR"] or "Required for:") or "")
			row.btn.targetEntry = target
			row.btn.lbl:SetText(name)
			if target then
				row.btn.lbl:SetTextColor(0.4, 0.78, 1)
				row.btn:SetEnabled(true)
			else
				row.btn.lbl:SetTextColor(0.55, 0.55, 0.55)
				row.btn:SetEnabled(false)
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", prevReqWidget, "BOTTOMLEFT", 0, i == 1 and -4 or -3)
			row:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", -6, 0)
			row:Show()
			prevReqWidget = row
			reqLastWidget = row
		end
		local numSteps = Guides_ShowSteps(entry)
		-- Sizing the scroll region stays with the caller: it needs the step count
		-- from Guides_ShowSteps and the source/description flags resolved earlier,
		-- and neither of those alone owns the answer.
		Guides_UpdateDetailScroll(numSteps, sourceText ~= "", descText ~= "")

		Guides_ShowModel(entry)
	end

	-- ==============================================
	-- ROW BUILDER & LIST REFRESH
	-- ==============================================

	local function Guides_GetOrCreateRow(idx)
		if guides_rowButtons[idx] then return guides_rowButtons[idx] end

		local yOff = -(idx - 1) * GP_ROW_H
		local row  = CreateFrame("Button", nil, scrollChild)
		row:SetHeight(GP_ROW_H)
		row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
		row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, yOff)

		local rowBg = row:CreateTexture(nil, "BACKGROUND")
		rowBg:SetAllPoints()
		local rbC = SC:ThemeColor(idx % 2 == 0 and "rowEven" or "rowOdd")
		rowBg:SetColorTexture(rbC[1], rbC[2], rbC[3], rbC[4])
		row.rowBg = rowBg

		local selBg = row:CreateTexture(nil, "BACKGROUND")
		selBg:SetAllPoints()
		local scC = SC:ThemeColor("rowSel")
		selBg:SetColorTexture(scC[1], scC[2], scC[3], scC[4])
		selBg:Hide()
		row.selBg = selBg

		local hovTex = row:CreateTexture(nil, "HIGHLIGHT")
		hovTex:SetAllPoints()
		local hcC = SC:ThemeColor("rowHov")
		hovTex:SetColorTexture(hcC[1], hcC[2], hcC[3], hcC[4])
		row:SetHighlightTexture(hovTex)
		row.hovTex = hovTex

		-- Icon (plain, no border)
		local ico = row:CreateTexture(nil, "ARTWORK")
		ico:SetSize(32, 32)
		ico:SetPoint("LEFT", 4, 0)
		ico:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		row.ico = ico

		local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		lbl:SetPoint("LEFT", ico, "RIGHT", 6, 0)
		lbl:SetPoint("RIGHT", row, "RIGHT", -14, 0) -- leave room for status dot
		lbl:SetJustifyH("LEFT")
		lbl:SetMaxLines(2)
		row.lbl = lbl

		local dot = row:CreateTexture(nil, "OVERLAY")
		dot:SetSize(6, 6)
		dot:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		row.dot = dot

		row:SetScript("OnClick", function(self)
			guides_selected = self.entry
			Guides_ShowDetail(self.entry)
			for _, r in pairs(guides_rowButtons) do
				r.selBg:SetShown(r.entry == self.entry)
			end
		end)

		guides_rowButtons[idx] = row
		return row
	end

	Guides_RefreshList = function()
		local total    = #guides_entries
		local contentH = math_max(1, total * GP_ROW_H)
		scrollChild:SetHeight(contentH)

		local visibleH = scrollFrame:GetHeight()
		if not visibleH or visibleH < GP_ROW_H then visibleH = contentH end
		local maxScroll = math_max(0, contentH - visibleH)
		-- Use guides_scrollPos (not scrollFrame:GetVerticalScroll) because WoW resets the
		-- frame's internal scroll value to 0 when the panel is hidden (tab switch).
		local curScroll = math_min(guides_scrollPos, maxScroll)

		guides_scrollPos = curScroll
		scrollFrame:SetVerticalScroll(curScroll)
		scrollBar:SetMinMaxValues(0, maxScroll)
		scrollBar:SetValue(curScroll)
		scrollBar:SetShown(maxScroll > 0)

		-- Size the thumb to the share of the list that is on screen. This is a
		-- bare Slider rather than one of Blizzard's scrollbar templates, so
		-- nothing does it for us: the thumb kept the fixed 20px it was given at
		-- creation and looked identical whether it was scrolling every entry or
		-- three search results. Searching narrows the list, so that is exactly
		-- when a fixed thumb misleads most.
		-- Half the strictly proportional height: a true-to-scale thumb reads as
		-- a heavy block against a 6px bar, and the bar is a position indicator
		-- here rather than something people drag much. 10px floor keeps it
		-- grabbable on the longest lists.
		local thumb = scrollBar:GetThumbTexture()
		if thumb and maxScroll > 0 then
			local trackH = scrollBar:GetHeight() or 0
			if trackH > 0 and contentH > 0 then
				local proportional = trackH * (visibleH / contentH) * 0.5
				thumb:SetHeight(math_max(10, math_min(trackH, proportional)))
			end
		end

		for i = 1, math_max(total, #guides_rowButtons) do
			local entry = guides_entries[i]
			local row   = Guides_GetOrCreateRow(i)

			if entry then
				row.ico:SetTexture(SC:GetEntryIcon(entry))

				local status = SC:GetEntryStatus(entry) or "unknown"
				local isCol  = (status == "collected")
				local isMis  = (status == "missing")
				row.ico:SetDesaturated(not isCol)

				row.lbl:SetText(SC:GetEntryName(entry))
				if isCol then
					row.lbl:SetTextColor(1, 0.82, 0)
				else
					row.lbl:SetTextColor(0.5, 0.5, 0.5)
				end

				if isCol then
					SetStatusMarker(row.dot, "collected", 6, 0, 1, 0)
				elseif isMis then
					SetStatusMarker(row.dot, "missing", 6, 1, 0, 0)
				else
					-- No glyph for "unknown" -- the data has not loaded yet rather
					-- than resolved to a state, and a neutral dot says that better
					-- than any symbol would.
					SetStatusMarker(row.dot, nil, 6, 0.5, 0.5, 0.5)
				end
				row.dot:Show()

				row.entry = entry
				row.selBg:SetShown(entry == guides_selected)
				row:Show()
			else
				row:Hide()
				row.entry = nil
				row.selBg:Hide()
			end
		end
	end

	-- Recolour existing rows when the theme changes (called by SC:ApplyTheme)
	SC.onThemeChanged = function()
		for idx, row in ipairs(guides_rowButtons) do
			if row.rowBg then
				local c = SC:ThemeColor(idx % 2 == 0 and "rowEven" or "rowOdd")
				row.rowBg:SetColorTexture(c[1], c[2], c[3], c[4])
			end
			if row.selBg then
				local c = SC:ThemeColor("rowSel")
				row.selBg:SetColorTexture(c[1], c[2], c[3], c[4])
			end
			if row.hovTex then
				local c = SC:ThemeColor("rowHov")
				row.hovTex:SetColorTexture(c[1], c[2], c[3], c[4])
			end
		end
	end

	listPane:EnableMouseWheel(true)
	listPane:SetScript("OnMouseWheel", function(self, delta)
		local cur = guides_scrollPos
		local max = scrollFrame:GetVerticalScrollRange()
		local new = math_max(0, math_min(max, cur - delta * GP_ROW_H))
		guides_scrollPos = new
		scrollFrame:SetVerticalScroll(new)
		scrollBar:SetValue(new)
	end)

	-- ==============================================
	-- GUIDE STYLE  (switch between horizontal tab bar and side-tab buttons)
	-- Call SC.ApplyGuideStyle("horizontal") or SC.ApplyGuideStyle("sidetabs")
	-- from anywhere (e.g. the filter dropdown) to toggle live, no reload needed.
	-- ==============================================
	-- persist=true records the choice in SavedVariables; the initial call below
	-- passes false so constructing the panel does not overwrite the value that
	-- PLAYER_LOGIN is about to read back.
	local function ApplyGuideStyle(style, persist)
		guidesStyle = style or "sidetabs"
		if persist and SecretChecklistDB then
			SecretChecklistDB.guidesStyle = guidesStyle
		end
		-- Capture current model state from whichever style was previously active
		local hadModel = modelSkBtn.hasModel or modelTab.hasModel
		if guidesStyle == "sidetabs" then
			detailTabBar:Hide()
			infoPane:ClearAllPoints()
			infoPane:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, 0)
			infoPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
			modelPane:ClearAllPoints()
			modelPane:SetPoint("TOPLEFT", detailPane, "TOPLEFT", 0, 0)
			modelPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
		else -- "horizontal"
			infoSkBtn:Hide()
			modelSkBtn:Hide()
		end
		SetModelTabEnabled(hadModel)
		SwitchDetailTab(activeDetailTab)
	end
	-- Public entry point: a style set through here is a deliberate choice, so it persists.
	SC.ApplyGuideStyle = function(style) ApplyGuideStyle(style, true) end

	guidesPanel:SetScript("OnShow", function()
		SC:RefreshCaches()
		if SC.updateProgressBar then SC.updateProgressBar() end
		-- Apply preselected entry (set by Overview icon click) before filtering
		if SC.guidesPreselect then
			guides_selected = SC.guidesPreselect
			SC.guidesPreselect = nil
		end
		Guides_ApplyFilter()
		Guides_RefreshList()
		if guides_selected then
			-- Scroll the list so the selected row is visible
			for i, e in ipairs(guides_entries) do
				if e == guides_selected then
					local visH       = scrollFrame:GetHeight() or 0
					local targetY    = (i - 1) * GP_ROW_H
					local scrollTo   = math_max(0, targetY - math_max(0, (visH - GP_ROW_H) / 2))
					local maxScroll  = math_max(0, #guides_entries * GP_ROW_H - visH)
					scrollTo         = math_min(scrollTo, maxScroll)
					guides_scrollPos = scrollTo
					scrollFrame:SetVerticalScroll(scrollTo)
					scrollBar:SetValue(scrollTo)
					break
				end
			end
			Guides_ShowDetail(guides_selected)
		elseif #guides_entries > 0 then
			local firstRow = guides_rowButtons[1]
			if firstRow then firstRow:Click() end
		else
			Guides_ShowDetail(nil)
		end
	end)

	-- Initial style applied at PLAYER_LOGIN (deferred so SavedVariables are committed);
	-- set a neutral starting state here (sidetabs is the default). persist=false:
	-- writing the default here would overwrite the saved value before login reads it.
	ApplyGuideStyle("sidetabs", false)

	-- Redraw the open guide when an item we asked for finishes loading.
	--
	-- Item data is cached lazily, so GetItemInfo returns nil for anything the
	-- client has not seen. The detail pane requests what it needs above; this
	-- turns the answer into a redraw, which is what stops a step's item row from
	-- being present in one session and missing in the next.
	--
	-- Coalesced through a timer: a single guide can request several items and
	-- each one answers separately, but one redraw covers them all.
	do
		local itemLoadFrame   = CreateFrame("Frame")
		local redrawScheduled = false
		itemLoadFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
		itemLoadFrame:SetScript("OnEvent", function(_, _, _, success)
			-- Only on success. The event also reports failures, and redrawing on
			-- one would re-request the same item and fire it again -- a loop for
			-- any id the client cannot resolve.
			if success == false then return end
			if redrawScheduled then return end
			if not (guidesPanel:IsShown() and guides_selected) then return end
			redrawScheduled = true
			C_Timer.After(0.1, function()
				redrawScheduled = false
				if guidesPanel:IsShown() and guides_selected then
					Guides_ShowDetail(guides_selected)
				end
			end)
		end)
	end
end -- SC:BuildGuidesPanel
