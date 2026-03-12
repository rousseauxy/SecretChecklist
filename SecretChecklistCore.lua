-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs
local math_min, math_max = math.min, math.max
local math_cos, math_sin, math_atan2, math_deg, math_rad = math.cos, math.sin, math.atan2, math.deg, math.rad
local tinsert = table.insert
local string_format = string.format

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
local defaultKinds = { mount=true, pet=true, toy=true, achievement=true, quest=true, transmog=true }
local tabFilters = {
	overview = { status = "all",     kinds = { mount=true, pet=true, toy=true, achievement=true, quest=true, transmog=true } },
	guides   = { status = "missing", kinds = { mount=true, pet=true, toy=true, achievement=true, quest=true, transmog=true } },
}

-- Read-only accessors: return filters for the currently active tab
function SC:GetFilterStatus()
	local f = tabFilters[SC.currentTab]
	return f and f.status or "all"
end
function SC:GetFilterKinds()
	local f = tabFilters[SC.currentTab]
	return f and f.kinds or defaultKinds
end

-- ==============================================
-- FILTERING
-- ==============================================

local function GetFilteredEntries()
	local entries = SC.entries or {}
	local f = tabFilters[SC.currentTab] or tabFilters.overview
	local filterStatus = f.status
	local filterKinds  = f.kinds
	
	local filtered = {}
	for _, entry in ipairs(entries) do
		local shouldInclude = true
		
		-- First filter by kind/type
		local entryKind = entry.kind or "unknown"
		if not filterKinds[entryKind] then
			shouldInclude = false
		end
		
		-- Then filter by collection status if not "all"
		if shouldInclude and filterStatus ~= "all" then
			local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
			
			if filterStatus == "collected" and status ~= "collected" then
				shouldInclude = false
			elseif filterStatus == "missing" and not (status == "missing" or status == "unknown" or status == "manual") then
				shouldInclude = false
			end
		end
		
		-- Entry passed all filters
		if shouldInclude then
			tinsert(filtered, entry)
		end
	end
	
	return filtered
end

local function UpdateFilterButtonText()
	if not frame.FilterDropdown or not frame.FilterDropdown.Text then return end
	local f = tabFilters[SC.currentTab]
	if not f then return end
	local count = 0
	if f.status ~= "all" then count = count + 1 end
	for _, enabled in pairs(f.kinds) do
		if not enabled then count = count + 1 end
	end
	frame.FilterDropdown.Text:SetText(count > 0 and string_format(L["FILTER_WITH_COUNT"] or "Filter (%d)", count) or L["FILTER"] or "Filter")
end

-- Expose filtered entries to tab panel files
function SC:GetFilteredEntries() return GetFilteredEntries() end

-- ==============================================
-- TAB SYSTEM
-- ==============================================

