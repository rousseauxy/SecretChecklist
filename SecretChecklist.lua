local addonName = ...

-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local SC = {}
_G.SecretChecklist = SC

SecretChecklistDB = SecretChecklistDB or {}

-- Entries are now defined in data/SecretEntries.lua

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

function SC:GetEntryIcon(entry)
	if type(entry) ~= "table" then
		return FALLBACK_ICON
	end
	
	-- For mounts with mountID specified (e.g., Fathom Dweller)
	if type(entry.mountID) == "number" then
		if C_MountJournal and C_MountJournal.GetMountInfoByID then
			local _, _, icon = C_MountJournal.GetMountInfoByID(entry.mountID)
			if icon then
				return icon
			end
		end
	end
	
	-- For pets with speciesID (e.g., Jenafur)
	if type(entry.speciesID) == "number" then
		if C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
			local _, icon = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
			if icon then
				return icon
			end
		end
	end
	
	if type(entry.itemID) == "number" then
		if C_Item and C_Item.GetItemIconByID then
			local icon = C_Item.GetItemIconByID(entry.itemID)
			if icon then
				return icon
			end
		end
	end
	
	if type(entry.achievementID) == "number" then
		local _, _, _, _, _, _, _, _, _, icon = GetAchievementInfo(entry.achievementID)
		if icon then
			return icon
		end
	end
	-- Custom icon specified directly
	if type(entry.icon) == "number" or type(entry.icon) == "string" then
		return entry.icon
	end
	return FALLBACK_ICON
end

function SC:GetEntryName(entry)
	if type(entry) ~= "table" then
		return "Unknown"
	end
	
	-- Try to get localized name from game APIs
	if entry.kind == "mount" and type(entry.mountID) == "number" then
		if C_MountJournal and C_MountJournal.GetMountInfoByID then
			local name = C_MountJournal.GetMountInfoByID(entry.mountID)
			if name and name ~= "" then
				return name
			end
		end
	end
	
	if entry.kind == "pet" and type(entry.speciesID) == "number" then
		if C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID then
			local name = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
			if name and name ~= "" then
				return name
			end
		end
	end
	
	if (entry.kind == "toy" or entry.kind == "transmog" or entry.kind == "housing") and type(entry.itemID) == "number" then
		if C_Item and C_Item.GetItemInfo then
			local name = C_Item.GetItemInfo(entry.itemID)
			if name and name ~= "" then
				return name
			end
		end
	end
	
	if entry.kind == "achievement" and type(entry.achievementID) == "number" then
		local _, name = GetAchievementInfo(entry.achievementID)
		if name and name ~= "" then
			return name
		end
	end
	
	if entry.kind == "quest" and type(entry.questID) == "number" then
		if C_QuestLog and C_QuestLog.GetQuestInfo then
			local questInfo = C_QuestLog.GetQuestInfo(entry.questID)
			if questInfo and questInfo.title and questInfo.title ~= "" then
				return questInfo.title
			end
		end
	end
	
	-- Fall back to hardcoded name in data file
	if type(entry.name) == "string" and entry.name ~= "" then
		return entry.name
	end
	
	return "Unknown"
end

function SC:RefreshCaches()
	self:EnsureCollectionsLoaded()
end

function SC:GetEntryStatus(entry)
	-- Returns: "collected" | "missing" | "unknown" | "manual", plus optional detail
	if type(entry) ~= "table" then
		return "unknown", "Invalid entry"
	end
	if entry.kind == "manual" then
		return "manual", entry.note
	end
	local have, detail = self:CheckEntry(entry)
	if have == true then
		return "collected", detail
	end
	if have == false then
		return "missing", detail
	end
	return "unknown", detail
end

