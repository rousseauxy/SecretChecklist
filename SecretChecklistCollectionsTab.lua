-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs
local math_min, math_max, math_ceil = math.min, math.max, math.ceil

local SC = _G.SecretChecklist
if not SC then return end

local SecureTabs = LibStub("SecureTabs-2.0")

-- ==============================================
-- LAYOUT CONSTANTS (matching MDungeonTeleports)
-- ==============================================

local BUTTON_WIDTH = 208
local BUTTON_HEIGHT = 50
local BUTTONS_PER_ROW = 3
local BUTTONS_PER_PAGE = 21
local START_OFFSET_X = 40
local START_OFFSET_Y = -85
local BUTTON_PADDING_X = 0
local BUTTON_PADDING_Y = 16

-- ==============================================
-- STATE AND HELPER FUNCTIONS
-- ==============================================

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff66c0ffSecretChecklist|r: " .. tostring(msg))
end

-- Helper function to hide all Blizzard collection frames
local function HideBlizzardCollectionFrames()
	local frames = {
		MountJournal,
		PetJournal,
		ToyBox,
		HeirloomsJournal,
		WardrobeCollectionFrame,
		WarbandSceneJournal,
		ManuscriptsSideTabsFrame
	}
	for i = 1, #frames do
		local frame = frames[i]
		if frame and frame.Hide then
			frame:Hide()
		end
	end
end

-- ==============================================
-- FRAME CREATION
-- ==============================================

-- Main frame for Secrets tab (nil name to avoid global namespace pollution)
local SecretsFrame = CreateFrame("Frame", nil, CollectionsJournal)
SecretsFrame:SetAllPoints()
SecretsFrame:Hide()
SecretsFrame:SetPropagateMouseMotion(true)
SecretsFrame:SetPropagateMouseClicks(true)
SecretsFrame:EnableMouseWheel(true)

-- Background using Blizzard's template (positioned below top bar)
local bgFrame = CreateFrame("Frame", nil, SecretsFrame, "CollectionsBackgroundTemplate")
bgFrame:SetPoint("TOPLEFT", 4, -60)
bgFrame:SetPoint("BOTTOMRIGHT", -6, 5)
bgFrame:SetFrameLevel(1)

-- Hide background texture if ElvUI is loaded
if C_AddOns.IsAddOnLoaded("ElvUI") then
	bgFrame:Hide()
end

-- Create button pool
SecretsFrame.buttonPool = {}
SecretsFrame.currentPage = 1

-- ==============================================
-- BUTTON CREATION (matching MDungeonTeleports)
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
	if not SecretsFrame.buttonPool[index] then
		SecretsFrame.buttonPool[index] = CreateSecretButton(SecretsFrame, index)
	end
	return SecretsFrame.buttonPool[index]
end

-- ==============================================
-- LAYOUT FUNCTION
-- ==============================================

