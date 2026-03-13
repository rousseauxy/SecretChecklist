-- =================================================================
-- SecretChecklist/tabs/TabOverview.lua
-- Builds the Overview tab panel (secret button grid + paging).
--
-- SC:BuildOverviewPanel(frame, L) is called first in Initialize()
-- inside SecretChecklistFrame.lua.
--
-- Shared state access:
--   SC:GetFilteredEntries()    -- filter logic lives in Frame.lua
--   SC.currentTab              -- checked before doing overview work
--
-- Exposes:
--   SC.updateOverviewPage(newPage)  -- used by SwitchTab and OnFilterChanged
-- =================================================================

local SC = _G.SecretChecklist
if not SC then return end

local math_min, math_max, math_ceil = math.min, math.max, math.ceil
local select        = select
local string_format = string.format

function SC:BuildOverviewPanel(frame, L)

	-- ==============================================
	-- LAYOUT CONSTANTS
	-- ==============================================

	local BUTTON_WIDTH     = 208
	local BUTTON_HEIGHT    = 50
	local BUTTONS_PER_ROW  = 3
	local BUTTONS_PER_PAGE = 21
	local START_OFFSET_X   = 38
	local START_OFFSET_Y   = -40
	local BUTTON_PADDING_X = 0
	local BUTTON_PADDING_Y = 16

	-- ==============================================
	-- STATE
	-- ==============================================

	frame.buttonPool  = {}
	frame.currentPage = 1

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

		-- Helper for safe tooltip calls
		local function TryTooltip(fn)
			return pcall(fn) == true
		end

		-- Tooltip handler
		button:SetScript("OnEnter", function(self)
			if not self.entry then return end
			local entry = self.entry

			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOMLEFT", self.slotFrameCollected, "TOPRIGHT", -2, -2)

			local success = false
			if entry.kind == "toy" and entry.itemID then
				success = TryTooltip(function() GameTooltip:SetToyByItemID(entry.itemID) end)
			elseif entry.kind == "mount" then
				if entry.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
					local _, spellID = C_MountJournal.GetMountInfoByID(entry.mountID)
					if spellID then success = TryTooltip(function() GameTooltip:SetMountBySpellID(spellID) end) end
				end
				if not success and entry.spellID then
					success = TryTooltip(function() GameTooltip:SetMountBySpellID(entry.spellID) end)
				end
				if not success and entry.itemID then
					success = TryTooltip(function() GameTooltip:SetItemByID(entry.itemID) end)
				end
				if success and C_MountJournal then
					local mountID = entry.mountID
					if not mountID and entry.itemID and C_MountJournal.GetMountFromItem then
						mountID = C_MountJournal.GetMountFromItem(entry.itemID)
					end
					if mountID then
						local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
						if C_MountJournal.GetMountInfoExtraByID then
							local _, description, source = C_MountJournal.GetMountInfoExtraByID(mountID)
							if source and source ~= "" then
								GameTooltip:AddLine(source, 1, 0.82, 0, true)
							end
							if description and description ~= "" then
								GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
							end
						end
						if isCollected ~= nil then
							local collected = isCollected == true
							GameTooltip:AddLine(
								collected and (L["TOOLTIP_COLLECTED"] or "Collected") or (L["TOOLTIP_NOT_COLLECTED"] or "Not collected"),
								collected and 0 or 1, collected and 1 or 0, 0
							)
						end
					end
				end
			elseif entry.kind == "pet" then
				if entry.itemID then
					success = TryTooltip(function() GameTooltip:SetItemByID(entry.itemID) end)
				end
				if success and entry.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
					local _, _, _, _, sourceText, description = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
					if sourceText and sourceText ~= "" then
						GameTooltip:AddLine(sourceText, 1, 0.82, 0, true)
					end
					if description and description ~= "" then
						GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
					end
					local numOwned = C_PetJournal.GetNumCollectedInfo and select(1, C_PetJournal.GetNumCollectedInfo(entry.speciesID))
					local collected = numOwned and numOwned > 0
					GameTooltip:AddLine(
						collected and (L["TOOLTIP_COLLECTED"] or "Collected") or (L["TOOLTIP_NOT_COLLECTED"] or "Not collected"),
						collected and 0 or 1, collected and 1 or 0, 0
					)
				end
				if not success and entry.speciesID and C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
					local speciesName, _, _, _, sourceText, description = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
					if speciesName then
						local rareColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[3] or { r = 0, g = 0.44, b = 0.87 }
						GameTooltip:SetText(speciesName, rareColor.r, rareColor.g, rareColor.b)
						if sourceText and sourceText ~= "" then
							GameTooltip:AddLine(sourceText, 1, 0.82, 0, true)
						end
						if description and description ~= "" then
							GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
						end
						local numOwned = C_PetJournal.GetNumCollectedInfo and select(1, C_PetJournal.GetNumCollectedInfo(entry.speciesID))
						local collected = numOwned and numOwned > 0
						GameTooltip:AddLine(
							collected and (L["TOOLTIP_COLLECTED"] or "Collected") or (L["TOOLTIP_NOT_COLLECTED"] or "Not collected"),
							collected and 0 or 1, collected and 1 or 0, 0
						)
						success = true
					end
				end
			elseif entry.kind == "achievement" and entry.achievementID then
				success = TryTooltip(function() GameTooltip:SetHyperlink("achievement:" .. entry.achievementID) end)
			elseif entry.kind == "transmog" and entry.itemID then
				success = TryTooltip(function() GameTooltip:SetItemByID(entry.itemID) end)
			elseif entry.kind == "housing" and entry.itemID then
				success = TryTooltip(function() GameTooltip:SetItemByID(entry.itemID) end)
				if success and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
					local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, true)
					if info then
						local owned = (info.quantity or 0) + (info.numPlaced or 0) + (info.remainingRedeemable or 0) > 0
						GameTooltip:AddLine(
							owned and (L["TOOLTIP_COLLECTED"] or "Collected") or (L["TOOLTIP_NOT_COLLECTED"] or "Not collected"),
							owned and 0 or 1, owned and 1 or 0, 0
						)
					end
				end
			elseif entry.kind == "quest" and entry.questID then
				local entryName = SC.GetEntryName and SC:GetEntryName(entry) or (entry.name or L["UNKNOWN"] or "(unknown)")
				GameTooltip:SetText(entryName, 1, 1, 1)
				if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
					local completed = C_QuestLog.IsQuestFlaggedCompleted(entry.questID)
					local statusText = completed and (L["TOOLTIP_COMPLETED"] or "Completed") or (L["TOOLTIP_NOT_COMPLETED"] or "Not completed")
					GameTooltip:AddLine(statusText, completed and 0 or 1, completed and 1 or 0, 0)
				end
				success = true
			end

			if not success then
				local entryName = SC.GetEntryName and SC:GetEntryName(entry) or (entry.name or L["UNKNOWN"] or "(unknown)")
				GameTooltip:SetText(entryName, 1, 1, 1)
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

	local function GetButton(index)
		if not frame.buttonPool[index] then
			frame.buttonPool[index] = CreateSecretButton(frame, index)
		end
		return frame.buttonPool[index]
	end

	-- ==============================================
	-- LAYOUT
	-- ==============================================

	local function LayoutCurrentPage()
		if SC.currentTab ~= "overview" then return end
		local entries = SC:GetFilteredEntries()

		local startIndex = (frame.currentPage - 1) * BUTTONS_PER_PAGE + 1
		local endIndex   = math_min(startIndex + BUTTONS_PER_PAGE - 1, #entries)

		for _, button in pairs(frame.buttonPool) do button:Hide() end

		local buttonIndex = 1
		local row, col    = 0, 0

		for i = startIndex, endIndex do
			local entry  = entries[i]
			local button = GetButton(buttonIndex)

			button.entry = entry
			local icon = SC.GetEntryIcon and SC:GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark"
			button.iconTexture:SetTexture(icon)
			button.iconTextureUncollected:SetTexture(icon)
			local entryName = SC.GetEntryName and SC:GetEntryName(entry) or (entry.name or L["UNKNOWN"] or "(unknown)")
			button.name:SetText(entryName)

			local status      = SC.GetEntryStatus and SC:GetEntryStatus(entry) or "unknown"
			local isCollected = status == "collected"
			local isMissing   = status == "missing"

			button.iconTexture:SetShown(isCollected)
			button.iconTextureUncollected:SetShown(not isCollected)
			button.slotFrameCollected:SetShown(isCollected)
			button.slotFrameUncollected:SetShown(not isCollected)
			button.slotFrameUncollectedInnerGlow:SetShown(isMissing)

			if isCollected then
				button.name:SetTextColor(1, 0.82, 0, 1)
				button.name:SetShadowColor(0, 0, 0, 1)
			elseif isMissing then
				button.name:SetTextColor(0.33, 0.27, 0.20, 1)
				button.name:SetShadowColor(0, 0, 0, 0.33)
			else
				button.name:SetTextColor(1.0, 0.82, 0.0, 1)
				button.name:SetShadowColor(0, 0, 0, 1)
			end

			local x = START_OFFSET_X + col * (BUTTON_WIDTH + BUTTON_PADDING_X)
			local y = START_OFFSET_Y - row * (BUTTON_HEIGHT + BUTTON_PADDING_Y)
			button:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", x, y)
			button:Show()

			buttonIndex = buttonIndex + 1
			col = col + 1
			if col >= BUTTONS_PER_ROW then
				row = row + 1
				col = 0
			end
		end
	end

	-- ==============================================
	-- PAGING
	-- ==============================================

	local function CalculateTotalPages()
		return math_ceil(#(SC:GetFilteredEntries()) / BUTTONS_PER_PAGE)
	end

	local function UpdateProgressBar()
		local totalAll, collectedAll = 0, 0
		local totalMS,  collectedMS  = 0, 0
		for _, entry in ipairs(SC.entries or {}) do
			if entry.kind ~= "manual" then
				totalAll = totalAll + 1
				local have = SC.CheckEntry and SC:CheckEntry(entry)
				if have == true then collectedAll = collectedAll + 1 end
			end
			if entry.mindSeeker then
				totalMS = totalMS + 1
				local have = SC.CheckEntry and SC:CheckEntry(entry)
				if have == true then collectedMS = collectedMS + 1 end
			end
		end
		frame.ProgressBar.TotalText:SetText(
			string_format("|cffffffff%d|r / %d %s", collectedAll, totalAll, L["SECRETS"] or "Secrets"))
		frame.ProgressBar.MindSeekerText:SetText(
			string_format("%s: |cffffffff%d|r / %d", L["MIND_SEEKER"] or "Mind-Seeker", collectedMS, totalMS))
	end

	local function UpdatePage(newPage)
		frame.currentPage = newPage
		SC:RefreshCaches()
		LayoutCurrentPage()
		UpdateProgressBar()
		local maxPages = CalculateTotalPages()
		frame.PagingFrame.PageText:SetText(string_format(L["PAGE_FORMAT"] or "Page %d / %d", frame.currentPage, maxPages))
		frame.PagingFrame.PrevPageButton:SetEnabled(frame.currentPage > 1)
		frame.PagingFrame.NextPageButton:SetEnabled(frame.currentPage < maxPages)
	end

	-- Mouse wheel scrolling through pages (only active on overview tab)
	frame:SetScript("OnMouseWheel", function(self, delta)
		if SC.currentTab ~= "overview" then return end
		local maxPages = CalculateTotalPages()
		if delta > 0 then
			if frame.currentPage > 1 then
				PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
				UpdatePage(frame.currentPage - 1)
			end
		else
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

	-- Expose UpdatePage for SwitchTab and OnFilterChanged in Frame.lua
	SC.updateOverviewPage = UpdatePage

end  -- SC:BuildOverviewPanel