function SC:EnsureCollectionsLoaded()
	-- Rely on collection APIs directly (some clients don't ship Blizzard_Collections as a loadable addon).
	local apis = {
		{C_ToyBox, "ForceToyRefilter"},
		{C_MountJournal, "SetDefaultFilters"},
		{C_PetJournal, "SetDefaultFilters"}
	}
	for _, api in ipairs(apis) do
		if api[1] and api[1][api[2]] then
			pcall(api[1][api[2]])
		end
	end
end

function SC:CheckEntry(entry)
	if entry.kind == "toy" then
		if type(entry.itemID) ~= "number" then
			return nil, "Toy missing itemID."
		end
		local hasToy = PlayerHasToy(entry.itemID)
		if hasToy == true then
			return true, "toy"
		elseif hasToy == false then
			return false, "toy"
		end
		-- If PlayerHasToy returns nil, toy data might not be loaded yet
		if C_ToyBox and C_ToyBox.GetToyInfo then
			local toyName = C_ToyBox.GetToyInfo(entry.itemID)
			if toyName == nil then
				return nil, "ToyBox data not loaded/cached yet. Open Collections → Toys once (then rerun)."
			end
		end
		return false, "toy"
	end

	if entry.kind == "mount" then
		if not C_MountJournal or not C_MountJournal.GetMountInfoByID then
			return nil, "MountJournal API unavailable (try after fully logged in)."
		end

		-- Check if mount specified by mountID (e.g., Fathom Dweller)
		if type(entry.mountID) == "number" then
			local isCollected = select(11, C_MountJournal.GetMountInfoByID(entry.mountID))
			if isCollected == nil then
				return nil, "Mount journal data not ready yet. Try /secrets wait or open Collections → Mounts once."
			end
			return isCollected == true, "mount"
		end

		local mountID
		if type(entry.itemID) == "number" and C_MountJournal.GetMountFromItem then
			mountID = C_MountJournal.GetMountFromItem(entry.itemID)
		end
		if type(mountID) == "number" then
			local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
			if isCollected == nil then
				return nil, "Mount journal data not ready yet. Try /secrets wait or open Collections → Mounts once."
			end
			return isCollected == true, "mount"
		end

		return nil, "Could not map to a mount yet (no mountID or itemID matched)."
	end

	if entry.kind == "pet" then
		if not C_PetJournal then
			return nil, "PetJournal API unavailable (try after fully logged in)."
		end

		if type(entry.speciesID) ~= "number" then
			return nil, "Pet missing speciesID."
		end
		if not C_PetJournal.GetNumCollectedInfo then
			return nil, "PetJournal API unavailable."
		end
		local numOwned = select(1, C_PetJournal.GetNumCollectedInfo(entry.speciesID))
		if numOwned == nil then
			return nil, "Pet journal data not ready yet. Open Collections → Pets once."
		end
		return numOwned > 0, "pet"
	end

	if entry.kind == "achievement" then
		local _, _, _, completed = GetAchievementInfo(entry.achievementID)
		return completed == true, "achievement"
	end

	if entry.kind == "quest" then
		if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
			return C_QuestLog.IsQuestFlaggedCompleted(entry.questID) == true, "quest"
		end
		return nil, "Quest API unavailable."
	end

	if entry.kind == "transmog" then
		if not C_TransmogCollection then
			return nil, "TransmogCollection API unavailable."
		end
		if type(entry.itemID) ~= "number" then
			return nil, "Transmog missing itemID."
		end
		-- Check if player knows this appearance
		if C_TransmogCollection.PlayerHasTransmog then
			local hasTransmog = C_TransmogCollection.PlayerHasTransmog(entry.itemID)
			if hasTransmog ~= nil then
				return hasTransmog == true, "transmog"
			end
		end
		-- Fallback: use GetItemInfo
		local _, _, _, _, isCollected = C_TransmogCollection.GetItemInfo(entry.itemID)
		if isCollected ~= nil then
			return isCollected == true, "transmog"
		end
		return nil, "Transmog data not loaded yet. Open Collections → Appearances once."
	end

	if entry.kind == "housing" then
		if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByItem then
			return nil, "HousingCatalog API unavailable."
		end
		if type(entry.itemID) ~= "number" then
			return nil, "Housing entry missing itemID."
		end
		local info = C_HousingCatalog.GetCatalogEntryInfoByItem(entry.itemID, true)
		if not info then
			return nil, "Housing catalog data not loaded yet."
		end
		local owned = (info.quantity or 0) + (info.numPlaced or 0) + (info.remainingRedeemable or 0) > 0
		return owned, "housing"
	end

	if entry.kind == "mystery" then
		return nil, "Reward unknown – in active investigation"
	end

	if entry.kind == "manual" then
		return nil, entry.note or "Manual check"
	end

	return nil, "Unknown kind"
end

-- Returns the status of a single progress step:
--   "done"    – quest flagged completed
--   "ready"   – quest not done, but item(s) are in bags/bank
--   "missing" – quest not done and item(s) not found
function SC:GetStepStatus(step)
	if step.questID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
		if C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
			return "done"
		end
	end
	if step.itemID then
		local have = GetItemCount(step.itemID, true)  -- true = include bank
		if have >= (step.count or 1) then return "ready" end
	end
	return "missing"
end

SLASH_SECRETCHECKLIST1 = "/secrets"
SLASH_SECRETCHECKLIST2 = "/secretchecklist"
SlashCmdList.SECRETCHECKLIST = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

	if msg == "options" or msg == "settings" then
		if SC.OpenOptionsPanel then
			SC:OpenOptionsPanel()
		end
		return
	end
	
	if msg == "minimap" then
		if SC.ToggleMinimapButton then
			SC:ToggleMinimapButton()
		end
	elseif msg == "alert" then
		-- Fire a test toast with the first entry in the list (dev/debug helper)
		local testEntry = SC.entries and SC.entries[1]
		if testEntry and SC.FireSecretAlert then
			SC:FireSecretAlert(testEntry)
		else
			print("|cffffcc00SecretChecklist:|r Alert system not ready yet.")
		end
	else
		-- Default: open UI
		if SC.OpenCollectionsSecretsTab then
			SC:OpenCollectionsSecretsTab()
		end
	end
end
