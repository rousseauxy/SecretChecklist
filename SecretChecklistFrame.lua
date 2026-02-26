-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs
local math_min, math_max, math_ceil = math.min, math.max, math.ceil
local math_cos, math_sin, math_atan2, math_deg, math_rad = math.cos, math.sin, math.atan2, math.deg, math.rad
local tinsert = table.insert

local SC = _G.SecretChecklist
if not SC then return end

-- Reference to the XML-defined frame
local frame = SecretChecklistFrame
if not frame then return end

-- ==============================================
-- LAYOUT CONSTANTS
-- ==============================================

local BUTTON_WIDTH = 208
local BUTTON_HEIGHT = 50
local BUTTONS_PER_ROW = 3
local BUTTONS_PER_PAGE = 21
local START_OFFSET_X = 38
local START_OFFSET_Y = -40
local BUTTON_PADDING_X = 0
local BUTTON_PADDING_Y = 16

-- ==============================================
-- STATE
-- ==============================================

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff66c0ffSecretChecklist|r: " .. tostring(msg))
end

-- Button pool
frame.buttonPool = {}
frame.currentPage = 1

-- Filter state (persisted in SavedVariables)
SecretChecklistDB.filters = SecretChecklistDB.filters or {
	showCollected = true,
	showUncollected = true,
}

-- ==============================================
-- BUTTON CREATION
-- ==============================================

