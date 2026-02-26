local addonName = ...

-- Localize frequently-used globals for performance
local type, select, next, pairs, ipairs = type, select, next, pairs, ipairs
local tostring, tonumber = tostring, tonumber
local math_min = math.min

local SC = {}
_G.SecretChecklist = SC

SecretChecklistDB = SecretChecklistDB or {}

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff66c0ffSecretChecklist|r: " .. tostring(msg))
end

-- Entries are now defined in data/SecretEntries.lua

-- ==============================================
-- HELPER FUNCTIONS
-- ==============================================

local function IsSpellKnownSafe(spellID)
	if type(spellID) ~= "number" then
		return false
	end
	if IsSpellKnown and IsSpellKnown(spellID) then
		return true
	end
	if IsPlayerSpell and IsPlayerSpell(spellID) then
		return true
	end
	return false
end

local function ExtractFirstNumber(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "number" then
			return v
		end
	end
	return nil
end

local function NormalizeName(s)
	if type(s) ~= "string" then
		return ""
	end
	s = s:lower()
	s = s:gsub("’", "'")
	s = s:gsub("[%(%)]", " ")
	s = s:gsub("[^a-z0-9]+", "")
	return s
end

local function GetCandidateNames(entry)
	local candidates = {}
	if type(entry.matchNames) == "table" then
		for _, n in ipairs(entry.matchNames) do
			if type(n) == "string" and n ~= "" then
				candidates[#candidates + 1] = n
			end
		end
	end
	if type(entry.name) == "string" and entry.name ~= "" then
		candidates[#candidates + 1] = entry.name
	end
	return candidates
end

local function ResolvePetSpeciesIDFromItemID(itemID, entry)
	if not C_PetJournal or not C_PetJournal.GetPetInfoByItemID or not C_PetJournal.GetPetInfoBySpeciesID then
		return nil
	end
	if type(itemID) ~= "number" then
		return nil
	end

	local ret = { C_PetJournal.GetPetInfoByItemID(itemID) }
	if #ret == 0 then
		return nil
	end

	local wanted = {}
	for _, candidate in ipairs(GetCandidateNames(entry)) do
		wanted[NormalizeName(candidate)] = true
	end

	local bestSpeciesID = nil
	for _, v in ipairs(ret) do
		if type(v) == "number" then
			local petName = C_PetJournal.GetPetInfoBySpeciesID(v)
			if type(petName) == "string" and petName ~= "" then
				if next(wanted) == nil or wanted[NormalizeName(petName)] then
					return v
				end
				bestSpeciesID = bestSpeciesID or v
			end
		end
	end

	return bestSpeciesID
end

local function GetFallbackIcon()
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function SC:GetEntryIcon(entry)
	if type(entry) ~= "table" then
		return GetFallbackIcon()
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
		if GetItemInfoInstant then
			local _, _, _, _, icon = GetItemInfoInstant(entry.itemID)
			if icon then
				return icon
			end
		end
	end
	
	if type(entry.spellID) == "number" and GetSpellTexture then
		local icon = GetSpellTexture(entry.spellID)
		if icon then
			return icon
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
	return GetFallbackIcon()
end

function SC:RefreshCaches()
	self:EnsureCollectionsLoaded()
	self._mountCacheBuilt = false
	self._petCacheBuilt = false
	self._mountByNormName = nil
	self._mountBySpellID = nil
	self._petByNormName = nil
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
	-- We can still nudge the journals to refresh their data.
	if C_ToyBox and C_ToyBox.ForceToyRefilter then
		pcall(C_ToyBox.ForceToyRefilter)
	end
	if C_MountJournal and C_MountJournal.SetDefaultFilters then
		pcall(C_MountJournal.SetDefaultFilters)
	end
	if C_PetJournal and C_PetJournal.SetDefaultFilters then
		pcall(C_PetJournal.SetDefaultFilters)
	end
end

function SC:BuildMountCache()
	if self._mountCacheBuilt then
		return
	end
	self._mountCacheBuilt = true
	self._mountByNormName = {}
	self._mountBySpellID = {}

	if not C_MountJournal or not C_MountJournal.GetMountIDs or not C_MountJournal.GetMountInfoByID then
		return
	end

	local mountIDs = C_MountJournal.GetMountIDs()
	if type(mountIDs) ~= "table" then
		return
	end
	if #mountIDs == 0 then
		return
	end

	for _, mountID in ipairs(mountIDs) do
		local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
		-- If collection data isn't ready yet, isCollected can be nil. Don't cache "false" in that case.
		if isCollected ~= nil then
			if type(name) == "string" then
				self._mountByNormName[NormalizeName(name)] = { mountID = mountID, collected = isCollected == true }
			end
			if type(spellID) == "number" then
				self._mountBySpellID[spellID] = { mountID = mountID, collected = isCollected == true }
			end
		end
	end
end

function SC:BuildPetCache()
	if self._petCacheBuilt then
		return
	end
	self._petCacheBuilt = true
	self._petByNormName = {}

	if not C_PetJournal or not C_PetJournal.GetNumPets or not C_PetJournal.GetPetInfoByIndex then
		return
	end

	local _, total = C_PetJournal.GetNumPets(false)
	if type(total) ~= "number" then
		return
	end
	if total == 0 then
		return
	end

	for i = 1, total do
		local _, speciesID = C_PetJournal.GetPetInfoByIndex(i)
		if type(speciesID) == "number" then
			local petName = nil
			if C_PetJournal.GetPetInfoBySpeciesID then
				petName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
			end
			if type(petName) == "string" then
				local numOwned = 0
				if C_PetJournal.GetNumCollectedInfo then
					local owned = select(1, C_PetJournal.GetNumCollectedInfo(speciesID))
					if owned == nil then
						-- Journal not ready; skip caching so we don't incorrectly mark as missing.
						numOwned = nil
					else
						numOwned = owned
					end
				end
				if numOwned ~= nil then
					self._petByNormName[NormalizeName(petName)] = { speciesID = speciesID, owned = numOwned }
				end
			end
		end
	end
end

function SC:IsCollectionDataReady()
	local toyReady = true
	local mountReady = true
	local petReady = true

	-- Toys: GetToyInfo returns nil when ToyBox hasn't populated yet.
	if C_ToyBox and C_ToyBox.GetToyInfo then
		for _, e in ipairs(self.entries) do
			if e.kind == "toy" and type(e.itemID) == "number" then
				local name = C_ToyBox.GetToyInfo(e.itemID)
				if name == nil then
					toyReady = false
				end
				break
			end
		end
	end

	-- Mounts: mountIDs can be empty until journal initializes.
	if C_MountJournal and C_MountJournal.GetMountIDs then
		local ids = C_MountJournal.GetMountIDs()
		if type(ids) ~= "table" or #ids == 0 then
			mountReady = false
		end
	else
		mountReady = false
	end

	-- Pets: total can be 0 until journal initializes.
	if C_PetJournal and C_PetJournal.GetNumPets then
		local _, total = C_PetJournal.GetNumPets(false)
		if type(total) ~= "number" or total == 0 then
			petReady = false
		end
	else
		petReady = false
	end

	return toyReady, mountReady, petReady
end

function SC:CheckEntry(entry)
	if entry.kind == "toy" then
		if type(entry.itemID) ~= "number" then
			return nil, "Toy missing itemID."
		end
		if PlayerHasToy(entry.itemID) == true then
			return true, "toy"
		end
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

		self:BuildMountCache()

		-- Check if mount specified by mountID (e.g., Fathom Dweller)
		if type(entry.mountID) == "number" then
			local isCollected = select(11, C_MountJournal.GetMountInfoByID(entry.mountID))
			if isCollected == nil then
				return nil, "Mount journal data not ready yet. Try /secrets wait or open Collections → Mounts once."
			end
			return isCollected == true, "mount"
		end

		if type(entry.spellID) == "number" and self._mountBySpellID and self._mountBySpellID[entry.spellID] then
			return self._mountBySpellID[entry.spellID].collected == true, "mount"
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

		-- Fallback: match by name in the journal
		if self._mountByNormName then
			for _, candidate in ipairs(GetCandidateNames(entry)) do
				local norm = NormalizeName(candidate)
				if self._mountByNormName[norm] ~= nil then
					return self._mountByNormName[norm].collected == true, "mount"
				end
			end
		end
		return nil, "Could not map to a mount yet (name/item/spell mismatch or journal not cached)."
	end

	if entry.kind == "pet" then
		if not C_PetJournal then
			return nil, "PetJournal API unavailable (try after fully logged in)."
		end

		local speciesID
		-- Check if speciesID is directly provided
		if type(entry.speciesID) == "number" then
			speciesID = entry.speciesID
		elseif type(entry.itemID) == "number" and C_PetJournal.GetPetInfoByItemID then
			speciesID = ResolvePetSpeciesIDFromItemID(entry.itemID, entry)
		end
		if type(speciesID) == "number" and C_PetJournal.GetNumCollectedInfo then
			local numOwned = select(1, C_PetJournal.GetNumCollectedInfo(speciesID))
			if numOwned == nil then
				return nil, "Pet journal data not ready yet. Try /secrets wait or open Collections → Pets once."
			end
			return numOwned > 0, "pet"
		end

		-- Fallback: match by pet name
		self:BuildPetCache()
		if self._petByNormName then
			for _, candidate in ipairs(GetCandidateNames(entry)) do
				local norm = NormalizeName(candidate)
				if self._petByNormName[norm] ~= nil then
					return (self._petByNormName[norm].owned or 0) > 0, "pet"
				end
			end
		end

		return nil, "Could not map to a pet yet (name/item mismatch or journal not cached). Open Collections → Pets once."
	end

	if entry.kind == "achievement" then
		local _, _, _, completed = GetAchievementInfo(entry.achievementID)
		return completed == true, "achievement"
	end

	if entry.kind == "spell" then
		-- Spells in this list are mounts (e.g., Slime Serpent). Check via Mount Journal when possible.
		self:BuildMountCache()
		if type(entry.spellID) == "number" and self._mountBySpellID and self._mountBySpellID[entry.spellID] then
			return self._mountBySpellID[entry.spellID].collected == true, "mount"
		end
		return IsSpellKnownSafe(entry.spellID) == true, "spell"
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
		local categoryID, visualID, canEnchant, icon, isCollected = C_TransmogCollection.GetItemInfo(entry.itemID)
		if isCollected ~= nil then
			return isCollected == true, "transmog"
		end
		return nil, "Transmog data not loaded yet. Open Collections → Appearances once."
	end

	if entry.kind == "manual" then
		return nil, entry.note or "Manual check"
	end

	return nil, "Unknown kind"
end

function SC:Run()
	self:RefreshCaches()

	local totalEntries = #self.entries
	local trackableTotal = 0
	local collected = 0
	local missing = 0
	local unknown = 0
	local manual = 0
	local lines = {}

	local header = "Checking your secret list…"
	Print(header)
	lines[#lines + 1] = header

	for _, entry in ipairs(self.entries) do
		local have, detail = self:CheckEntry(entry)
		if entry.kind ~= "manual" and not entry.linkedSecret then
			trackableTotal = trackableTotal + 1
		end
		if have == true then
			if not entry.linkedSecret then
				collected = collected + 1
			end
			local line = "[X] " .. entry.name
			Print("[|cff00ff00X|r] " .. entry.name)
			lines[#lines + 1] = line
		elseif have == false then
			if not entry.linkedSecret then
				missing = missing + 1
			end
			local line = "[ ] " .. entry.name
			Print("[|cffff0000 |r] " .. entry.name)
			lines[#lines + 1] = line
			if self.verbose and detail then
				Print("    " .. detail)
				lines[#lines + 1] = "    " .. detail
			end
		else
			if entry.kind == "manual" then
				manual = manual + 1
			elseif not entry.linkedSecret then
				unknown = unknown + 1
			end
			local line = "[?] " .. entry.name
			Print("[|cffffff00?|r] " .. entry.name)
			lines[#lines + 1] = line
			if detail then
				Print("    " .. detail)
				lines[#lines + 1] = "    " .. detail
			end
		end
	end

	local summary = string.format(
		"Result: %d collected, %d missing, %d unknown (%d manual). Trackable: %d. Total entries: %d.",
		collected,
		missing,
		unknown,
		manual,
		trackableTotal,
		totalEntries
	)
	Print(summary)
	lines[#lines + 1] = summary

	SecretChecklistDB.lastReport = {
		timestamp = date("%Y-%m-%d %H:%M:%S"),
		totalEntries = totalEntries,
		trackableTotal = trackableTotal,
		collected = collected,
		missing = missing,
		unknown = unknown,
		manual = manual,
		verbose = self.verbose == true,
		lines = lines,
	}
end

SLASH_SECRETCHECKLIST1 = "/secrets"
SLASH_SECRETCHECKLIST2 = "/secretcheck"

SlashCmdList.SECRETCHECKLIST = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "where" then
		Print("Last report is saved to WTF/Account/<YourAccount>/SavedVariables/SecretChecklist.lua after you /logout or exit the game.")
		return
	end
	if msg == "ui" or msg == "journal" or msg == "" then
		if SC.OpenCollectionsSecretsTab then
			SC:OpenCollectionsSecretsTab()
			return
		end
		Print("Collections tab not available.")
		return
	end
	if msg == "scan" then
		SC:Run()
		return
	end
	if msg == "wait" then
		Print("Waiting for collection data, then running scan…")
		local function SafeRun()
			local ok, err = xpcall(function()
				SC:Run()
			end, function(e)
				return tostring(e) .. (debugstack and ("\n" .. debugstack(2, 5, 5)) or "")
			end)
			if not ok then
				Print("ERROR while running scan. See SavedVariables for details.")
				Print(err)
				SecretChecklistDB.lastError = {
					timestamp = date("%Y-%m-%d %H:%M:%S"),
					message = err,
				}
			end
		end
		local triesLeft = 6
		local function TryRun()
			triesLeft = triesLeft - 1
			SC:EnsureCollectionsLoaded()
			local toyReady, mountReady, petReady = SC:IsCollectionDataReady()
			if toyReady and mountReady and petReady then
				SafeRun()
				return
			end
			if triesLeft <= 0 then
				Print("Collection data still not fully ready; running anyway (some items may show [?]).")
				SafeRun()
				return
			end
			if C_Timer and C_Timer.After then
				C_Timer.After(1.0, TryRun)
			else
				SafeRun()
			end
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, TryRun)
		else
			TryRun()
		end
		return
	end
	if msg == "verbose" then
		SC.verbose = true
		Print("Verbose mode ON for this session. Run /secrets again.")
		return
	end
	if msg == "quiet" then
		SC.verbose = false
		Print("Verbose mode OFF for this session.")
		return
	end
	-- Unknown command, show help
	Print("Commands: /secrets (open Collections Journal tab), /secrets scan, /secrets wait, /secrets where, /secrets verbose, /secrets quiet")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	Print("Loaded. Type /secrets to open the Collections Journal tab, or /secrets wait to run a scan.")
end)