local function SetTabActive(button, isActive)
	if isActive then
		button.LeftActive:Show(); button.RightActive:Show(); button.MiddleActive:Show()
		button.Left:Hide(); button.Right:Hide(); button.Middle:Hide()
		button.Text:SetFontObject("GameFontHighlightSmall")
	else
		button.LeftActive:Hide(); button.RightActive:Hide(); button.MiddleActive:Hide()
		button.Left:Show(); button.Right:Show(); button.Middle:Show()
		button.Text:SetFontObject("GameFontNormalSmall")
	end
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
	SC.currentTab = tabID
	local isOverview = (tabID == "overview")
	local isGuides   = (tabID == "guides")

	-- Show/hide overview-specific controls
	frame.ProgressBar:SetShown(isOverview)
	frame.PagingFrame:SetShown(isOverview)

	-- FilterDropdown is shared: overview anchors top-right of Inset;
	-- guides anchors top-right of the list pane (inside the left panel)
	if frame.FilterDropdown then
		frame.FilterDropdown:SetShown(isOverview or isGuides)
		frame.FilterDropdown:ClearAllPoints()
		if isGuides and SC.guidesListPane then
			frame.FilterDropdown:SetPoint("TOPRIGHT", SC.guidesListPane, "TOPRIGHT", 0, 0)
		else
			frame.FilterDropdown:SetPoint("TOPRIGHT", frame.Inset, "TOPRIGHT", -10, -8)
		end
		UpdateFilterButtonText()
		frame.FilterDropdown:Update()
	end

	-- Show/hide content panels
	if SC.guidesPanel then SC.guidesPanel:SetShown(isGuides) end
	if SC.aboutPanel  then SC.aboutPanel:SetShown(tabID == "about")  end

	if isOverview then
		if SC.updateOverviewPage then SC.updateOverviewPage(frame.currentPage) end
	else
		if frame.buttonPool then
			for _, btn in pairs(frame.buttonPool) do btn:Hide() end
		end
	end

	-- Sync tab button visual states
	for _, tabBtn in pairs(SC.tabButtons_list) do
		SetTabActive(tabBtn, tabBtn.tabID == tabID)
	end
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
		frame:SetTitle(L["WINDOW_TITLE"] or "Secrets Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText(L["WINDOW_TITLE"] or "Secrets Checklist")
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
	
	-- Set title using PortraitFrameTemplate method
	if frame.SetTitle then
		frame:SetTitle(L["WINDOW_TITLE"] or "Secrets Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText(L["WINDOW_TITLE"] or "Secrets Checklist")
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
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	
	-- Hide attic for cleaner look (if function exists)
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end
	
	-- Set proper font size for page text
	local fontPath, _, fontFlags = frame.PagingFrame.PageText:GetFont()
	frame.PagingFrame.PageText:SetFont(fontPath, 12, fontFlags)
	
	-- Setup filter dropdown
	if frame.FilterDropdown then
		-- Load saved preferences (per-tab)
		if SecretChecklistDB.tabFilters then
			for tab, f in pairs(SecretChecklistDB.tabFilters) do
				if tabFilters[tab] then
					if f.status then tabFilters[tab].status = f.status end
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
				SecretChecklistDB.tabFilters[tab] = { status = f.status, kinds = {} }
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
			rootDescription:CreateTitle(L["FILTER_BY_STATUS"] or "Filter by Status")
			
			-- Status radio buttons
			local statusOptions = {
				{label = L["FILTER_ALL"] or "All", value = "all"},
				{label = L["FILTER_COLLECTED"] or "Collected", value = "collected"},
				{label = L["FILTER_MISSING"] or "Missing", value = "missing"},
			}
			for _, opt in ipairs(statusOptions) do
				rootDescription:CreateRadio(opt.label,
					function() local f = tabFilters[SC.currentTab]; return f and f.status == opt.value end,
					function() local f = tabFilters[SC.currentTab]; if f then f.status = opt.value; OnFilterChanged() end end)
			end
			
			rootDescription:CreateDivider()
			rootDescription:CreateTitle(L["FILTER_BY_TYPE"] or "Filter by Type")
			
			-- Type checkboxes
			local typeOptions = {
				{label = L["KIND_MOUNTS"] or "Mounts", kind = "mount"},
				{label = L["KIND_PETS"] or "Pets", kind = "pet"},
				{label = L["KIND_TOYS"] or "Toys", kind = "toy"},
				{label = L["KIND_ACHIEVEMENTS"] or "Achievements", kind = "achievement"},
				{label = L["KIND_QUESTS"] or "Quests", kind = "quest"},
				{label = L["KIND_TRANSMOGS"] or "Transmog", kind = "transmog"},
			}
			
			-- Select All / Deselect All buttons
			rootDescription:CreateButton(L["FILTER_SELECT_ALL"] or "Select All", function()
				local f = tabFilters[SC.currentTab]; if not f then return end
				for _, opt in ipairs(typeOptions) do
					f.kinds[opt.kind] = true
				end
				OnFilterChanged()
			end)
			rootDescription:CreateButton(L["FILTER_DESELECT_ALL"] or "Deselect All", function()
				local f = tabFilters[SC.currentTab]; if not f then return end
				for _, opt in ipairs(typeOptions) do
					f.kinds[opt.kind] = false
				end
				OnFilterChanged()
			end)
		
		rootDescription:CreateDivider()
		
		for _, opt in ipairs(typeOptions) do
			rootDescription:CreateCheckbox(opt.label,
				function() local f = tabFilters[SC.currentTab]; return f and f.kinds[opt.kind] == true end,
				function() local f = tabFilters[SC.currentTab]; if f then f.kinds[opt.kind] = not f.kinds[opt.kind]; OnFilterChanged() end end)
		end
	end)

	-- Reset button callbacks
	frame.FilterDropdown:SetIsDefaultCallback(function()
		local f = tabFilters[SC.currentTab]
		if not f then return true end
		if f.status ~= "all" then return false end
		for _, enabled in pairs(f.kinds) do
			if not enabled then return false end
		end
		return true
	end)

	frame.FilterDropdown:SetDefaultCallback(function()
		local f = tabFilters[SC.currentTab]
		if not f then return end
		f.status = "all"
		for kind in pairs(f.kinds) do f.kinds[kind] = true end
		OnFilterChanged()
	end)

	UpdateFilterButtonText()
end

	SC:BuildOverviewPanel(frame, L)
	SC:BuildGuidesPanel(frame, L)
	SC:BuildAboutPanel(frame, L)

	-- Create tab buttons (Overview | Guides | About)
	local tabDefs = {
		{ id = "overview", label = L["TAB_OVERVIEW"] or "Overview" },
		{ id = "guides",   label = L["TAB_GUIDES"]   or "Guides"   },
		{ id = "about",    label = L["TAB_ABOUT"]    or "About"    },
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
	button:RegisterForClicks("LeftButtonUp")
	
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
	local angle = SecretChecklistDB.minimapAngle or 225
	local x = 80 * math_cos(math_rad(angle))
	local y = 80 * math_sin(math_rad(angle))
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	
	-- Tooltip
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(L["ADDON_NAME"] or "Secrets Checklist", 1, 1, 1)
		GameTooltip:AddLine(L["TOOLTIP_CLICK_TOGGLE"] or "Click to toggle window", 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["TOOLTIP_DRAG_MOVE"] or "Drag to move", 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Click handler
	button:SetScript("OnClick", function(self)
		SC:ToggleSecretsFrame()
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
			
			local x = 80 * math_cos(math_rad(angle))
			local y = 80 * math_sin(math_rad(angle))
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
	Settings.CreateCheckbox(category, minimapSetting, L["SETTINGS_MINIMAP_BUTTON_DESC"] or "Show or hide the SecretChecklist minimap button.")
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

-- Initialize when the frame is first loaded
if frame then
	Initialize()
	CreateOptionsPanel()
	SC:SetMinimapButtonHidden(SecretChecklistDB.hideMinimapButton == true)
end