local function CreateSecretButton(parent, index)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	
	-- Constrain hit rect to icon area only (left side, 56px width including border)
	button:SetHitRectInsets(0, BUTTON_WIDTH - 56, 0, 0)
	
	-- Icon texture (shown when collected)
	local iconTexture = button:CreateTexture(nil, "BORDER")
	iconTexture:SetSize(46, 46)
	iconTexture:SetPoint("LEFT", 4, 0)
	iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.iconTexture = iconTexture
	
	-- Uncollected icon overlay
	local iconTextureUncollected = button:CreateTexture(nil, "BORDER")
	iconTextureUncollected:SetSize(46, 46)
	iconTextureUncollected:SetPoint("LEFT", 4, 0)
	iconTextureUncollected:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	iconTextureUncollected:SetDesaturated(true)
	iconTextureUncollected:Hide()
	button.iconTextureUncollected = iconTextureUncollected
	
	-- Slot frame for collected (background border)
	local slotFrameCollected = button:CreateTexture(nil, "ARTWORK", nil, -1)
	slotFrameCollected:SetSize(56, 56)
	slotFrameCollected:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
	slotFrameCollected:SetAtlas("collections-itemborder-collected")
	button.slotFrameCollected = slotFrameCollected
	
	-- Slot frame for uncollected
	local slotFrameUncollected = button:CreateTexture(nil, "ARTWORK", nil, -1)
	slotFrameUncollected:SetSize(56, 56)
	slotFrameUncollected:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
	slotFrameUncollected:SetAtlas("collections-itemborder-uncollected")
	slotFrameUncollected:Hide()
	button.slotFrameUncollected = slotFrameUncollected
	
	-- Inner glow for uncollected
	local slotFrameUncollectedInnerGlow = button:CreateTexture(nil, "ARTWORK")
	slotFrameUncollectedInnerGlow:SetSize(56, 56)
	slotFrameUncollectedInnerGlow:SetPoint("CENTER", slotFrameUncollected)
	slotFrameUncollectedInnerGlow:SetAtlas("collections-itemborder-glow")
	slotFrameUncollectedInnerGlow:SetBlendMode("ADD")
	slotFrameUncollectedInnerGlow:Hide()
	button.slotFrameUncollectedInnerGlow = slotFrameUncollectedInnerGlow
	
	-- Name text beside icon
	local name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetSize(140, 0)
	name:SetPoint("LEFT", 65, 1)
	name:SetJustifyH("LEFT")
	name:SetMaxLines(2)
	button.name = name
	
	-- Highlight texture (only around icon, not text)
	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlight:SetBlendMode("ADD")
	highlight:SetSize(46, 46)
	highlight:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
	button:SetHighlightTexture(highlight)
	
	-- Tooltip handler
	button:SetScript("OnEnter", function(self)
		if not self.entry then return end
		
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("BOTTOMLEFT", self.slotFrameCollected, "TOPRIGHT", -2, -2)
		
		-- Show proper in-game tooltip based on entry type
		local entry = self.entry
		local success = false
		
		if entry.kind == "toy" and entry.itemID then
			success = pcall(function() GameTooltip:SetToyByItemID(entry.itemID) end)
		elseif entry.kind == "mount" then
			-- Try mountID first
			if entry.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
				local _, spellID = C_MountJournal.GetMountInfoByID(entry.mountID)
				if spellID then
					success = pcall(function() GameTooltip:SetMountBySpellID(spellID) end)
				end
			end
			-- Then try spellID
			if not success and entry.spellID then
				success = pcall(function() GameTooltip:SetMountBySpellID(entry.spellID) end)
			end
			-- Finally try itemID
			if not success and entry.itemID then
				success = pcall(function() GameTooltip:SetItemByID(entry.itemID) end)
			end
		elseif entry.kind == "pet" then
			-- Try itemID first if available
			if entry.itemID then
				success = pcall(function() GameTooltip:SetItemByID(entry.itemID) end)
			end
			-- For pets with speciesID but no itemID (like Jenafur), show custom tooltip
			if not success and entry.speciesID and C_PetJournal then
				local speciesName = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
				if speciesName then
					GameTooltip:SetText(speciesName, 1, 1, 1)
					local numOwned = select(1, C_PetJournal.GetNumCollectedInfo(entry.speciesID))
					if numOwned and numOwned > 0 then
						GameTooltip:AddLine("Collected", 0, 1, 0)
					else
						GameTooltip:AddLine("Not collected", 1, 0, 0)
					end
					success = true
				end
			end
		elseif entry.kind == "achievement" and entry.achievementID then
			success = pcall(function() GameTooltip:SetHyperlink("achievement:" .. entry.achievementID) end)
		elseif entry.kind == "spell" and entry.spellID then
			success = pcall(function() GameTooltip:SetSpellByID(entry.spellID) end)
		elseif entry.kind == "transmog" and entry.itemID then
			success = pcall(function() GameTooltip:SetItemByID(entry.itemID) end)
		elseif entry.kind == "quest" and entry.questID then
			-- Show custom tooltip for quests
			GameTooltip:SetText(entry.name or "(unknown)", 1, 1, 1)
			if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
				local completed = C_QuestLog.IsQuestFlaggedCompleted(entry.questID)
				if completed then
					GameTooltip:AddLine("Completed", 0, 1, 0)
				else
					GameTooltip:AddLine("Not completed", 1, 0, 0)
				end
			end
			success = true
		end
		
		if not success then
			-- Fallback: show name and details
			GameTooltip:SetText(entry.name or "(unknown)", 1, 1, 1)
			if entry.note then
				GameTooltip:AddLine(entry.note, 0.8, 0.8, 0.8, true)
			end
		end
		
		GameTooltip:Show()
	end)
	
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	return button
end

-- Function to get or create a button from the pool
local function GetButton(index)
	if not frame.buttonPool[index] then
		frame.buttonPool[index] = CreateSecretButton(frame, index)
	end
	return frame.buttonPool[index]
end

-- ==============================================
-- FILTERING
-- ==============================================

local function GetFilteredEntries()
	local entries = SC.entries or {}
	local filtered = {}
	local filters = SecretChecklistDB.filters or {}
	
	for _, entry in ipairs(entries) do
		local status = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
		local showThis = false
		
		if status == "collected" and filters.showCollected then
			showThis = true
		elseif (status == "missing" or status == "unknown" or status == "manual") and filters.showUncollected then
			showThis = true
		end
		
		if showThis then
			tinsert(filtered, entry)
		end
	end
	
	return filtered
