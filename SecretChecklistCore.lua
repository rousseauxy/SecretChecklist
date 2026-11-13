-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs
local math_max = math.max
local math_cos, math_sin, math_atan2, math_deg, math_rad = math.cos, math.sin, math.atan2, math.deg, math.rad
local tinsert = table.insert
local table_sort = table.sort

-- Kind sort order used by GetFilteredEntries; defined once at module level
local kindOrder = { mount = 1, pet = 2, toy = 3, achievement = 4, transmog = 5, quest = 6, housing = 7, mystery = 8 }

-- Localization accessor
local L = _G.SecretChecklistLocale or {}

local SC = _G.SecretChecklist
if not SC then return end

-- Reference to the XML-defined frame
local frame = SecretChecklistFrame
if not frame then return end

-- ==============================================
-- STATE
-- ==============================================

-- Tab state (on SC so tab panel files can read/write them)
SC.currentTab      = "overview"
SC.tabButtons_list = {}
-- SC.guidesListPane and SC.onFilterChange are set by BuildGuidesPanel

-- Filter state per tab (local; exposed via accessors so tab panel files can read them)
local defaultKinds = { mount = true, pet = true, toy = true, achievement = true, quest = true, transmog = true, housing = true, mystery = true }
local tabFilters   = {
	overview = { showCollected = true, showMissing = true, kinds = { mount = true, pet = true, toy = true, achievement = true, quest = true, transmog = true, housing = true, mystery = true }, mindSeekerOnly = false, sortBy = "type" },
	guides   = { showCollected = true, showMissing = true, kinds = { mount = true, pet = true, toy = true, achievement = true, quest = true, transmog = true, housing = true, mystery = true }, mindSeekerOnly = false, sortBy = "status" },
}

-- Read-only accessors: return filters for the currently active tab
function SC:GetShowCollected()
	local f = tabFilters[SC.currentTab]
	return f == nil or f.showCollected ~= false
end

function SC:GetShowMissing()
	local f = tabFilters[SC.currentTab]
	return f == nil or f.showMissing ~= false
end

function SC:GetFilterKinds()
	local f = tabFilters[SC.currentTab]
	return f and f.kinds or defaultKinds
end

function SC:GetFilterMindSeekerOnly()
	local f = tabFilters[SC.currentTab]
	return f and f.mindSeekerOnly or false
end

function SC:GetSortBy()
	local f = tabFilters[SC.currentTab]
	return f and f.sortBy or "type"
end

-- ==============================================
-- FILTERING
-- ==============================================

local function GetFilteredEntries()
	local entries        = SC.entries or {}
	local f              = tabFilters[SC.currentTab] or tabFilters.overview
	local showCollected  = f.showCollected ~= false
	local showMissing    = f.showMissing ~= false
	local filterKinds    = f.kinds
	local mindSeekerOnly = f.mindSeekerOnly
	local sortBy         = f.sortBy or "type"

	-- No kind checked means no kind filter, by design: the type list acts as a
	-- narrowing selection rather than a whitelist, so clearing it returns to the
	-- unfiltered view instead of an empty one.
	local anyKindEnabled = false
	for _, v in pairs(filterKinds) do
		if v then
			anyKindEnabled = true
			break
		end
	end

	local filtered = {}
	for _, entry in ipairs(entries) do
		local shouldInclude = true

		local entryKind = entry.kind or "unknown"
		if anyKindEnabled and not filterKinds[entryKind] then
			shouldInclude = false
		end

		-- Filter by Mind-Seeker
		if shouldInclude and mindSeekerOnly and not entry.mindSeeker then
			shouldInclude = false
		end

		-- Filter by collection status (only when the two checkboxes differ)
		if shouldInclude and showCollected ~= showMissing then
			local status = SC:GetEntryStatus(entry) or "unknown"
			local isCollected = (status == "collected")
			if showCollected and not isCollected then
				shouldInclude = false
			elseif showMissing and isCollected then
				shouldInclude = false
			end
		end

		if shouldInclude then
			tinsert(filtered, entry)
		end
	end

	-- Sort
	-- Pre-compute sort keys once (O(N)) so the comparator closure does not
	-- call GetEntryName / GetEntryStatus O(N log N) times during the sort.
	if sortBy == "name" then
		local lowerName = {}
		for _, e in ipairs(filtered) do lowerName[e] = SC:GetEntryName(e):lower() end
		table_sort(filtered, function(a, b) return lowerName[a] < lowerName[b] end)
	elseif sortBy == "status" then
		local statusOrder = { missing = 1, unknown = 2, manual = 3, collected = 4 }
		local lowerName, statusKey = {}, {}
		for _, e in ipairs(filtered) do
			lowerName[e] = SC:GetEntryName(e):lower()
			statusKey[e] = statusOrder[SC:GetEntryStatus(e)] or 2
		end
		table_sort(filtered, function(a, b)
			if statusKey[a] ~= statusKey[b] then return statusKey[a] < statusKey[b] end
			return lowerName[a] < lowerName[b]
		end)
	elseif sortBy == "status_col" then
		local statusOrder = { collected = 1, missing = 2, unknown = 3, manual = 4 }
		local lowerName, statusKey = {}, {}
		for _, e in ipairs(filtered) do
			lowerName[e] = SC:GetEntryName(e):lower()
			statusKey[e] = statusOrder[SC:GetEntryStatus(e)] or 3
		end
		table_sort(filtered, function(a, b)
			if statusKey[a] ~= statusKey[b] then return statusKey[a] < statusKey[b] end
			return lowerName[a] < lowerName[b]
		end)
	else -- "type" (default)
		local lowerName = {}
		for _, e in ipairs(filtered) do lowerName[e] = SC:GetEntryName(e):lower() end
		table_sort(filtered, function(a, b)
			local ka = kindOrder[a.kind or "unknown"] or 99
			local kb = kindOrder[b.kind or "unknown"] or 99
			if ka ~= kb then return ka < kb end
			return lowerName[a] < lowerName[b]
		end)
	end

	return filtered