local function LayoutCurrentPage()
	local entries = SC.entries or {}
	
	-- Calculate page boundaries
	local startIndex = (SecretsFrame.currentPage - 1) * BUTTONS_PER_PAGE + 1
	local endIndex = math.min(startIndex + BUTTONS_PER_PAGE - 1, #entries)
	
	-- Hide all buttons first
	for _, button in pairs(SecretsFrame.buttonPool) do
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
		
		-- Position button in grid
		local x = START_OFFSET_X + col * (BUTTON_WIDTH + BUTTON_PADDING_X)
		local y = START_OFFSET_Y - row * (BUTTON_HEIGHT + BUTTON_PADDING_Y)
		
		button:SetPoint("TOPLEFT", SecretsFrame, "TOPLEFT", x, y)
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
	local entries = SC.entries or {}
	return math.ceil(#entries / BUTTONS_PER_PAGE)
end

-- Function to update page display
local function UpdatePage(newPage)
	SecretsFrame.currentPage = newPage
	SC:RefreshCaches()
	LayoutCurrentPage()
	
	if SecretsFrame.PagingFrame then
		SecretsFrame.PagingFrame:SetCurrentPage(newPage)
	end
end

-- Mouse wheel scrolling through pages
SecretsFrame:SetScript("OnMouseWheel", function(self, delta)
	local maxPages = CalculateTotalPages()
	
	if delta > 0 then
		-- Scroll up - go to previous page
		if SecretsFrame.currentPage > 1 then
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			UpdatePage(SecretsFrame.currentPage - 1)
		end
	else
		-- Scroll down - go to next page
		if SecretsFrame.currentPage < maxPages then
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			UpdatePage(SecretsFrame.currentPage + 1)
		end
	end
end)

-- Create progress bar (matching ManuscriptsJournal/PaperDoll style, with ElvUI support)
local progressBar = CreateFrame("StatusBar", nil, SecretsFrame)
progressBar:SetSize(200, 15)
progressBar:SetPoint("TOP", SecretsFrame, "TOP", 0, -34)
progressBar:SetFrameLevel(100)
progressBar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
progressBar:SetStatusBarColor(0.03125, 0.85, 0.0) -- Bright green
progressBar:SetMinMaxValues(0, 100)
progressBar:SetValue(0)

-- Background (black texture behind the bar)
local progressBarBG = progressBar:CreateTexture(nil, "BACKGROUND")
progressBarBG:SetPoint("TOPLEFT", progressBar, "TOPLEFT", 0, -1)
progressBarBG:SetPoint("BOTTOMRIGHT", progressBar, "BOTTOMRIGHT", 0, 1)
progressBarBG:SetColorTexture(0.0, 0.0, 0.0, 1.0)

-- Border texture (PaperDoll skills bar border)
local progressBarBorder = progressBar:CreateTexture(nil, "OVERLAY")
progressBarBorder:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
progressBarBorder:SetSize(215, 30)
progressBarBorder:SetPoint("LEFT", progressBar, "LEFT", -12, 0)

-- Progress text overlay on the bar
local progressText = progressBar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 1)
progressText:SetText("0/0")
SecretsFrame.progressBar = progressBar
SecretsFrame.progressText = progressText

-- Apply ElvUI styling if ElvUI is loaded
if C_AddOns.IsAddOnLoaded("ElvUI") then
	local E = unpack(_G.ElvUI)
	if E and E.private and E.private.skins and E.private.skins.blizzard and E.private.skins.blizzard.enable then
		local S = E:GetModule("Skins")
		if S and S.HandleStatusBar then
			S:HandleStatusBar(progressBar)
			-- ElvUI removes the border texture when skinning, so hide ours
			progressBarBorder:Hide()
			progressBarBG:Hide()
		end
	end
end

-- Create paging frame manually (matching MDungeonTeleports)
SecretsFrame.PagingFrame = CreateFrame("Frame", nil, SecretsFrame)
SecretsFrame.PagingFrame:SetSize(200, 30)
SecretsFrame.PagingFrame:SetPoint("BOTTOM", 21, 43)
SecretsFrame.PagingFrame:EnableMouse(false)

-- Page text
SecretsFrame.PagingFrame.PageText = SecretsFrame.PagingFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
SecretsFrame.PagingFrame.PageText:SetPoint("LEFT", 5, 0)
local fontPath, _, fontFlags = SecretsFrame.PagingFrame.PageText:GetFont()
SecretsFrame.PagingFrame.PageText:SetFont(fontPath, 12, fontFlags)

-- Previous page button
SecretsFrame.PagingFrame.PrevPageButton = CreateFrame("Button", nil, SecretsFrame.PagingFrame)
SecretsFrame.PagingFrame.PrevPageButton:SetSize(32, 32)
SecretsFrame.PagingFrame.PrevPageButton:SetPoint("LEFT", SecretsFrame.PagingFrame.PageText, "RIGHT", 5, 0)
SecretsFrame.PagingFrame.PrevPageButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
SecretsFrame.PagingFrame.PrevPageButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
SecretsFrame.PagingFrame.PrevPageButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
SecretsFrame.PagingFrame.PrevPageButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
SecretsFrame.PagingFrame.PrevPageButton:SetScript("OnClick", function()
	if SecretsFrame.currentPage > 1 then
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		UpdatePage(SecretsFrame.currentPage - 1)
	end
end)

-- Next page button
SecretsFrame.PagingFrame.NextPageButton = CreateFrame("Button", nil, SecretsFrame.PagingFrame)
SecretsFrame.PagingFrame.NextPageButton:SetSize(32, 32)
SecretsFrame.PagingFrame.NextPageButton:SetPoint("LEFT", SecretsFrame.PagingFrame.PrevPageButton, "RIGHT", 5, 0)
SecretsFrame.PagingFrame.NextPageButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
SecretsFrame.PagingFrame.NextPageButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
SecretsFrame.PagingFrame.NextPageButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
SecretsFrame.PagingFrame.NextPageButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
SecretsFrame.PagingFrame.NextPageButton:SetScript("OnClick", function()
	local maxPages = CalculateTotalPages()
	if SecretsFrame.currentPage < maxPages then
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		UpdatePage(SecretsFrame.currentPage + 1)
	end
end)

-- Helper functions for paging frame
SecretsFrame.PagingFrame.SetMaxPages = function(self, maxPages)
	self.maxPages = maxPages
	self:UpdateButtons()
end

SecretsFrame.PagingFrame.SetCurrentPage = function(self, page)
	-- Calculate progress (excluding linkedSecret entries)
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
	progressText:SetText(string.format("%d/%d", collected, trackable))
	if trackable > 0 then
		SecretsFrame.progressBar:SetMinMaxValues(0, trackable)
		SecretsFrame.progressBar:SetValue(collected)
	else
		SecretsFrame.progressBar:SetMinMaxValues(0, 1)
		SecretsFrame.progressBar:SetValue(0)
	end
	
	self.PageText:SetText("Page " .. page .. " / " .. (self.maxPages or 1))
	self:UpdateButtons()
end

SecretsFrame.PagingFrame.UpdateButtons = function(self)
	self.PrevPageButton:SetEnabled(SecretsFrame.currentPage > 1)
	self.NextPageButton:SetEnabled(SecretsFrame.currentPage < (self.maxPages or 1))
end

SecretsFrame.PagingFrame.maxPages = 1

-- ==============================================
-- TAB REGISTRATION
-- ==============================================

-- Store tab reference
local secretsTab = nil
local originalPortraitTexture = nil
local originalTitleText = nil

local function EnsureSecretsTab()
	if secretsTab then
		return true
	end

	if not CollectionsJournal then
		return false
	end

	if not LibStub then
		return false
	end

	local secureTabs = LibStub("SecureTabs-2.0", true)
	if not secureTabs then
		return false
	end

	-- Build data and setup pages
	local totalPages = CalculateTotalPages()
	SecretsFrame.PagingFrame:SetMaxPages(math.max(totalPages, 1))

	-- Register the tab with SecureTabs (no SecureActionButtonTemplate needed!)
	secretsTab = secureTabs:Add(CollectionsJournal, SecretsFrame, "Secrets")

	secretsTab.OnSelect = function()
		-- Load collections addon if not already loaded
		C_AddOns.LoadAddOn("Blizzard_Collections")
		
		-- When the tab is selected, show our custom frame
		if SecretsFrame then
			SecretsFrame:Show()
		end
	end

	-- Hook into SecretsFrame show to update content and UI
	SecretsFrame:HookScript("OnShow", function()
		-- Hide all other collection frames IMMEDIATELY to prevent race conditions
		HideBlizzardCollectionFrames()
		
		-- Hide the underlying covered tab's text to prevent double text
		if CollectionsJournal.selectedTab then
			local coveredTab = _G["CollectionsJournalTab" .. CollectionsJournal.selectedTab]
			if coveredTab then
				local textFS = coveredTab.Text or coveredTab:GetFontString()
				if textFS then
					textFS:SetAlpha(0)
				end
			end
		end
		
		-- Update the display to ensure content is loaded
		UpdatePage(SecretsFrame.currentPage)
		
		-- Store the original values on first selection
		if not originalPortraitTexture and CollectionsJournalPortrait then
			originalPortraitTexture = CollectionsJournalPortrait:GetTexture()
		end
		if not originalTitleText and CollectionsJournalTitleText then
			originalTitleText = CollectionsJournalTitleText:GetText()
		end
		
		-- Change the portrait icon
		if CollectionsJournalPortrait then
			CollectionsJournalPortrait:SetTexture(454046)
		end
		
		-- Change the title text
		if CollectionsJournalTitleText then
			CollectionsJournalTitleText:SetText("Secrets Checklist")
		end
	end)
	
	-- Hook into SecretsFrame hide to restore original UI
	SecretsFrame:HookScript("OnHide", function()
		-- Restore the original portrait
		if CollectionsJournalPortrait and originalPortraitTexture then
			CollectionsJournalPortrait:SetTexture(originalPortraitTexture)
		end
		
		-- Restore the original title
		if CollectionsJournalTitleText and originalTitleText then
			CollectionsJournalTitleText:SetText(originalTitleText)
		end
		
		-- Restore the covered tab's text alpha
		if CollectionsJournal.selectedTab then
			local coveredTab = _G["CollectionsJournalTab" .. CollectionsJournal.selectedTab]
			if coveredTab then
				local textFS = coveredTab.Text or coveredTab:GetFontString()
				if textFS then
					textFS:SetAlpha(1)
				end
			end
		end
		
		-- Deferred check to hide Blizzard frames after tab switch completes
		-- This prevents Blizzard's tab code from showing HeirloomsJournal when we're covering that tab
		-- Using RunNextFrame is more efficient than C_Timer for immediate next-frame execution
		RunNextFrame(function()
			-- Only hide if another custom tab is now showing
			if not SecretsFrame:IsShown() and CollectionsJournal:IsShown() then
				-- Check if TeleportsFrame or ManuscriptsJournal is showing
				local customTabShowing = false
				local TeleportsFrame = _G.TeleportsFrame
				local ManuscriptsSideTabsFrame = _G.ManuscriptsSideTabsFrame
				
				if TeleportsFrame and TeleportsFrame:IsShown() then
					customTabShowing = true
				end
				if ManuscriptsSideTabsFrame and ManuscriptsSideTabsFrame:IsShown() then
					customTabShowing = true
				end
				
				-- If a custom tab is showing, hide all Blizzard frames
				if customTabShowing then
					HideBlizzardCollectionFrames()
				end
			end
		end)
	end)

	-- Hook CollectionsJournal OnShow to handle reopening with Secrets tab selected
	CollectionsJournal:HookScript("OnShow", function()
		-- If SecretsFrame is visible, ensure other frames are hidden
		if SecretsFrame and SecretsFrame:IsShown() then
			HideBlizzardCollectionFrames()
		end
	end)

	return true
end

-- ==============================================
-- OPENING FUNCTION
-- ==============================================

function SC:OpenCollectionsSecretsTab()
	-- Load Collections addon if not loaded
	if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
		C_AddOns.LoadAddOn("Blizzard_Collections")
	end

	-- Ensure tab is created
	if not EnsureSecretsTab() then
		Print("Could not attach Secrets tab. Please open Collections Journal manually first.")
		return false
	end

	-- Show Collections Journal
	if not CollectionsJournal:IsShown() then
		ShowUIPanel(CollectionsJournal)
	end

	-- Select our tab if it exists
	if secretsTab and secretsTab.Click then
		secretsTab:Click()
		return true
	end

	return false
end

-- ==============================================
-- INITIALIZATION
-- ==============================================

-- When Blizzard_Collections becomes available, create the tab
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
	if name == "Blizzard_Collections" then
		EnsureSecretsTab()
		f:UnregisterEvent("ADDON_LOADED")
	end
end)

-- If Collections is already loaded, initialize immediately
if C_AddOns.IsAddOnLoaded("Blizzard_Collections") and CollectionsJournal then
	EnsureSecretsTab()
end