end

-- ==============================================
-- LAYOUT FUNCTION
-- ==============================================

local function LayoutCurrentPage()
	local entries = GetFilteredEntries()
	
	-- Calculate page boundaries
	local startIndex = (frame.currentPage - 1) * BUTTONS_PER_PAGE + 1
	local endIndex = math_min(startIndex + BUTTONS_PER_PAGE - 1, #entries)
	
	-- Hide all buttons first
	for _, button in pairs(frame.buttonPool) do
		button:Hide()
	end
	
	-- Layout visible items
	local buttonIndex = 1
	local row = 0
	local col = 0
	
	for i = startIndex, endIndex do
		local entry = entries[i]
		local button = GetButton(buttonIndex)
		
		-- Set button data
		button.entry = entry
		button.iconTexture:SetTexture(SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")
		button.iconTextureUncollected:SetTexture(SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")
		button.name:SetText(entry.name or "(unknown)")
		
		-- Check if player has the item
		local status = "unknown"
		if SC.GetEntryStatus then
			status = SC:GetEntryStatus(entry)
		end
		
		if status == "collected" then
			button.iconTexture:Show()
			button.iconTextureUncollected:Hide()
			button.name:SetTextColor(1, 0.82, 0, 1)
			button.name:SetShadowColor(0, 0, 0, 1)
			button.slotFrameCollected:Show()
			button.slotFrameUncollected:Hide()
			button.slotFrameUncollectedInnerGlow:Hide()
		elseif status == "missing" then
			button.iconTexture:Hide()
			button.iconTextureUncollected:Show()
			button.name:SetTextColor(0.33, 0.27, 0.20, 1)
			button.name:SetShadowColor(0, 0, 0, 0.33)
			button.slotFrameCollected:Hide()
			button.slotFrameUncollected:Show()
			button.slotFrameUncollectedInnerGlow:Show()
		else
			-- Unknown/manual entries
			button.iconTexture:Hide()
			button.iconTextureUncollected:Show()
			button.name:SetTextColor(1.0, 0.82, 0.0, 1)
			button.name:SetShadowColor(0, 0, 0, 1)
			button.slotFrameCollected:Hide()
			button.slotFrameUncollected:Show()
			button.slotFrameUncollectedInnerGlow:Hide()
		end
		
		-- Position button in grid (relative to Inset frame)
		local x = START_OFFSET_X + col * (BUTTON_WIDTH + BUTTON_PADDING_X)
		local y = START_OFFSET_Y - row * (BUTTON_HEIGHT + BUTTON_PADDING_Y)
		
		button:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", x, y)
		button:Show()
		
		buttonIndex = buttonIndex + 1
		col = col + 1
		
		-- Move to next row if we've filled the current row
		if col >= BUTTONS_PER_ROW then
			row = row + 1
			col = 0
		end
	end
end

-- ==============================================
-- PAGING AND UI CONTROLS
-- ==============================================

-- Function to calculate total pages
local function CalculateTotalPages()
	local entries = GetFilteredEntries()
	return math_ceil(#entries / BUTTONS_PER_PAGE)
end

-- Update progress bar
local function UpdateProgressBar()
	local trackable = 0
	local collected = 0
	local entries = SC.entries or {}
	
	for _, entry in ipairs(entries) do
		if entry.kind ~= "manual" and not entry.linkedSecret then
			trackable = trackable + 1
			local have = SC.CheckEntry and SC:CheckEntry(entry)
			if have == true then
				collected = collected + 1
			end
		end
	end
	
	-- Update progress bar and text
	frame.ProgressBar.Text:SetText(string.format("%d/%d", collected, trackable))
	
	if trackable > 0 then
		frame.ProgressBar:SetMinMaxValues(0, trackable)
		frame.ProgressBar:SetValue(collected)
	else
		frame.ProgressBar:SetMinMaxValues(0, 1)
		frame.ProgressBar:SetValue(0)
	end
end

-- Update paging frame
local function UpdatePagingFrame()
	local maxPages = CalculateTotalPages()
	frame.PagingFrame.PageText:SetText("Page " .. frame.currentPage .. " / " .. maxPages)
	frame.PagingFrame.PrevPageButton:SetEnabled(frame.currentPage > 1)
	frame.PagingFrame.NextPageButton:SetEnabled(frame.currentPage < maxPages)
end

-- Function to update page display
local function UpdatePage(newPage)
	frame.currentPage = newPage
	SC:RefreshCaches()
	LayoutCurrentPage()
	UpdateProgressBar()
	UpdatePagingFrame()
end

-- Mouse wheel scrolling through pages
frame:SetScript("OnMouseWheel", function(self, delta)
	local maxPages = CalculateTotalPages()
	
	if delta > 0 then
		-- Scroll up - go to previous page
		if frame.currentPage > 1 then
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			UpdatePage(frame.currentPage - 1)
		end
	else
		-- Scroll down - go to next page
		if frame.currentPage < maxPages then
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			UpdatePage(frame.currentPage + 1)
		end
	end
end)

-- Paging button handlers
frame.PagingFrame.PrevPageButton:SetScript("OnClick", function()
	if frame.currentPage > 1 then
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		UpdatePage(frame.currentPage - 1)
	end
end)

frame.PagingFrame.NextPageButton:SetScript("OnClick", function()
	local maxPages = CalculateTotalPages()
	if frame.currentPage < maxPages then
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		UpdatePage(frame.currentPage + 1)
	end
end)

-- ==============================================
-- SHOW/HIDE HANDLERS
-- ==============================================

frame:SetScript("OnShow", function()
	UpdatePage(frame.currentPage)
end)

-- ==============================================
-- PUBLIC API
-- ==============================================

function SC:OpenSecretsFrame()
	-- Set title using PortraitFrameTemplate method
	if frame.SetTitle then
		frame:SetTitle("Secrets Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText("Secrets Checklist")
	elseif frame.Title then
		-- Fallback for older versions
		frame.Title:SetText("Secrets Checklist")
	end
	frame:Show()
	return true
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
		Print("Created Inset frame manually (should have been in XML)")
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
		frame:SetTitle("Secrets Checklist")
	elseif frame.TitleText then
		frame.TitleText:SetText("Secrets Checklist")
	end
	
	-- Set portrait icon
	local iconTexture = 237388
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
	
	-- Setup filter checkboxes
	if frame.UncollectedFilterCheckbox then
		frame.UncollectedFilterCheckbox:SetChecked(SecretChecklistDB.filters.showUncollected)
		frame.UncollectedFilterCheckbox.Text:SetText("Not Collected")
		frame.UncollectedFilterCheckbox:SetScript("OnClick", function(self)
			SecretChecklistDB.filters.showUncollected = self:GetChecked()
			frame.currentPage = 1
			UpdatePage(frame.currentPage)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
	end
	
	if frame.CollectedFilterCheckbox then
		frame.CollectedFilterCheckbox:SetChecked(SecretChecklistDB.filters.showCollected)
		frame.CollectedFilterCheckbox.Text:SetText("Collected")
		frame.CollectedFilterCheckbox:SetScript("OnClick", function(self)
			SecretChecklistDB.filters.showCollected = self:GetChecked()
			frame.currentPage = 1
			UpdatePage(frame.currentPage)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
	end
	
	-- Initial update
	UpdatePage(1)
	
	-- Register frame for ESC key to close
	tinsert(UISpecialFrames, "SecretChecklistFrame")
	
	Print("Standalone window ready. Use /secrets to open.")
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
	icon:SetTexture(237388)
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
		GameTooltip:SetText("Secrets Checklist", 1, 1, 1)
		GameTooltip:AddLine("Click to toggle window", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
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

-- Initialize when the frame is first loaded
if frame then
	Initialize()
end