end

-- The button reads "Filter", always.
--
-- It used to append a count of active filters, which measured the wrong thing:
-- narrowing to a single type unchecks the other seven, so picking one type read
-- "Filter (7)". A number that goes up as you narrow is worse than no number,
-- and the dropdown already shows what is ticked the moment you open it.
--
-- L["FILTER_WITH_COUNT"] is deliberately left in the locale files. It is
-- translated in ruRU already, and keeping it costs nothing if the count ever
-- comes back in a form that counts something a player would recognise.
local function UpdateFilterButtonText()
	if not frame.FilterDropdown or not frame.FilterDropdown.Text then return end
	frame.FilterDropdown.Text:SetText(L["FILTER"] or "Filter")
end

-- Expose filtered entries to tab panel files
function SC:GetFilteredEntries() return GetFilteredEntries() end

-- ==============================================
-- TAB SYSTEM
-- ==============================================

local function SetTabActive(button, isActive)
	-- EllesmereUI's Tab primitive reads selection from button.isSelected -- our
	-- frame is not a PanelTemplates-managed tab system, so that flag is what its
	-- TabIsSelected check falls through to. Set it for every theme, then let the
	-- active theme paint.
	button.isSelected = isActive
	SC:ThemePrimitive("StyleTab")(button, isActive)
end

local SwitchTab -- forward declaration

local function CreateTabButton(tabID, label)
	local button = CreateFrame("Button", "SecretChecklistTab_" .. tabID, frame)
	button:SetHeight(32)
	button.tabID = tabID

	-- Active state textures
	local leftActive = button:CreateTexture(nil, "BACKGROUND")
	leftActive:SetAtlas("uiframe-activetab-left", true)
	leftActive:SetPoint("TOPLEFT", -1, 0)
	button.LeftActive = leftActive

	local rightActive = button:CreateTexture(nil, "BACKGROUND")
	rightActive:SetAtlas("uiframe-activetab-right", true)
	rightActive:SetPoint("TOPRIGHT", 8, 0)
	button.RightActive = rightActive

	local middleActive = button:CreateTexture(nil, "BACKGROUND")
	middleActive:SetAtlas("_uiframe-activetab-center", true)
	middleActive:SetPoint("TOPLEFT", leftActive, "TOPRIGHT", 0, 0)
	middleActive:SetPoint("TOPRIGHT", rightActive, "TOPLEFT", 0, 0)
	middleActive:SetHorizTile(true)
	button.MiddleActive = middleActive

	-- Inactive state textures
	local left = button:CreateTexture(nil, "BACKGROUND")
	left:SetAtlas("uiframe-tab-left", true)
	left:SetPoint("TOPLEFT", -3, 0)
	button.Left = left

	local right = button:CreateTexture(nil, "BACKGROUND")
	right:SetAtlas("uiframe-tab-right", true)
	right:SetPoint("TOPRIGHT", 7, 0)
	button.Right = right

	local middle = button:CreateTexture(nil, "BACKGROUND")
	middle:SetAtlas("_uiframe-tab-center", true)
	middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
	middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
	middle:SetHorizTile(true)
	button.Middle = middle

	-- Tab text
	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 2)
	text:SetText(label)
	button.Text = text

	-- Width based on text (minimum 60px)
	button:SetWidth(math_max(60, text:GetStringWidth() + 40))

	-- Click handler
	button:SetScript("OnClick", function()
		SwitchTab(tabID)
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
	end)

	return button
end

SwitchTab = function(tabID)
	SC.currentTab    = tabID
	local isOverview = (tabID == "overview")
	local isGuides   = (tabID == "guides")

	-- Show/hide overview-specific controls
	frame.ProgressBar:SetShown(isOverview or isGuides)
	frame.PagingFrame:SetShown(isOverview)

	-- FilterDropdown is shared across overview and guides
	if frame.FilterDropdown then
		frame.FilterDropdown:SetShown(isOverview or isGuides)
		frame.FilterDropdown:ClearAllPoints()
		frame.FilterDropdown:SetPoint("TOPRIGHT", frame.Inset, "TOPRIGHT", -10, -8)
		-- Update() before the text, not after. UpdateFilterButtonText writes
		-- FilterDropdown.Text directly, and Update() regenerates the button from
		-- Blizzard's own menu state -- so running it second discarded the label
		-- we had just set and left the button reading "Filter" with no count,
		-- on a tab that did have filters applied.
		frame.FilterDropdown:Update()
		UpdateFilterButtonText()
	end

	-- Show/hide content panels
	if SC.guidesPanel then SC.guidesPanel:SetShown(isGuides) end
	if SC.aboutPanel then SC.aboutPanel:SetShown(tabID == "about") end

	if isOverview then
		if SC.updateOverviewPage then SC.updateOverviewPage(frame.currentPage) end
	else
		-- Hide overview icon buttons when leaving overview tab
		if frame.buttonPool then
			for _, btn in pairs(frame.buttonPool) do btn:Hide() end
		end
		if isGuides then
			if SC.updateProgressBar then SC.updateProgressBar() end
		end
	end

	-- Sync tab button visual states
	for _, tabBtn in pairs(SC.tabButtons_list) do
		SetTabActive(tabBtn, tabBtn.tabID == tabID)
	end
end

-- Navigate to the Guides tab and pre-select a specific entry (called from Overview icon click)
function SC:OpenGuideForEntry(entry)
	SC.guidesPreselect = entry
	SwitchTab("guides")
