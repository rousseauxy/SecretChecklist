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

function SC:BuildGuidesPanel(frame, L)

	-- ==============================================
	-- PANEL FRAME
	-- ==============================================

	SC.guidesPanel = CreateFrame("Frame", nil, frame.Inset)
	SC.guidesPanel:SetAllPoints(frame.Inset)
	SC.guidesPanel:Hide()
	local guidesPanel = SC.guidesPanel  -- local alias for readability

	-- ---- dimension constants ----
	local GP_LEFT_W    = 240   -- width of the list pane
	local GP_DIV_W     = 2     -- divider strip
	local GP_PAD       = 8     -- general padding
	local GP_ROW_H     = 44    -- height of each list row
	local GP_FILTER_H  = 28    -- height reserved at top of list pane for filter dropdown
	local GP_TOP_DRP   = GP_PAD + 20  -- total drop from panel top to list pane start

	-- ---- per-panel state ----
	local guides_entries    = {}   -- filtered entry list
	local guides_rowButtons = {}   -- row button frames in scrollChild
	local guides_selected   = nil  -- currently selected entry
	local guides_scrollPos  = 0    -- persists scroll position across tab switches (WoW resets GetVerticalScroll on hide)
	local scrollFrame, scrollBar   -- scroll widgets assigned in Left Pane section below
	local currentNumSteps   = 0      -- step count for the currently displayed entry

	-- ==============================================
	-- FILTERING  (reads shared filter state via SC accessors)
	-- ==============================================

	local function Guides_ApplyFilter()
		guides_entries = SC:GetFilteredEntries()
	end

	-- forward declarations for mutual recursion
	local Guides_RefreshList
	local Guides_ShowDetail

	-- Called by OnFilterChanged (user changed a filter) -- resets scroll to top.
	SC.onFilterChange = function()
		guides_scrollPos = 0
		if scrollFrame then scrollFrame:SetVerticalScroll(0) end
		if scrollBar   then scrollBar:SetValue(0) end
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
	listPane:SetPoint("TOPLEFT",    guidesPanel, "TOPLEFT",    GP_PAD, -GP_TOP_DRP)
	listPane:SetPoint("BOTTOMLEFT", guidesPanel, "BOTTOMLEFT", GP_PAD,  GP_PAD)
	listPane:SetWidth(GP_LEFT_W)

	-- ScrollFrame: clips the list rows and handles vertical scrolling
	scrollFrame = CreateFrame("ScrollFrame", nil, listPane)
	scrollFrame:SetPoint("TOPLEFT",     listPane, "TOPLEFT",     0, -GP_PAD)
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
	scrollBar:SetPoint("TOPLEFT",    listPane, "TOPRIGHT",    4, -16)
	scrollBar:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 4,  16)
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
	divider:SetPoint("TOPLEFT",    listPane, "TOPRIGHT",    16, 0)  -- 6 (scrollbar) + 10
	divider:SetPoint("BOTTOMLEFT", listPane, "BOTTOMRIGHT", 16, 0)
	local dC = SC:ThemeColor("divider")
	divider:SetColorTexture(dC[1], dC[2], dC[3], dC[4])
	SC.themeTargets = SC.themeTargets or {}
	SC.themeTargets.divider   = divider
	SC.themeTargets.scrollBar = scrollBar

	-- ==============================================
	-- RIGHT DETAIL PANE
	-- ==============================================

	local DP_SCROLL_W  = 8                       -- width of the text-section scrollbar
	local DP_LINK_AREA = GP_PAD + 22 + GP_PAD   -- vertical room for linkBtn (padding + height + padding)
	local DP_TAB_H     = 26                      -- height of the Info / Model sub-tab bar
	local DP_TAB_TOP   = 8                       -- gap above the tab bar

	local detailPane = CreateFrame("Frame", nil, guidesPanel)
	detailPane:SetPoint("TOPLEFT",     divider,    "TOPRIGHT",      GP_PAD, 0)
	detailPane:SetPoint("BOTTOMRIGHT", guidesPanel, "BOTTOMRIGHT", -15, GP_PAD)

	-- ---- Info / Model sub-tab bar ----
	local detailTabBar = CreateFrame("Frame", nil, detailPane)
	detailTabBar:SetPoint("TOPLEFT",  detailPane, "TOPLEFT",  0, -DP_TAB_TOP)
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

	local infoTab  = MakeDetailTab("Info")
	local modelTab = MakeDetailTab("Model")
	-- Split tab bar in half: "BOTTOM" anchor = horizontal center of parent
	infoTab:SetPoint( "TOPLEFT",     detailTabBar, "TOPLEFT",     0, 0)
	infoTab:SetPoint( "BOTTOMRIGHT", detailTabBar, "BOTTOM",      0, 0)
	modelTab:SetPoint("TOPLEFT",     detailTabBar, "TOP",         0, 0)
	modelTab:SetPoint("BOTTOMRIGHT", detailTabBar, "BOTTOMRIGHT", 0, 0)

	-- Vertical divider between tabs and horizontal line below bar
	local tabMidLine = detailTabBar:CreateTexture(nil, "BORDER")
	tabMidLine:SetWidth(1)
	tabMidLine:SetPoint("TOPLEFT",    infoTab, "TOPRIGHT",    0,  0)
	tabMidLine:SetPoint("BOTTOMLEFT", infoTab, "BOTTOMRIGHT", 0,  0)
	tabMidLine:SetColorTexture(0.3, 0.25, 0.15, 0.6)
	local tabBarLine = detailTabBar:CreateTexture(nil, "BORDER")
	tabBarLine:SetHeight(1)
	tabBarLine:SetPoint("BOTTOMLEFT",  detailTabBar, "BOTTOMLEFT",  0, 0)
	tabBarLine:SetPoint("BOTTOMRIGHT", detailTabBar, "BOTTOMRIGHT", 0, 0)
	tabBarLine:SetColorTexture(0.3, 0.25, 0.15, 0.5)

	-- Sub-panes: both sit below the tab bar, above the Wowhead link button
	local infoPane = CreateFrame("Frame", nil, detailPane)
	infoPane:SetPoint("TOPLEFT",     detailTabBar, "BOTTOMLEFT",  0,  -2)
	infoPane:SetPoint("BOTTOMRIGHT", detailPane,   "BOTTOMRIGHT", 0,   DP_LINK_AREA)
	local modelPane = CreateFrame("Frame", nil, detailPane)
	modelPane:SetPoint("TOPLEFT",     detailTabBar, "BOTTOMLEFT",  0,  -2)
	modelPane:SetPoint("BOTTOMRIGHT", detailPane,   "BOTTOMRIGHT", 0,   DP_LINK_AREA)
	modelPane:Hide()

	-- Tab switching logic
	local activeDetailTab = "info"
	local SwitchDetailTab  -- forward declaration so SetModelTabEnabled can reference it
	local function SetModelTabEnabled(enabled)
		modelTab.hasModel = enabled
		if enabled then
			-- Show the tab bar and anchor panes below it
			detailTabBar:Show()
			infoPane:ClearAllPoints()
			infoPane:SetPoint("TOPLEFT",     detailTabBar, "BOTTOMLEFT",  0, -2)
			infoPane:SetPoint("BOTTOMRIGHT", detailPane,   "BOTTOMRIGHT", 0,  DP_LINK_AREA)
			modelPane:ClearAllPoints()
			modelPane:SetPoint("TOPLEFT",     detailTabBar, "BOTTOMLEFT",  0, -2)
			modelPane:SetPoint("BOTTOMRIGHT", detailPane,   "BOTTOMRIGHT", 0,  DP_LINK_AREA)
		else
			-- No model: hide the tab bar but preserve the same top margin as when it is shown
			detailTabBar:Hide()
			local noTabTop = -(DP_TAB_TOP + DP_TAB_H + 2)
			infoPane:ClearAllPoints()
			infoPane:SetPoint("TOPLEFT",     detailPane, "TOPLEFT",     0, noTabTop)
			infoPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
			modelPane:ClearAllPoints()
			modelPane:SetPoint("TOPLEFT",     detailPane, "TOPLEFT",     0, noTabTop)
			modelPane:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, DP_LINK_AREA)
			if activeDetailTab == "model" then
				SwitchDetailTab("info")
			end
		end
	end
	SwitchDetailTab = function(which)
		activeDetailTab = which
		infoPane:SetShown( which == "info")
		modelPane:SetShown(which == "model")
		-- Active tab: brighter bg + gold text; inactive: darker + grey (dimmer if disabled)
		infoTab.bg:SetColorTexture(  which == "info"  and 0.20 or 0.10,  which == "info"  and 0.20 or 0.10,  which == "info"  and 0.28 or 0.14, 0.95)
		modelTab.bg:SetColorTexture( which == "model" and 0.20 or 0.10,  which == "model" and 0.20 or 0.10,  which == "model" and 0.28 or 0.14, 0.95)
		if which == "info" then
			infoTab.lbl:SetTextColor( 1, 0.82, 0)
			local g = modelTab.hasModel and 0.6 or 0.35
			modelTab.lbl:SetTextColor(g, g, g)
		else
			infoTab.lbl:SetTextColor( 0.6, 0.6, 0.6)
			modelTab.lbl:SetTextColor(1, 0.82, 0)
		end
	end
	SwitchDetailTab("info")
	infoTab:SetScript( "OnClick", function() SwitchDetailTab("info") end)
	modelTab:SetScript("OnClick", function()
		if modelTab.hasModel then SwitchDetailTab("model") end
	end)

	-- ---- Scrollable text section (fills infoPane entirely) ----
	local detailScroll = CreateFrame("ScrollFrame", nil, infoPane)
	detailScroll:SetPoint("TOPLEFT",     infoPane, "TOPLEFT",     0, 0)
	detailScroll:SetPoint("BOTTOMRIGHT", infoPane, "BOTTOMRIGHT", -(DP_SCROLL_W + 4), 0)

	local detailContent = CreateFrame("Frame")
	detailContent:SetWidth(300)   -- corrected to match scroll width each time an entry is shown
	detailContent:SetHeight(500)  -- overwritten by Guides_UpdateDetailScroll
	detailScroll:SetScrollChild(detailContent)

	local detailScrollBar = CreateFrame("Slider", nil, infoPane)
	detailScrollBar:SetOrientation("VERTICAL")
	detailScrollBar:SetWidth(DP_SCROLL_W)
	detailScrollBar:SetPoint("TOPLEFT",    detailScroll, "TOPRIGHT",    4, 0)
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
	detailName:SetPoint("LEFT",  detailIcon,    "RIGHT",  10, 0)
	detailName:SetPoint("RIGHT", detailContent, "RIGHT",  -6, 0)
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
	detailSource:SetPoint("TOPLEFT",  detailStatus,  "BOTTOMLEFT", 0,  -6)
	detailSource:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT",  -6,   0)
	detailSource:SetJustifyH("LEFT")
	detailSource:SetTextColor(1, 0.82, 0)
	detailSource:SetWordWrap(true)

	-- Description (grey, word-wrapped)
	local detailDesc = detailContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailDesc:SetPoint("TOPLEFT",  detailSource,  "BOTTOMLEFT", 0,  -6)
	detailDesc:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT",  -6,   0)
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

		local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
		lbl:SetPoint("TOP",  row, "TOP",  0, 0)
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
		btn:SetPoint("LEFT",   lbl, "RIGHT",  4, 0)
		btn:SetPoint("RIGHT",  row, "RIGHT",  0, 0)
		btn:SetPoint("TOP",    row, "TOP",    0, 0)
		btn:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
		btn:SetScript("OnEnter", function(self)
			if not self.targetEntry then return end
			local e  = self.targetEntry
			local kc = ({
				mount={0.6,0.8,1}, pet={0.6,1,0.6}, toy={1,0.6,1},
				achievement={1,0.82,0}, quest={1,0.7,0.3}, transmog={0.8,0.6,1},
				housing={1,0.85,0.5}, mystery={0.7,0.5,1},
			})[e.kind] or {0.8,0.8,0.8}
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(e.name or "?", 1, 0.82, 0)
			local kindStr = e.kind and (e.kind:sub(1,1):upper()..e.kind:sub(2)) or ""
			GameTooltip:AddLine(kindStr, kc[1], kc[2], kc[3])
			local st = SC.GetEntryStatus and SC:GetEntryStatus(e) or "unknown"
			if st == "collected" then
				GameTooltip:AddLine(L["TOOLTIP_COLLECTED"] or "Collected", 0, 1, 0)
			elseif st == "missing" then
				GameTooltip:AddLine(L["TOOLTIP_NOT_COLLECTED"] or "Not collected", 1, 0, 0)
			end
			GameTooltip:AddLine("Click to view", 0.55, 0.55, 0.55)
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
							local visH     = scrollFrame:GetHeight() or 0
							local targetY  = (i - 1) * GP_ROW_H
							local scrollTo = math_max(0, targetY - math_max(0, (visH - GP_ROW_H) / 2))
							local maxScroll = math_max(0, #guides_entries * GP_ROW_H - visH)
							scrollTo = math_min(scrollTo, maxScroll)
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

	local requiresRow    = MakeReqLinkRow()
	local requiredForRow = MakeReqLinkRow()

	-- Wowhead guide link button — same visual template as the Filter dropdown
	-- DropdownButton + WowStyle1FilterDropdownTemplate gives the identical look.
	-- SetScript("OnClick") replaces the built-in dropdown-open handler entirely,
	-- so clicking shows our copy popup instead of a menu.
	local linkBtn = CreateFrame("DropdownButton", nil, detailPane, "WowStyle1FilterDropdownTemplate")
	linkBtn:SetSize(90, 22)
	linkBtn:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", 0, GP_PAD)
	linkBtn:SetText("Guide")
	linkBtn.currentURL = ""
	linkBtn:SetEnabled(false)  -- greyed until a URL is present
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
		GameTooltip:SetText("Guide", 1, 0.82, 0)
		if self.currentURL ~= "" then
			GameTooltip:AddLine("Click to copy link", 0.8, 0.8, 0.8)
		else
			GameTooltip:AddLine("No guide link yet", 0.6, 0.6, 0.6)
		end
		GameTooltip:Show()
	end)
	linkBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- Copy-link popup (UIParent child so it floats above the addon frame)
	local copyDialog = CreateFrame("Frame", nil, UIParent)
	copyDialog:SetSize(305, 52)
	copyDialog:SetFrameStrata("FULLSCREEN_DIALOG")
	copyDialog:SetFrameLevel(100)
	copyDialog:SetClampedToScreen(true)
	copyDialog:Hide()

	local copyBg = copyDialog:CreateTexture(nil, "BACKGROUND")
	copyBg:SetAllPoints()
	copyBg:SetColorTexture(0.05, 0.05, 0.08, 0.95)

	local copyBorderLine = copyDialog:CreateTexture(nil, "BORDER")
	copyBorderLine:SetPoint("TOPLEFT",     copyDialog, "TOPLEFT",      1, -1)
	copyBorderLine:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -1,  1)
	copyBorderLine:SetColorTexture(0.35, 0.30, 0.18, 0.9)

	local copyLabel = copyDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	copyLabel:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 8, -5)
	copyLabel:SetText("Ctrl+C to copy  ·  Esc to close")
	copyLabel:SetTextColor(0.65, 0.65, 0.65)

	local copyBox = CreateFrame("EditBox", nil, copyDialog)
	copyBox:SetPoint("BOTTOMLEFT",  copyDialog, "BOTTOMLEFT",   8,  6)
	copyBox:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -8,  6)
	copyBox:SetHeight(24)
	copyBox:SetAutoFocus(true)
	copyBox:SetMaxLetters(512)
	copyBox:SetFontObject("ChatFontNormal")
	copyBox:SetJustifyH("LEFT")
	copyBox:SetTextInsets(4, 4, 2, 2)
	local copyBoxBg = copyBox:CreateTexture(nil, "BACKGROUND")
	copyBoxBg:SetAllPoints()
	copyBoxBg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
	copyBox:SetScript("OnEscapePressed",   function() copyDialog:Hide() end)
	copyBox:SetScript("OnEnterPressed",    function() copyDialog:Hide() end)
	copyBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	copyBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(copyDialog.currentURL or "")
			self:HighlightText()
		end
	end)

	linkBtn:SetScript("OnClick", function(self)
		local url = self.currentURL or ""
		if url == "" then return end
		copyDialog.currentURL = url
		copyDialog:ClearAllPoints()
		-- Convert button screen position to UIParent coordinate space so the
		-- popup stays put when the main frame is dragged
		local bx, by = self:GetCenter()
		local scale  = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
		copyDialog:SetPoint("TOP", UIParent, "BOTTOMLEFT",
			bx * scale,
			(by - self:GetHeight() * 0.5) * scale - 4)
		copyBox:SetText(url)
		copyDialog:Show()
		copyBox:SetFocus()
		copyBox:HighlightText()
	end)

	-- ==============================================
	-- PROGRESS STEPS  (shown only for entries with a steps table)
	-- ==============================================

	local STEP_ROW_H  = 18
	local MAX_STEPS
	do
		local maxFound = 0
		for _, e in ipairs(SC.entries or {}) do
			local steps = e.steps
			if steps and #steps > maxFound then maxFound = #steps end
		end
		MAX_STEPS = math.max(maxFound, 1)
	end

	-- Forward-declare so step-row OnClick closures can reference these before they are defined below.
	local Guides_RelayoutSteps, Guides_UpdateDetailScroll
	local STEP_NOTE_INDENT = 14   -- note panels are indented; step headers stay flush left
	local STEP_NOTE_PAD    = 5    -- vertical padding inside note panel
	local stepsCollapsed   = true -- steps start collapsed; toggled by clicking the header

	local stepRows = {}
	for i = 1, MAX_STEPS do
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
		lbl:SetPoint("LEFT",  ico, "RIGHT", 5, 0)
		lbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		lbl:SetJustifyH("LEFT")
		row.lbl = lbl

		-- ---- Note panel (shown below the header row when the step is expanded) ----
		local np = CreateFrame("Frame", nil, detailContent)
		np:Hide()
		local npBg = np:CreateTexture(nil, "BACKGROUND")
		npBg:SetAllPoints()
		npBg:SetColorTexture(0.07, 0.07, 0.11, 0.65)

		local noteLbl = np:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noteLbl:SetPoint("TOPLEFT",  np, "TOPLEFT",  5, -STEP_NOTE_PAD)
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
		wpLbl:SetPoint("LEFT",   wpIco, "RIGHT",  3, 0)
		wpLbl:SetPoint("RIGHT",  wpBtn, "RIGHT",  0, 0)
		wpLbl:SetPoint("TOP",    wpBtn, "TOP",    0, 0)
		wpLbl:SetPoint("BOTTOM", wpBtn, "BOTTOM", 0, 0)
		wpLbl:SetJustifyH("LEFT")
		wpLbl:SetTextColor(0.4, 0.78, 1)
		wpLbl:SetText("Set Waypoint")
		wpBtn:SetScript("OnClick", function(self)
			local wp = self.waypoint
			if not wp then return end
			local label = row.lbl:GetText() or ""
			if TomTom and TomTom.AddWaypoint then
				TomTom:AddWaypoint(wp.mapID, wp.x, wp.y, { title = label })
			else
				C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(wp.mapID, wp.x, wp.y))
				C_SuperTrack.SetSuperTrackedUserWaypoint(true)
			end
		end)
		wpBtn:Hide()
		np.wpBtn = wpBtn

		row.notePanel = np
		row.isOpen    = false
		row:SetScript("OnClick", function(self)
			if not self.hasNote then return end
			self.isOpen = not self.isOpen
			self.notePanel:SetShown(self.isOpen)
			self.arrowLbl:SetText(self.isOpen and "-" or "+")
			Guides_UpdateDetailScroll(currentNumSteps, detailSource:GetText() ~= "", detailDesc:GetText() ~= "", false)
		end)

		row:Hide()
		stepRows[i] = row
	end
	-- (Row TOPLEFT anchors are set dynamically by Guides_RelayoutSteps.)

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
	stepsHdrLbl:SetPoint("LEFT",  stepsHeader, "LEFT",  6, 0)
	stepsHdrLbl:SetPoint("RIGHT", stepsHeader, "RIGHT", -6, 0)
	stepsHdrLbl:SetJustifyH("LEFT")
	stepsHdrLbl:SetTextColor(0.7, 0.7, 0.7)
	stepsHeader.lbl = stepsHdrLbl
	stepsHeader:SetScript("OnClick", function()
		stepsCollapsed = not stepsCollapsed
		if stepsCollapsed then
			-- Collapse: hide all rows and their open note panels
			for i = 1, currentNumSteps do
				stepRows[i]:Hide()
				stepRows[i].notePanel:Hide()
			end
		else
			-- Expand: show all rows (note panels stay closed until individually clicked)
			for i = 1, currentNumSteps do
				stepRows[i]:Show()
			end
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
	detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)

	-- Dedicated model for zoomed transmog slot view (mirrors AppearanceTooltip's .Zoomed model).
	-- SetKeepModelOnHide keeps the player loaded between views so TryOn can be called synchronously.
	local detailModelZoomed = CreateFrame("DressUpModel", nil, modelPane)
	detailModelZoomed:SetAllPoints(modelPane)
	detailModelZoomed:SetKeepModelOnHide(true)
	detailModelZoomed:SetUnit("player")  -- pre-load player model at creation (mirrors AppearanceTooltip's PLAYER_LOGIN)
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
			local x  = GetCursorPosition()
			local dx = x - (self.lastMouseX or x)
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
		-- Anchor the header below the last visible requirement row (or detailDesc if none)
		stepsHeader:ClearAllPoints()
		stepsHeader:SetPoint("TOPLEFT", reqLastWidget, "BOTTOMLEFT", 0, -12)
		stepsHeader:SetPoint("RIGHT",   detailContent, "RIGHT",      0,    0)
		local totalH = 12 + 20 + 4   -- pre-gap + header height + gap after header
		if stepsCollapsed then
			-- Hide all rows; only the header is shown
			for i = 1, currentNumSteps do
				stepRows[i]:Hide()
				stepRows[i].notePanel:Hide()
			end
			return totalH
		end
		local prevFrame = stepsHeader
		local contentW  = detailContent:GetWidth() or 280
		for i = 1, currentNumSteps do
			local row = stepRows[i]
			local np  = row.notePanel
			-- Anchor header below previous frame, always flush with detailContent left
			row:ClearAllPoints()
			row:SetPoint("TOP",   prevFrame,     "BOTTOM",  0,  -2)
			row:SetPoint("LEFT",  detailContent, "LEFT",    0,   0)
			row:SetPoint("RIGHT", detailContent, "RIGHT",   0,   0)
			totalH    = totalH + STEP_ROW_H + 2
			prevFrame = row
			-- If this step's note panel is open, anchor and size it
			if np:IsShown() then
				-- Give noteLbl an explicit width so GetStringHeight is accurate
				np.noteLbl:SetWidth(math_max(contentW - STEP_NOTE_INDENT - 4 - 10, 50))
				local textH  = np.noteLbl:GetStringHeight()
				local panelH = STEP_NOTE_PAD
				             + (textH > 0 and textH or 46)
				             + STEP_NOTE_PAD
				if np.itemBtn:IsShown() then panelH = panelH + 4 + 16 end
				if np.wpBtn:IsShown()   then panelH = panelH + 4 + 16 end
				panelH = panelH + STEP_NOTE_PAD  -- bottom breathing room
				np:SetHeight(panelH)
				np:ClearAllPoints()
				np:SetPoint("TOPLEFT", row,           "BOTTOMLEFT", STEP_NOTE_INDENT, 0)
				np:SetPoint("RIGHT",   detailContent, "RIGHT",      -4,               0)
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
		local h = GP_PAD + 48 + 8    -- top padding + icon row + gap below icon
		h = h + 14 + 4               -- kind badge
		h = h + 16 + 6               -- status line
		if hasSource then h = h + 40 + 6 end   -- source  (~2 wrapped lines)
		if hasDesc   then h = h + 60 + 6 end   -- desc    (~4 wrapped lines)
		if requiresRow:IsShown()    then h = h + 6 + 20 end   -- requires link row
		if requiredForRow:IsShown() then h = h + 4 + 20 end   -- requiredFor link row
		if numSteps > 0 then
			h = h + Guides_RelayoutSteps()   -- pre-gap + header + step rows + open note panels
		end
		h = h + 20   -- breathing room
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

	Guides_ShowDetail = function(entry)
		guides_selected = entry
		if not entry then
			detailIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			detailKind:SetText("")
			detailName:SetText("")
			detailStatus:SetText("")
			detailSource:SetText("")
			detailDesc:SetText("")
			requiresRow:Hide()
			requiredForRow:Hide()
			reqLastWidget = detailDesc
			linkBtn.currentURL = ""
			linkBtn:SetEnabled(false)
			copyDialog:Hide()
			for i = 1, MAX_STEPS do
				stepRows[i]:Hide()
				stepRows[i].notePanel:Hide()
				stepRows[i].isOpen = false
			end
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

		local icon = SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark"
		detailIcon:SetTexture(icon)

		local kindColors = {
			mount       = { 0.6, 0.8, 1 },
			pet         = { 0.6, 1,   0.6 },
			toy         = { 1,   0.6, 1   },
			achievement = { 1,   0.82, 0  },
			quest       = { 1,   0.7, 0.3 },
			transmog    = { 0.8, 0.6, 1   },
			housing     = { 1,   0.85, 0.5 },
			mystery     = { 0.7, 0.5,  1   },
		}
		local kc      = kindColors[entry.kind] or { 0.8, 0.8, 0.8 }
		local kindStr = entry.kind and (entry.kind:sub(1,1):upper() .. entry.kind:sub(2)) or ""
		detailKind:SetText(kindStr)
		detailKind:SetTextColor(kc[1], kc[2], kc[3])

		local entryName = SC.GetEntryName and SC:GetEntryName(entry) or entry.name or "?"
		detailName:SetText(entryName)

		local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
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
			local mountID = entry.mountID
			if not mountID and entry.itemID and C_MountJournal and C_MountJournal.GetMountFromItem then
				mountID = C_MountJournal.GetMountFromItem(entry.itemID)
			end
			if mountID and C_MountJournal and C_MountJournal.GetMountInfoExtraByID then
				local _, desc, src = C_MountJournal.GetMountInfoExtraByID(mountID)
				sourceText = src  or ""
				descText   = desc or ""
			end
		elseif entry.kind == "pet" then
			if entry.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
				local _, _, _, _, src, desc = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
				sourceText = src  or ""
				descText   = desc or ""
			end
		elseif entry.kind == "achievement" and entry.achievementID then
			local _, _, _, _, _, _, _, desc = GetAchievementInfo(entry.achievementID)
			descText = desc or ""
		elseif entry.kind == "toy" and entry.itemID then
			local _, spellID = GetItemSpell(entry.itemID)
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
		if type(entry.source) == "string" and entry.source ~= "" then sourceText = entry.source end
		if type(entry.desc)   == "string" and entry.desc   ~= "" then descText   = entry.desc   end
		-- "Part of" cross-reference shown at top of the source field
		if type(entry.partOf) == "string" and entry.partOf ~= "" then
			local prefix = "Part of: " .. entry.partOf
			sourceText = sourceText ~= "" and (prefix .. "\n" .. sourceText) or prefix
		end
		detailSource:SetText(sourceText)
		detailDesc:SetText(descText)
		-- ---- Requirement cross-reference links ----
		requiresRow:Hide()
		requiredForRow:Hide()
		reqLastWidget = detailDesc
		local prevReqWidget = detailDesc
		if type(entry.requires) == "string" and entry.requires ~= "" then
			local target
			for _, e in ipairs(SC.entries or {}) do
				if e.name == entry.requires then target = e; break end
			end
			requiresRow.lbl:SetText("Requires:")
			requiresRow.btn.targetEntry = target
			requiresRow.btn.lbl:SetText(entry.requires)
			if target then
				requiresRow.btn.lbl:SetTextColor(0.4, 0.78, 1)
				requiresRow.btn:SetEnabled(true)
			else
				requiresRow.btn.lbl:SetTextColor(0.55, 0.55, 0.55)
				requiresRow.btn:SetEnabled(false)
			end
			requiresRow:ClearAllPoints()
			requiresRow:SetPoint("TOPLEFT",  prevReqWidget, "BOTTOMLEFT", 0, -6)
			requiresRow:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT",  -6,  0)
			requiresRow:Show()
			prevReqWidget = requiresRow
			reqLastWidget = requiresRow
		end
		if type(entry.requiredFor) == "string" and entry.requiredFor ~= "" then
			local target
			for _, e in ipairs(SC.entries or {}) do
				if e.name == entry.requiredFor then target = e; break end
			end
			requiredForRow.lbl:SetText("Required for:")
			requiredForRow.btn.targetEntry = target
			requiredForRow.btn.lbl:SetText(entry.requiredFor)
			if target then
				requiredForRow.btn.lbl:SetTextColor(0.4, 0.78, 1)
				requiredForRow.btn:SetEnabled(true)
			else
				requiredForRow.btn.lbl:SetTextColor(0.55, 0.55, 0.55)
				requiredForRow.btn:SetEnabled(false)
			end
			requiredForRow:ClearAllPoints()
			requiredForRow:SetPoint("TOPLEFT",  prevReqWidget, "BOTTOMLEFT", 0, -4)
			requiredForRow:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT",  -6,  0)
			requiredForRow:Show()
			reqLastWidget = requiredForRow
		end
		-- ---- Progress Steps ----
		-- Resolve stepsRef: if this entry delegates its steps to another entry, find that entry.
		local stepsEntry = entry
		if entry.stepsRef then
			for _, e in ipairs(SC.entries or {}) do
				if e.name == entry.stepsRef then stepsEntry = e; break end
			end
		end
		local steps = stepsEntry.steps
		local numSteps = steps and #steps or 0
		currentNumSteps = numSteps
		-- If the entry opts into stepsOverrideOnDone, force all steps green once the entry itself is complete.
		-- Only use this for entries whose steps have no questIDs and get consumed on completion (e.g. Shu'halo fortunes).
		local entryDone = entry.stepsOverrideOnDone and SC.GetEntryStatus and (SC:GetEntryStatus(entry)) == "collected"
		local doneCount = 0
		for i = 1, MAX_STEPS do
			local step = steps and steps[i]
			local row  = stepRows[i]
			local np   = row.notePanel
			if step then
				local st = entryDone and "done" or (SC.GetStepStatus and SC:GetStepStatus(step) or "missing")
				-- Status dot colour + label text colour
				if st == "done" then
					doneCount = doneCount + 1
					row.ico:SetColorTexture(0, 1, 0)
					row.lbl:SetTextColor(0.53, 0.53, 0.53)
					row.lbl:SetText(step.label)
				elseif st == "ready" then
					row.ico:SetColorTexture(1, 0.82, 0)
					row.lbl:SetTextColor(1, 0.82, 0)
					row.lbl:SetText(step.label)
				else
					row.ico:SetColorTexture(1, 0, 0)
					row.lbl:SetTextColor(0.8, 0.8, 0.8)
					row.lbl:SetText(step.label)
				end
				-- Populate note panel
				np.noteLbl:SetText(step.note or "")
				-- Item hyperlink (only when item is cached; GetItemInfo returns nil otherwise)
				local itemBtn = np.itemBtn
				if step.itemID then
					local _, itemLink = GetItemInfo(step.itemID)
					if itemLink then
						local display = itemLink
						if step.count and step.count > 1 then
							display = itemLink .. "  ×" .. step.count
						end
						itemBtn.lbl:SetText(display)
						itemBtn.itemLink = itemLink
						itemBtn:SetPoint("TOPLEFT", np.noteLbl, "BOTTOMLEFT", 0, -4)
						itemBtn:SetPoint("RIGHT",   np,         "RIGHT",     -6,  0)
						itemBtn:Show()
					else
						itemBtn.itemLink = nil
						itemBtn:Hide()
					end
				else
					itemBtn.itemLink = nil
					itemBtn:Hide()
				end
				-- Waypoint button
				local wpBtn = np.wpBtn
				if step.waypoint then
					wpBtn.waypoint = step.waypoint
					local wpAnchor = itemBtn:IsShown() and itemBtn or np.noteLbl
					wpBtn:SetPoint("TOPLEFT", wpAnchor, "BOTTOMLEFT", 0, -4)
					wpBtn:SetPoint("RIGHT",   np,       "RIGHT",     -6,  0)
					wpBtn:Show()
				else
					wpBtn.waypoint = nil
					wpBtn:Hide()
				end
				-- Show expand arrow only when there is something to reveal in the note panel
				local hasNote = (step.note and step.note ~= "")
				             or itemBtn:IsShown()
				             or wpBtn:IsShown()
				row.hasNote = hasNote
				row.arrowLbl:SetShown(hasNote)
				-- Always reset collapse state when loading a new entry
				row.isOpen = false
				row.arrowLbl:SetText("+")
				np:Hide()
				row:Hide()   -- hidden until the steps header is expanded
			else
				row.hasNote = false
				row.isOpen  = false
				np:Hide()
				row:Hide()
			end
		end
		if numSteps > 0 then
			stepsCollapsed = true   -- always start collapsed when loading a new entry
			stepsHeader.lbl:SetText("+  Progress  " .. doneCount .. " / " .. numSteps .. "  steps")
			stepsHeader:Show()
		else
			stepsHeader:Hide()
		end
		Guides_UpdateDetailScroll(numSteps, sourceText ~= "", descText ~= "")
		-- ---- End Progress Steps ----

		-- Hide model strip for kinds that never have a 3-D model
		if entry.kind == "achievement" or entry.kind == "quest"
		or entry.kind == "toy"         or entry.kind == "mystery" then
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
			local mountID = entry.mountID
			if not mountID and entry.itemID and C_MountJournal and C_MountJournal.GetMountFromItem then
				mountID = C_MountJournal.GetMountFromItem(entry.itemID)
			end
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
			if cameraID == 0 then cameraID = nil end  -- 0 is truthy in Lua but means no camera
			local heldSlots = {
				INVTYPE_WEAPON=true, INVTYPE_2HWEAPON=true, INVTYPE_WEAPONMAINHAND=true,
				INVTYPE_WEAPONOFFHAND=true, INVTYPE_RANGED=true, INVTYPE_RANGEDRIGHT=true,
				INVTYPE_HOLDABLE=true, INVTYPE_SHIELD=true,
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
					detailModelScene:TransitionToModelSceneID(HOUSING_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
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

	-- ==============================================
	-- ROW BUILDER & LIST REFRESH
	-- ==============================================

	local function Guides_GetOrCreateRow(idx)
		if guides_rowButtons[idx] then return guides_rowButtons[idx] end

		local yOff = -(idx - 1) * GP_ROW_H
		local row  = CreateFrame("Button", nil, scrollChild)
		row:SetHeight(GP_ROW_H)
		row:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, yOff)
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
		lbl:SetPoint("LEFT",  ico, "RIGHT", 6,   0)
		lbl:SetPoint("RIGHT", row, "RIGHT", -14, 0)  -- leave room for status dot
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

		local visibleH  = scrollFrame:GetHeight()
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

		for i = 1, math_max(total, #guides_rowButtons) do
			local entry = guides_entries[i]
			local row   = Guides_GetOrCreateRow(i)

			if entry then
				local icon = SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark"
				row.ico:SetTexture(icon)

				local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
				local isCol  = (status == "collected")
				local isMis  = (status == "missing")
				row.ico:SetDesaturated(not isCol)

				local entryName = SC.GetEntryName and SC:GetEntryName(entry) or entry.name or "?"
				row.lbl:SetText(entryName)
				if isCol then
					row.lbl:SetTextColor(1, 0.82, 0)
				else
					row.lbl:SetTextColor(0.5, 0.5, 0.5)
				end

				if isCol then
					row.dot:SetColorTexture(0, 1, 0)
				elseif isMis then
					row.dot:SetColorTexture(1, 0, 0)
				else
					row.dot:SetColorTexture(0.5, 0.5, 0.5)
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
					local visH     = scrollFrame:GetHeight() or 0
					local targetY  = (i - 1) * GP_ROW_H
					local scrollTo = math_max(0, targetY - math_max(0, (visH - GP_ROW_H) / 2))
					local maxScroll = math_max(0, #guides_entries * GP_ROW_H - visH)
					scrollTo = math_min(scrollTo, maxScroll)
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

end  -- SC:BuildGuidesPanel