end

-- ==============================================
-- SHOW/HIDE HANDLERS
-- ==============================================

frame:SetScript("OnShow", function()
	SwitchTab(SC.currentTab)
end)

-- ==============================================
-- PUBLIC API
-- ==============================================

function SC:OpenSecretsFrame()
	if frame.SetTitle then
		frame:SetTitle(L["WINDOW_TITLE"] or "Secret Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText(L["WINDOW_TITLE"] or "Secret Checklist")
	end
	frame:Show()
end

function SC:CloseSecretsFrame()
	frame:Hide()
end

function SC:ToggleSecretsFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		self:OpenSecretsFrame()
	end
end

-- Backward compatibility
SC.OpenCollectionsSecretsTab = SC.OpenSecretsFrame

-- ==============================================
-- INITIALIZATION
-- ==============================================

-- Initialize on load
local function Initialize()
	-- Ensure Inset frame exists (safety check, should be created by XML)
	if not frame.Inset then
		local inset = CreateFrame("Frame", nil, frame)
		inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -60)
		inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)
		frame.Inset = inset
	end

	-- Add background to Inset for visibility
	if not frame.Inset.bg then
		local bg = frame.Inset:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.12, 0.10, 0.08, 0.98)
		frame.Inset.bg = bg
	end
	SC.themeTargets = SC.themeTargets or {}
	SC.themeTargets.insetBg = frame.Inset.bg

	-- Set title using PortraitFrameTemplate method
	if frame.SetTitle then
		frame:SetTitle(L["WINDOW_TITLE"] or "Secret Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText(L["WINDOW_TITLE"] or "Secret Checklist")
	end

	-- Set portrait icon
	local iconTexture = 454046
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture(iconTexture)
		frame.PortraitContainer.portrait:SetTexCoord(0, 1, 0, 1)
	elseif frame.SetPortraitToAsset then
		frame:SetPortraitToAsset(iconTexture)
	end

	-- Setup dragging (PortraitFrameTemplate provides this)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	-- Persist where the player put the window. Dragging worked before but the
	-- result was never saved, so the frame snapped back to centre every reload.
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		if point then
			SecretChecklistDB.framePos = { point = point, relPoint = relPoint, x = x, y = y }
		end
	end)

	-- Restore it. Anchored to UIParent rather than to whatever GetPoint returned
	-- as the relative frame, so a saved position cannot outlive its anchor.
	local pos = SecretChecklistDB.framePos
	if pos and pos.point then
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
	end


	-- Hide attic for cleaner look (if function exists)
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end

	-- Set proper font size for page text
	-- GetFont returns nil when the inherited font object has not resolved, and
	-- SetFont(nil, ...) errors.
	local fontPath, _, fontFlags = frame.PagingFrame.PageText:GetFont()
	if fontPath then
		frame.PagingFrame.PageText:SetFont(fontPath, 12, fontFlags)
	end

	-- Create filter dropdown in Lua (same path as wowhead button in TabGuides → guaranteed pill texture)
	if not frame.FilterDropdown then
		-- Parented to the Inset, not to the frame.
		--
		-- As a sibling of the Inset it landed on the same frame level (2 and 2),
		-- and sibling frames at equal level merge into one draw order by layer --
		-- so the Inset's background painted over the dropdown's pill while its
		-- arrow and label, on higher layers, still drew. The button rendered as
		-- bare text with an arrow and no chrome.
		--
		-- The Guide button in TabGuides uses this same template and never showed
		-- the problem because it is a descendant of the Inset, so it is always
		-- above it. This makes the filter button one too.
		local fd = CreateFrame("DropdownButton", nil, frame.Inset, "WowStyle1FilterDropdownTemplate")
		fd:SetSize(90, 22)
		fd:SetPoint("TOPRIGHT", frame.Inset, "TOPRIGHT", -10, -8)
		frame.FilterDropdown = fd
	end

	-- Setup filter dropdown
	if frame.FilterDropdown then
		-- Load saved preferences (per-tab)
		if SecretChecklistDB.tabFilters then
			for tab, f in pairs(SecretChecklistDB.tabFilters) do
				if tabFilters[tab] then
					if f.showCollected ~= nil then tabFilters[tab].showCollected = f.showCollected end
					if f.showMissing ~= nil then tabFilters[tab].showMissing = f.showMissing end
					if f.sortBy ~= nil then tabFilters[tab].sortBy = f.sortBy end
					if f.mindSeekerOnly ~= nil then tabFilters[tab].mindSeekerOnly = f.mindSeekerOnly end
					if f.kinds then
						for kind, enabled in pairs(f.kinds) do
							tabFilters[tab].kinds[kind] = enabled
						end
					end
				end
			end
		end

		-- Helper to save state and refresh
		local function OnFilterChanged()
			SecretChecklistDB.tabFilters = {}
			for tab, f in pairs(tabFilters) do
				SecretChecklistDB.tabFilters[tab] = {
					showCollected  = f.showCollected,
					showMissing    = f.showMissing,
					sortBy         = f.sortBy,
					mindSeekerOnly = f.mindSeekerOnly,
					kinds          = {},
				}
				for k, v in pairs(f.kinds) do
					SecretChecklistDB.tabFilters[tab].kinds[k] = v
				end
			end
			if SC.currentTab == "overview" then
				if SC.updateOverviewPage then SC.updateOverviewPage(1) end
			elseif SC.currentTab == "guides" and SC.onFilterChange then
				SC.onFilterChange()
			end
			UpdateFilterButtonText()
		end

		frame.FilterDropdown:SetupMenu(function(dropdown, rootDescription)
			-- Root level: quick toggles (HC-style)
			rootDescription:CreateCheckbox(
				L["FILTER_COLLECTED"] or "Collected",
				function()
					local f = tabFilters[SC.currentTab]; return f == nil or f.showCollected ~= false
				end,
				function()
					local f = tabFilters[SC.currentTab]; if f then
						-- nil counts as enabled, so toggling an unset filter turns it off.
					f.showCollected = (f.showCollected == false); OnFilterChanged()
					end
				end)
			rootDescription:CreateCheckbox(
				L["FILTER_NOT_COLLECTED"] or "Not Collected",
				function()
					local f = tabFilters[SC.currentTab]; return f == nil or f.showMissing ~= false
				end,
				function()
					local f = tabFilters[SC.currentTab]; if f then
						-- nil counts as enabled, so toggling an unset filter turns it off.
					f.showMissing = (f.showMissing == false); OnFilterChanged()
					end
				end)
			-- Only offered when the data has Mind-Seeker entries (retail); on
			-- Forever it would filter the list down to nothing.
			local hasMindSeeker = false
			for _, e in ipairs(SC.entries or {}) do
				if e.mindSeeker then hasMindSeeker = true; break end
			end
			if hasMindSeeker then
			rootDescription:CreateCheckbox(
				L["FILTER_MIND_SEEKER_ONLY"] or "Mind-Seeker only",
				function()
					local f = tabFilters[SC.currentTab]; return f and f.mindSeekerOnly == true
				end,
				function()
					local f = tabFilters[SC.currentTab]; if f then
						f.mindSeekerOnly = not f.mindSeekerOnly; OnFilterChanged()
					end
				end)
			end

			-- Sort by submenu
			local sortSubmenu = rootDescription:CreateButton(L["SORT_BY"] or "Sort by")
			local sortOptions = {
				{ label = L["SORT_TYPE"] or "Type",                   value = "type" },
				{ label = L["SORT_NAME"] or "Name",                   value = "name" },
				{ label = L["SORT_STATUS_INC"] or "Incomplete first", value = "status" },
				{ label = L["SORT_STATUS_COL"] or "Collected first",  value = "status_col" },
			}
			for _, opt in ipairs(sortOptions) do
				sortSubmenu:CreateRadio(opt.label,
					function()
						local f = tabFilters[SC.currentTab]; return f and f.sortBy == opt.value
					end,
					function()
						local f = tabFilters[SC.currentTab]; if f then
							f.sortBy = opt.value; OnFilterChanged()
						end
					end)
			end

			-- Type submenu
			local typeOptions = {
				{ label = L["KIND_MOUNTS"] or "Mounts",             kind = "mount" },
				{ label = L["KIND_PETS"] or "Pets",                 kind = "pet" },
				{ label = L["KIND_TOYS"] or "Toys",                 kind = "toy" },
				{ label = L["KIND_ACHIEVEMENTS"] or "Achievements", kind = "achievement" },
				{ label = L["KIND_QUESTS"] or "Quests",             kind = "quest" },
				{ label = L["KIND_TRANSMOGS"] or "Transmog",        kind = "transmog" },
				{ label = L["KIND_HOUSINGS"] or "Housing",          kind = "housing" },
				{ label = L["KIND_MYSTERIES"] or "Mystery",         kind = "mystery" },
			}
			local typeSubmenu = rootDescription:CreateButton(L["FILTER_BY_TYPE"] or "Type")
			typeSubmenu:CreateCheckbox(L["FILTER_SELECT_ALL"] or "Select All",
				function()
					local f = tabFilters[SC.currentTab]; if not f then return false end
					for _, opt in ipairs(typeOptions) do if not f.kinds[opt.kind] then return false end end
					return true
				end,
				function()
					local f = tabFilters[SC.currentTab]; if not f then return end
					for _, opt in ipairs(typeOptions) do f.kinds[opt.kind] = true end
					OnFilterChanged()
				end)
			typeSubmenu:CreateCheckbox(L["FILTER_DESELECT_ALL"] or "Deselect All",
				function()
					local f = tabFilters[SC.currentTab]; if not f then return false end
					for _, opt in ipairs(typeOptions) do if f.kinds[opt.kind] then return false end end
					return true
				end,
				function()
					local f = tabFilters[SC.currentTab]; if not f then return end
					for _, opt in ipairs(typeOptions) do f.kinds[opt.kind] = false end
					OnFilterChanged()
				end)
			typeSubmenu:CreateDivider()
			for _, opt in ipairs(typeOptions) do
				typeSubmenu:CreateCheckbox(opt.label,
					function()
						local f = tabFilters[SC.currentTab]; return f and f.kinds[opt.kind] == true
					end,
					function()
						local f = tabFilters[SC.currentTab]; if f then
							f.kinds[opt.kind] = not f.kinds[opt.kind]; OnFilterChanged()
						end
					end)
			end
		end)

		-- Reset button callbacks
		frame.FilterDropdown:SetIsDefaultCallback(function()
			local f = tabFilters[SC.currentTab]
			if not f then return true end
			if f.showCollected == false or f.showMissing == false then return false end
			if f.mindSeekerOnly then return false end
			if (f.sortBy or "type") ~= "type" then return false end
			for _, enabled in pairs(f.kinds) do
				if not enabled then return false end
			end
			return true
		end)

		frame.FilterDropdown:SetDefaultCallback(function()
			local f = tabFilters[SC.currentTab]
			if not f then return end
			f.showCollected  = true
			f.showMissing    = true
			f.mindSeekerOnly = false
			f.sortBy         = "type"
			for kind in pairs(f.kinds) do f.kinds[kind] = true end
			OnFilterChanged()
		end)

		-- Reapply our label after any Blizzard-side regeneration.
		--
		-- UpdateFilterButtonText writes FilterDropdown.Text directly, and the
		-- dropdown rewrites that text whenever it updates itself -- including
		-- once on its own, after this setup runs, when the frame is first shown.
		-- That is why the "(n)" count was missing until you switched tabs: the
		-- init-time call was correct and then immediately overwritten.
		--
		-- Hooking Update removes the ordering question altogether, rather than
		-- moving our call around and hoping nothing else regenerates the button.
		hooksecurefunc(frame.FilterDropdown, "Update", UpdateFilterButtonText)

		UpdateFilterButtonText()
	end

	SC:BuildOverviewPanel(frame, L)
	SC:BuildGuidesPanel(frame, L)
	SC:BuildAboutPanel(frame, L)

	-- Create tab buttons
	local tabDefs = {
		{ id = "overview", label = L["TAB_OVERVIEW"] or "Overview" },
		{ id = "guides",   label = L["TAB_GUIDES"] or "Guides" },
		{ id = "about",    label = L["TAB_ABOUT"] or "About" },
	}
	local prevBtn = nil
	for i, def in ipairs(tabDefs) do
		local btn = CreateTabButton(def.id, def.label)
		if i == 1 then
			btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 11, 2)
		else
			btn:SetPoint("TOPLEFT", prevBtn, "TOPRIGHT", 3, 0)
		end
		tinsert(SC.tabButtons_list, btn)
		prevBtn = btn
	end
	SC.lastTabButton = prevBtn

	-- Initialize tab display (sets currentTab, shows panels, updates page)
	SwitchTab("overview")

	-- Register frame for ESC key to close
	tinsert(UISpecialFrames, "SecretChecklistFrame")
end

-- ==============================================
-- MINIMAP BUTTON
-- ==============================================

local function CreateMinimapButton()
	local button = CreateFrame("Button", "SecretChecklistMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:EnableMouse(true)
	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Icon
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetTexture(454046)
	button.icon = icon

	-- Border
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetPoint("TOPLEFT")
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	-- Highlight
	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetSize(20, 20)
	highlight:SetPoint("CENTER", 0, 1)
	highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	highlight:SetBlendMode("ADD")

	-- Position (default to top-left of minimap)
	-- Radius 85 places the button just outside the decorative minimap ring.
	local minimapRadius = (Minimap:GetWidth() / 2) + 5
	local angle = SecretChecklistDB.minimapAngle or 225
	local x = minimapRadius * math_cos(math_rad(angle))
	local y = minimapRadius * math_sin(math_rad(angle))
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)

	-- Tooltip
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L["ADDON_NAME"] or "Secret Checklist", 1, 1, 1)
		GameTooltip:AddLine(L["TOOLTIP_CLICK_TOGGLE"] or "Click to toggle window", 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["TOOLTIP_RIGHT_CLICK_OPTIONS"] or "Right-click to open options", 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["TOOLTIP_DRAG_MOVE"] or "Drag to move", 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Click handler (left = toggle window, right = options, alt+left = About)
	button:SetScript("OnClick", function(self, mouseButton)
		if mouseButton == "RightButton" then
			if SC.OpenOptionsPanel then SC:OpenOptionsPanel() end
		elseif IsAltKeyDown() then
			SC:OpenSecretsFrame()
			SwitchTab("about")
		else
			SC:ToggleSecretsFrame()
		end
	end)

	-- Drag handler
	button:SetScript("OnDragStart", function(self)
		self:LockHighlight()
		self:SetScript("OnUpdate", function(self)
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale

			local angle = math_deg(math_atan2(py - my, px - mx))
			SecretChecklistDB.minimapAngle = angle

			local minimapRadius = (Minimap:GetWidth() / 2) + 5
			local x = minimapRadius * math_cos(math_rad(angle))
			local y = minimapRadius * math_sin(math_rad(angle))
			self:ClearAllPoints()
			self:SetPoint("CENTER", Minimap, "CENTER", x, y)
		end)
	end)

	button:SetScript("OnDragStop", function(self)
		self:UnlockHighlight()
		self:SetScript("OnUpdate", nil)
	end)

	return button
end

-- Create the minimap button
local minimapButton = CreateMinimapButton()

-- Centralized minimap visibility setter used by slash commands and settings UI.
function SC:SetMinimapButtonHidden(hidden)
	hidden = hidden == true
	SecretChecklistDB.hideMinimapButton = hidden

	if hidden then
		minimapButton:Hide()
	else
		minimapButton:Show()
	end
end

-- Public API to toggle minimap button
function SC:ToggleMinimapButton()
	self:SetMinimapButtonHidden(not SecretChecklistDB.hideMinimapButton)
end

-- Stored reference to our compartment entry (used for removal).
local compartmentData = nil

-- Centralized addon compartment visibility setter used by settings UI.
function SC:SetAddonCompartmentHidden(hidden)
	hidden = hidden == true
	SecretChecklistDB.hideAddonCompartment = hidden

	if not AddonCompartmentFrame then return end

	if hidden then
		-- Blizzard has no UnregisterAddon API, so removal means reaching into
		-- AddonCompartmentFrame.registeredAddons -- a private field with no
		-- compatibility guarantee. Guard its shape rather than assume it: if
		-- Blizzard renames or restructures it, the button simply stays visible
		-- instead of throwing on a settings change.
		if compartmentData then
			local list = AddonCompartmentFrame.registeredAddons
			if type(list) == "table" then
				-- Iterate backwards: removing while indexing forwards skips the
				-- following element, which would matter if a duplicate registration
				-- ever occurred.
				for i = #list, 1, -1 do
					if list[i] == compartmentData then
						table.remove(list, i)
					end
				end
				if AddonCompartmentFrame.UpdateDisplay then
					AddonCompartmentFrame:UpdateDisplay()
				end
			end
			compartmentData = nil
		end
	else
		if not compartmentData then
			compartmentData = {
				text        = "Secret Checklist",
				icon        = 454046,
				notCheckable = true,
				func        = SecretChecklist_OnAddonCompartmentClick,
				funcOnEnter = SecretChecklist_OnAddonCompartmentEnter,
				funcOnLeave = SecretChecklist_OnAddonCompartmentLeave,
			}
			AddonCompartmentFrame:RegisterAddon(compartmentData)
		end
	end
end

-- Register in the addon compartment on first load (called from PLAYER_LOGIN).
local function RegisterAddonCompartment()
	if not AddonCompartmentFrame then return end
	compartmentData = {
		text        = "Secret Checklist",
		icon        = 454046,
		notCheckable = true,
		func        = SecretChecklist_OnAddonCompartmentClick,
		funcOnEnter = SecretChecklist_OnAddonCompartmentEnter,
		funcOnLeave = SecretChecklist_OnAddonCompartmentLeave,
	}
	AddonCompartmentFrame:RegisterAddon(compartmentData)
end

local function CreateOptionsPanel()
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory and Settings.RegisterProxySetting and Settings.CreateCheckbox) then
		return
	end

	local category = Settings.RegisterVerticalLayoutCategory("SecretChecklist")
	SC.optionsCategory = category
	if category and category.GetID then
		SC.optionsCategoryID = category:GetID()
	end
	Settings.RegisterAddOnCategory(category)

	local function GetMinimapValue()
		return not SecretChecklistDB.hideMinimapButton
	end

	local function SetMinimapValue(value)
		SC:SetMinimapButtonHidden(not value)
	end

	local minimapSetting = Settings.RegisterProxySetting(
		category,
		"SECRETCHECKLIST_MINIMAP_ICON",
		Settings.VarType.Boolean,
		L["SETTINGS_MINIMAP_BUTTON"] or "Show Minimap Button",
		Settings.Default.True,
		GetMinimapValue,
		SetMinimapValue
	)
	Settings.CreateCheckbox(category, minimapSetting,
		L["SETTINGS_MINIMAP_BUTTON_DESC"] or "Show or hide the SecretChecklist minimap button.")

	local function GetCompartmentValue()
		return SecretChecklistDB.hideAddonCompartment ~= true
	end
	local function SetCompartmentValue(value)
		SC:SetAddonCompartmentHidden(not value)
	end
	local compartmentSetting = Settings.RegisterProxySetting(
		category,
		"SECRETCHECKLIST_ADDON_COMPARTMENT",
		Settings.VarType.Boolean,
		L["SETTINGS_ADDON_COMPARTMENT"] or "Show Addon Compartment Button",
		Settings.Default.True,
		GetCompartmentValue,
		SetCompartmentValue
	)
	Settings.CreateCheckbox(category, compartmentSetting,
		L["SETTINGS_ADDON_COMPARTMENT_DESC"] or "Show or hide the SecretChecklist button in the minimap addon compartment.")

	local function GetAlertsValue()
		return SecretChecklistDB.alertsEnabled ~= false -- default true
	end
	local function SetAlertsValue(value)
		SecretChecklistDB.alertsEnabled = value
	end
	local alertsSetting = Settings.RegisterProxySetting(
		category,
		"SECRETCHECKLIST_ALERTS",
		Settings.VarType.Boolean,
		L["SETTINGS_ALERTS"] or "Show Collection Alerts",
		Settings.Default.True,
		GetAlertsValue,
		SetAlertsValue
	)
	Settings.CreateCheckbox(category, alertsSetting,
		L["SETTINGS_ALERTS_DESC"] or "Show a toast notification when a tracked secret is newly collected.")

	-- Theme selection dropdown
	if Settings.CreateDropdown and Settings.CreateControlTextContainer then
		local function GetTheme() return SecretChecklistDB.theme or "Default" end
		local function SetTheme(value)
			-- Records that the theme is a deliberate choice, so the EllesmereUI
			-- auto-select never overrides it on a later login.
			SecretChecklistDB.themeUserSet = true
			SC:ApplyTheme(value)
		end
		local themeSetting = Settings.RegisterProxySetting(
			category,
			"SECRETCHECKLIST_THEME",
			Settings.VarType.String,
			L["SETTINGS_THEME"] or "Theme",
			"Default",
			GetTheme,
			SetTheme
		)
		-- A theme names itself in English and may additionally name locale keys
		-- for its label and description. Themes registered by other addons carry
		-- neither, so they fall through to their own English text unchanged.
		local function ThemeText(theme)
			local name = (theme.NameKey and L[theme.NameKey]) or theme.Name
			local desc = (theme.DescKey and L[theme.DescKey]) or theme.Description
			return name, desc
		end

		local function GetThemeOptions()
			local container = Settings.CreateControlTextContainer()
			-- Add Default first, then any other available themes
			local ordered = { "Default", "ElvUI", "EllesmereUI" }
			local isOrdered = {}
			for _, key in ipairs(ordered) do
				isOrdered[key] = true
				local theme = SC.themes and SC.themes[key]
				if theme and theme.Available then
					container:Add(key, ThemeText(theme))
				end
			end
			-- Add any runtime-registered themes not in the hardcoded list above
			for key, theme in pairs(SC.themes or {}) do
				if theme.Available and not isOrdered[key] then
					container:Add(key, ThemeText(theme))
				end
			end
			return container:GetData()
		end
		Settings.CreateDropdown(category, themeSetting, GetThemeOptions,
			L["SETTINGS_THEME_DESC"] or "Select a visual theme for SecretChecklist.")

		-- Guides tab style dropdown
		local function GetTabStyle() return SecretChecklistDB.guidesStyle or "sidetabs" end
		local function SetTabStyle(value)
			if SC.ApplyGuideStyle then SC.ApplyGuideStyle(value) end
		end
		local tabStyleSetting = Settings.RegisterProxySetting(
			category,
			"SECRETCHECKLIST_TAB_STYLE",
			Settings.VarType.String,
			L["SETTINGS_GUIDES_STYLE"] or "Guides tab style",
			"sidetabs",
			GetTabStyle,
			SetTabStyle
		)
		local function GetTabStyleOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add("sidetabs",
				L["GUIDES_STYLE_SIDETABS"] or "Default",
				L["GUIDES_STYLE_SIDETABS_DESC"] or "SpellBook-style side tabs on the right edge of the detail pane.")
			container:Add("horizontal",
				L["GUIDES_STYLE_HORIZONTAL"] or "Modern",
				L["GUIDES_STYLE_HORIZONTAL_DESC"] or "Classic horizontal Info / Model tab bar inside the detail pane.")
			return container:GetData()
		end
		Settings.CreateDropdown(category, tabStyleSetting, GetTabStyleOptions,
			L["SETTINGS_GUIDES_STYLE_DESC"] or "Choose how the Info and Model tabs are shown in the Guides panel.")
	end
end

function SC:OpenOptionsPanel()
	if Settings and Settings.OpenToCategory and self.optionsCategory and self.optionsCategory.GetID then
		Settings.OpenToCategory(self.optionsCategory:GetID())
		return true
	end

	if Settings and Settings.OpenToCategory and type(self.optionsCategoryID) == "number" then
		Settings.OpenToCategory(self.optionsCategoryID)
		return true
	end

	return false
end

-- Build the UI at ADDON_LOADED rather than at file scope.
--
-- Initialize() restores saved filters from SecretChecklistDB, and ADDON_LOADED
-- is the first point at which SavedVariables are guaranteed to be both loaded
-- and addressable. Running it during file execution left that read racing
-- against DB population -- the same hazard that had already forced the minimap
-- restore below onto PLAYER_LOGIN.
if frame then
	local initFrame = CreateFrame("Frame")
	initFrame:RegisterEvent("ADDON_LOADED")
	initFrame:SetScript("OnEvent", function(self, _, addonName)
		if addonName ~= "SecretChecklist" then return end
		self:UnregisterEvent("ADDON_LOADED")
		SC:InitDB()
		Initialize()
		CreateOptionsPanel()
	end)
end

-- Trigger housing storage load proactively. Declared here (file-level local)
-- so it is visible both inside the collection-events do block (where it is
-- defined) and in the PLAYER_ENTERING_WORLD block below.
local TriggerHousingStorageLoad
-- Refresh overview buttons and About model when collection data finishes loading.
-- Fixes first-open stale display caused by lazy-loaded mount/pet/toy journals.
do
	local _refreshPending = false
	local function ScheduleCollectionRefresh()
		-- Drop the status cache before the debounce guard, not after it: a second
		-- event arriving inside the 100ms window still invalidates state even
		-- though it will not schedule another redraw. Every collection, bag and
		-- housing handler funnels through here, so this is the single choke point.
		SC:InvalidateStatusCache()
		if _refreshPending then return end
		_refreshPending = true
		C_Timer.After(0.1, function()
			_refreshPending = false
			-- Alert scanning runs inside the debounce, not per event. It walks all
			-- 52 entries calling GetEntryStatus -> CheckEntry, which is 1-3 C API
			-- calls each, and its triggers include PET_JOURNAL_LIST_UPDATE and
			-- MOUNT_JOURNAL_SEARCH_UPDATED -- events that fire dozens of times a
			-- second while the player scrolls or types in their Pet/Mount Journal.
			-- Coalescing to one scan per 100ms burst is imperceptible for a toast.
			if SC.CheckForNewCollections then SC:CheckForNewCollections() end
			if frame:IsShown() and SC.currentTab == "overview" and SC.refreshOverviewDisplay then
				SC.refreshOverviewDisplay(frame.currentPage or 1)
			end
			if frame:IsShown() and SC.currentTab == "guides" and SC.onCollectionRefresh then
				SC.onCollectionRefresh()
			end
			if SC.aboutPanel and SC.aboutPanel:IsShown() then
				local onShow = SC.aboutPanel:GetScript("OnShow")
				if onShow then onShow(SC.aboutPanel) end
			end
		end)
	end

	local collectionFrame = CreateFrame("Frame")
	collectionFrame:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	collectionFrame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
	collectionFrame:RegisterEvent("TOYS_UPDATED")
	collectionFrame:RegisterEvent("ACHIEVEMENT_EARNED")
	collectionFrame:RegisterEvent("QUEST_TURNED_IN")
	collectionFrame:SetScript("OnEvent", function()
		ScheduleCollectionRefresh()
	end)

	-- Housing catalog loads asynchronously and storage data (ownership) is only
	-- populated after the housing catalog UI has been opened. Until then,
	-- entrySubtype=1 is ambiguous: it means both "genuinely unowned" AND
	-- "storage not loaded yet". To prevent UI flicker on zone transitions
	-- (where the catalog reloads and subtype briefly returns 1 before storage
	-- re-merges), we track a ready flag:
	--   false = catalog is rebuilding, storage may not be merged yet
	--   true  = HOUSING_STORAGE_UPDATED has fired, ownership data is current
	-- CheckEntry uses this to treat subtype=1+not-ready as nil (unknown)
	-- rather than false (missing), stopping the flicker.
	SC._housingStorageReady = false

	-- HOUSING_CATALOG_CATEGORY_UPDATED fires per-category during async load.
	-- Mark storage as not-ready so CheckEntry withholds judgement on subtype=1
	-- until ownership data confirms it. UI redraw is still scheduled so the
	-- display updates once storage catches up.
	local housingCatalogFrame = CreateFrame("Frame")
	housingCatalogFrame:RegisterEvent("HOUSING_CATALOG_CATEGORY_UPDATED")
	housingCatalogFrame:SetScript("OnEvent", function()
		SC._housingStorageReady = false
		ScheduleCollectionRefresh()
	end)

	-- HOUSING_STORAGE_UPDATED fires once the full storage state is ready.
	-- HOUSING_STORAGE_ENTRY_UPDATED fires on individual ownership changes.
	-- HOUSE_DECOR_ADDED_TO_CHEST fires on loot.
	-- All three confirmed to exist in-game.
	local housingFrame = CreateFrame("Frame")
	housingFrame:RegisterEvent("HOUSING_STORAGE_UPDATED")
	housingFrame:RegisterEvent("HOUSING_STORAGE_ENTRY_UPDATED")
	housingFrame:RegisterEvent("HOUSE_DECOR_ADDED_TO_CHEST")
	housingFrame:SetScript("OnEvent", function()
		SC._housingStorageReady = true
		ScheduleCollectionRefresh()
		if SC.CheckHousingCollections then SC:CheckHousingCollections() end
	end)

	-- Proactively trigger housing storage load via CreateCatalogSearcher().RunSearch().
	-- Storage is lazy-loaded (only populated when housing catalog UI opens). Called on
	-- every PLAYER_ENTERING_WORLD (covers login + all zone transitions / instance exits)
	-- so the item shows as collected without requiring the player to open housing UI.
	TriggerHousingStorageLoad = function()
		if not (C_HousingCatalog and C_HousingCatalog.CreateCatalogSearcher) then return end
		local ok, searcher = pcall(C_HousingCatalog.CreateCatalogSearcher)
		if ok and searcher then
			pcall(function()
				searcher:SetAutoUpdateOnParamChanges(false)
				searcher:RunSearch()
			end)
		end
	end

	-- Refresh step/substep item counts when bag contents change or when the bank
	-- is opened for the first time in a session (GetItemCount only returns bank
	-- data after BANKFRAME_OPENED has fired at least once).
	local bagFrame = CreateFrame("Frame")
	bagFrame:RegisterEvent("BAG_UPDATE")
	bagFrame:RegisterEvent("BANKFRAME_OPENED")
	bagFrame:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
	bagFrame:SetScript("OnEvent", function()
		ScheduleCollectionRefresh()
	end)
end

-- Apply minimap button visibility and position on PLAYER_LOGIN, which guarantees
-- SavedVariables are fully committed (reading at file-load time can race against DB population).
do
	local loginFrame = CreateFrame("Frame")
	loginFrame:RegisterEvent("PLAYER_LOGIN")
	loginFrame:SetScript("OnEvent", function(self)
		-- Restore saved position
		local angle = SecretChecklistDB.minimapAngle or 225
		local r = (Minimap:GetWidth() / 2) + 5
		minimapButton:ClearAllPoints()
		minimapButton:SetPoint("CENTER", Minimap, "CENTER",
			r * math_cos(math_rad(angle)),
			r * math_sin(math_rad(angle)))
		-- Restore saved visibility
		SC:SetMinimapButtonHidden(SecretChecklistDB.hideMinimapButton == true)
		-- Register the addon compartment entry (we manage this ourselves; no TOC directives).
		-- If the setting says hidden, skip registration entirely.
		if SecretChecklistDB.hideAddonCompartment ~= true then
			RegisterAddonCompartment()
		end
		-- themeUserSet is seeded by SC:InitDB at ADDON_LOADED, which is strictly
		-- earlier than this, so it is already correct here.
		--
		-- Auto-select ElvUI theme on first load if ElvUI is present and no theme has been saved yet.
		-- EllesmereUI, when present and able to skin us, takes precedence and
		-- claims this from its own skin callback (it can only paint once that fires).
		if not SecretChecklistDB.theme and ElvUI then
			SecretChecklistDB.theme = "ElvUI"
		end
		SC:ApplyTheme(SecretChecklistDB.theme or "Default")
		-- Restore saved Guides tab style (deferred to PLAYER_LOGIN so SavedVariables are committed)
		if SC.ApplyGuideStyle then SC.ApplyGuideStyle(SecretChecklistDB.guidesStyle or "sidetabs") end
		-- Notify player if debug mode was left enabled from a previous session
		if SecretChecklistDB.debugMode then
			print(
			"|cffffcc00SecretChecklist:|r Debug mode is |cff00ff00enabled|r — stepsOverrideOnDone is suppressed. Type /secrets debug to disable.")
		end
		-- Initialise the secret-collected alert toast system
		if SC.InitAlertSystem then SC:InitAlertSystem() end
		-- Build the initial collection snapshot after a short delay so all
		-- journals (mounts, pets, toys) have had time to finish loading.
		-- Only transitions from missing→collected AFTER this point will fire.
		C_Timer.After(5, function()
			if SC.BuildAlertSnapshot then SC:BuildAlertSnapshot() end
		end)
		self:UnregisterEvent("PLAYER_LOGIN")
	end)
end

-- Trigger housing storage load on every zone entry (login + instance exits).
-- PLAYER_ENTERING_WORLD fires for all of these, making a separate login call redundant.
do
	local zoneFrame = CreateFrame("Frame")
	zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	zoneFrame:SetScript("OnEvent", function()
		C_Timer.After(3, TriggerHousingStorageLoad)
	end)
end
