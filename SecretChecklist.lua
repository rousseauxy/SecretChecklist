-- Localize frequently-used globals for performance
local type, pairs, ipairs = type, pairs, ipairs
local math_min = math.min
local select = select

local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local SC = {}
_G.SecretChecklist = SC

-- WoW: Forever is a separate client with its own AddOns folder, SavedVariables
-- and secrets. Internally it is called "Camelot": SecretChecklist_Camelot.toc
-- loads there and data/ForeverEntries.lua replaces data/SecretEntries.lua.
-- 18 is the project id other Forever addons fall back to on clients that do
-- not define the constant.
SC.IS_FOREVER = WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == (WOW_PROJECT_CAMELOT or 18)

-- ==============================================
-- SAVED VARIABLES
-- ==============================================

-- History:
--   1 -- never ran. dbVersion was listed in DB_DEFAULTS, so the defaults loop
--        stamped it to the current version *before* the migration gate read it,
--        and every existing profile looked already-migrated.
--   2 -- the retired-key prune, re-gated so profiles carrying that bogus
--        version-1 stamp are cleaned too.
--   3 -- prunes aboutUnlocked, whose only writer has now been removed. A key
--        added to RETIRED_KEYS is only pruned by a gate a profile has not yet
--        passed, so extending the list means bumping the version.
local DB_VERSION = 3

-- Every key the addon persists, with its default.
--
-- dbVersion is deliberately NOT here: it must be read before defaults are
-- applied, and is stamped once, after migrations have run.
local DB_DEFAULTS = {
	hideMinimapButton    = false,
	hideAddonCompartment = false,
	minimapAngle         = 225,
	alertsEnabled        = true,
	guidesStyle          = "sidetabs",
	debugMode            = false,
	-- framePos is deliberately absent: nil means "never moved", which is what
	-- tells Initialize to leave the XML's centred anchor alone.
	-- theme / themeUserSet are deliberately absent: nil is meaningful for both
	-- (it is what the ElvUI / EllesmereUI auto-select checks for on first run).
	tabFilters           = {},
	-- itemID -> "YYYY-MM-DD" of the last time a tracked item was seen on a
	-- vendor. See SecretChecklistVendor.lua.
	vendorSeen           = {},
}

-- Kinds a saved filter may legitimately contain. Used to prune keys left behind
-- by kinds that no longer exist.
local VALID_KINDS = {
	mount = true, pet = true, toy = true, achievement = true,
	quest = true, transmog = true, housing = true, mystery = true,
}

-- Top-level keys written by features that have since been removed. They persist
-- in every existing user's SavedVariables forever unless something deletes them.
local RETIRED_KEYS = {
	"filterKinds",   -- superseded by tabFilters.<tab>.kinds
	"filterStatus",  -- superseded by tabFilters.<tab>.showCollected / showMissing
	"lastError",     -- removed error-reporting feature
	"lastReport",    -- removed error-reporting feature
	"aboutUnlocked", -- written by UnlockAboutTab, which was never called and is now removed
}

-- Idempotent: safe to call more than once.
function SC:InitDB()
	-- A client crash mid-write can leave the SavedVariables file truncated, in
	-- which case the global may be absent or not a table. Indexing it would then
	-- error before anything else in the addon runs.
	if type(SecretChecklistDB) ~= "table" then
		SecretChecklistDB = {}
	end
	local db = SecretChecklistDB

	-- Read the stored version BEFORE applying defaults. If dbVersion were seeded
	-- as a default, every existing profile would be stamped current and skip
	-- every migration below -- which is exactly what the first version of this
	-- function did.
	local fromVersion = db.dbVersion or 0

	for key, default in pairs(DB_DEFAULTS) do
		if db[key] == nil then
			db[key] = (type(default) == "table") and {} or default
		end
	end

	-- Migrations are ordered and gated on the version the profile arrived with.
	-- Each step is written to be idempotent, so a profile that took the bogus
	-- version-1 stamp is corrected here rather than needing a separate step.
	-- Gated on 3, not 2: the prune below is idempotent and the list has grown, so
	-- a profile already stamped 2 still needs one more pass over it.
	if fromVersion < 3 then
		for _, key in ipairs(RETIRED_KEYS) do
			db[key] = nil
		end
		-- Installs predating themeUserSet: a theme already saved counts as the
		-- user's own choice, so upgrading never moves anyone off the theme they
		-- picked. Seeding it here -- before any auto-select runs -- is what stops
		-- an auto-pick being mistaken for a deliberate one. This used to be
		-- duplicated in the PLAYER_LOGIN handler and in the EllesmereUI skin
		-- callback because neither knew which would run first; with InitDB
		-- running at ADDON_LOADED, both are strictly later and can just read it.
		if db.themeUserSet == nil then
			db.themeUserSet = (db.theme ~= nil)
		end
		if type(db.tabFilters) == "table" then
			for _, filter in pairs(db.tabFilters) do
				if type(filter) == "table" and type(filter.kinds) == "table" then
					for kind in pairs(filter.kinds) do
						if not VALID_KINDS[kind] then
							filter.kinds[kind] = nil
						end
					end
				end
			end
		end
	end

	-- Stamped once, after every migration has had a chance to run.
	db.dbVersion = DB_VERSION

	return db
end

-- Called again from ADDON_LOADED; this early call keeps the file-scope readers
-- (the minimap button's saved angle, for one) working until they move.
SC:InitDB()

-- Globals required by AddonCompartmentFunc / Enter / Leave
-- When registered via RegisterAddon() (not TOC), the calling convention is:
--   func(_, menuInputData, menu)  where menuInputData.buttonName = "LeftButton"/"RightButton"
--   funcOnEnter(button, addonInfo)
--   funcOnLeave(button, addonInfo)
function SecretChecklist_OnAddonCompartmentClick(_, menuInputData, menu)
	local buttonName = menuInputData and menuInputData.buttonName or "LeftButton"
	if buttonName == "RightButton" then
		if SC.OpenOptionsPanel then SC:OpenOptionsPanel() end
	else
		SC:ToggleSecretsFrame()
	end
end

function SecretChecklist_OnAddonCompartmentEnter(button, addonInfo)
	local L = _G.SecretChecklistLocale or {}
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(L["ADDON_NAME"] or "Secret Checklist", 1, 1, 1)
	GameTooltip:AddLine(L["TOOLTIP_CLICK_TOGGLE"] or "Click to toggle window", 0.8, 0.8, 0.8)
	GameTooltip:AddLine(L["TOOLTIP_RIGHT_CLICK_OPTIONS"] or "Right-click to open options", 0.8, 0.8, 0.8)
	GameTooltip:Show()
end

function SecretChecklist_OnAddonCompartmentLeave(button, addonInfo)
	GameTooltip:Hide()
end

-- An empty UI translation has to behave as an absent one.
--
-- Every call site is written `L["KEY"] or "English"`, and "" is truthy in Lua,
-- so a locale file containing L["TAB_GUIDES"] = "" would render a blank label
-- rather than falling back. That is a very easy line for a translator to leave
-- behind, and the result looks like a bug in the addon rather than a gap in the
-- translation. Runs once, straight after locale.xml has loaded every locale.
do
	local locale = _G.SecretChecklistLocale
	if type(locale) == "table" then
		for key, value in pairs(locale) do
			if value == "" then locale[key] = nil end
		end
	end
end

-- ==============================================
-- DATA STRINGS
-- ==============================================
--
-- Step labels, notes, sources and descriptions live in data/SecretEntries.lua
-- as plain English. Unlike the UI strings in localisation/, they have no keys --
-- there are 794 of them and inventing an id per string would put the burden on
-- whoever adds a secret rather than on whoever translates one.
--
-- So the English text is the key, the way gettext does it. A locale file maps
-- the English to its translation and anything unmapped renders as written, so a
-- half-finished translation degrades string by string instead of all at once,
-- and the data file needs no changes at all.
--
-- The tradeoff: editing an English string orphans its translation. That is the
-- price of needing no keys, and tools/extract-strings.py re-runs to show which
-- strings are newly unmatched.
local dataLocale

function SC:T(text)
	if type(text) ~= "string" then return text end
	if dataLocale == nil then
		-- Resolved once. `false` records "no locale table" so this never
		-- re-reads the global on a client with no translation loaded.
		dataLocale = _G.SecretChecklistDataLocale or false
	end
	if not dataLocale then return text end
	local translated = dataLocale[text]
	-- Generated locale files pre-seed every string with "", so an untranslated
	-- entry is empty rather than absent. Both mean "use the English".
	if translated and translated ~= "" then return translated end
	return text
end

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

-- The journal ID for a mount entry.
--
-- Only two entries carry an explicit mountID; the rest identify their mount by
-- the item that teaches it. GetMountFromItem closes that gap, and it matters
-- for more than tidiness: without a mountID nothing localised is ever looked
-- up, so on a non-English client every one of those mounts kept its English
-- name in the overview while pets, toys and transmog were translated.
function SC:GetMountID(entry)
	if type(entry) ~= "table" then
		return nil
	end
	if type(entry.mountID) == "number" then
		return entry.mountID
	end
	if type(entry.itemID) == "number" and C_MountJournal and C_MountJournal.GetMountFromItem then
		return C_MountJournal.GetMountFromItem(entry.itemID)
	end
	return nil
end

function SC:GetEntryName(entry)
	if type(entry) ~= "table" then
		return "Unknown"
	end

	-- Try to get localized name from game APIs
	if entry.kind == "mount" then
		local mountID = SC:GetMountID(entry)
		if mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
			local name = C_MountJournal.GetMountInfoByID(mountID)
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
		if C_QuestLog and C_QuestLog.GetTitleForQuestID then
			local title = C_QuestLog.GetTitleForQuestID(entry.questID)
			if title and title ~= "" then
				return title
			end
		end
	end

	-- Fall back to hardcoded name in data file
	-- Translated for display only. entry.name is also the key that requires /
	-- requiredFor / stepsRef / partOf resolve against, and those comparisons use
	-- the raw field -- translating here would not break them.
	if type(entry.name) == "string" and entry.name ~= "" then
		return SC:T(entry.name)
	end

	return "Unknown"
end

-- Intentionally a no-op, kept as a stable call site for the panel files.
--
-- This used to call C_MountJournal.SetDefaultFilters / C_PetJournal.SetDefaultFilters
-- / C_ToyBox.ForceToyRefilter to "prime" the journals. Those are mutators, not
-- getters: every page turn, tab switch and filter change silently reset the
-- player's own Collections journal filters, and fought with addons that persist
-- journal state (Collectionator, BetterWardrobe, AllTheThings). They also fed a
-- MOUNT_JOURNAL_SEARCH_UPDATED -> refresh loop that had to be worked around in
-- TabOverview.
--
-- None of it was needed: GetMountInfoByID, GetNumCollectedInfo and PlayerHasToy
-- read account collection data directly and do not depend on journal filter
-- state or on the Collections UI having been opened.
function SC:RefreshCaches()
end

-- Status cache, keyed by entry table.
--
-- A single Overview page turn asks for entry status several times over: once
-- per entry to apply the collected/missing filter, again to build the sort key,
-- again per visible button to pick its border and colour, and again for the
-- progress counters -- and each answer costs 1-3 C API calls. The alert scan
-- walks every entry as well. Nothing about that changes between the calls.
--
-- "unknown" is deliberately never cached: it means the journal or catalog has
-- not finished loading, so re-asking is exactly the right behaviour. Only
-- settled answers are stored.
--
-- Invalidated wholesale by SC:InvalidateStatusCache, which the collection, bag
-- and housing event handlers call. Keys are entry tables from SC.entries, which
-- live for the session, so the cache is bounded and holds nothing else alive.
local statusCache, detailCache = {}, {}

function SC:InvalidateStatusCache()
	wipe(statusCache)
	wipe(detailCache)
end

function SC:GetEntryStatus(entry)
	-- Returns: "collected" | "missing" | "unknown" | "manual", plus optional detail
	if type(entry) ~= "table" then
		return "unknown", "Invalid entry"
	end

	local cached = statusCache[entry]
	if cached then
		return cached, detailCache[entry]
	end

	local status, detail
	if entry.kind == "manual" then
		status, detail = "manual", entry.note
	else
		local have, d = self:CheckEntry(entry)
		detail = d
		if have == true then
			status = "collected"
		elseif have == false then
			status = "missing"
		else
			status = "unknown"
		end
	end

	if status ~= "unknown" then
		statusCache[entry] = status
		detailCache[entry] = detail
	end
	return status, detail
end

-- One resolver per kind.
--
-- This was a 190-line if-chain, which meant adding a collectible type required
-- finding the right place inside it and the important part -- the questID
-- short-circuit that most secrets actually resolve through -- was buried at the
-- top of it. Each resolver is now independently readable, and the transmog bug
-- fixed in 3fc4fe0 is the kind of thing that hid in the middle of the chain.
--
-- Each takes an entry and returns (collected, detail), where collected is
-- true / false / nil, nil meaning "cannot tell yet".
local checkers = {}

-- True when the quest is flagged complete. Retail answers account-wide, which
-- is what a secret means there; a client without the warband API (Forever)
-- falls back to the character's own flag. nil when no quest API exists.
function SC:IsQuestDone(questID)
	if not C_QuestLog then return nil end
	if C_QuestLog.IsQuestFlaggedCompletedOnAccount then
		return C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) == true
	end
	if C_QuestLog.IsQuestFlaggedCompleted then
		return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
	end
	return nil
end

do
	checkers.toy = function(entry)
		if type(entry.itemID) ~= "number" then
			return nil, "Toy missing itemID."
		end
		if not PlayerHasToy then
			return nil, "Toy API unavailable."
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
				return nil, "Toy data has not finished loading yet."
			end
		end
		return false, "toy"
	end

	checkers.mount = function(entry)
		if not C_MountJournal or not C_MountJournal.GetMountInfoByID then
			return nil, "MountJournal API unavailable (try after fully logged in)."
		end

		-- Either an explicit mountID (e.g. Fathom Dweller) or the journal ID
		-- resolved from the item that teaches the mount.
		local mountID = SC:GetMountID(entry)
		if type(mountID) == "number" then
			local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
			if isCollected == nil then
				return nil, "Mount data has not finished loading yet."
			end
			return isCollected == true, "mount"
		end

		return nil, "Could not map to a mount yet (no mountID or itemID matched)."
	end

	checkers.pet = function(entry)
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
			return nil, "Pet data has not finished loading yet."
		end
		return numOwned > 0, "pet"
	end

	-- These two branches validate their id like every other kind does. Both APIs
	-- error on a nil id, and the data file is where contributors add entries.
	checkers.achievement = function(entry)
		if type(entry.achievementID) ~= "number" then
			return nil, "Achievement entry missing achievementID."
		end
		local _, _, _, completed = GetAchievementInfo(entry.achievementID)
		return completed == true, "achievement"
	end

	checkers.quest = function(entry)
		if type(entry.questID) ~= "number" then
			return nil, "Quest entry missing questID."
		end
		local done = SC:IsQuestDone(entry.questID)
		if done == nil then
			return nil, "Quest API unavailable."
		end
		return done, "quest"
	end

	checkers.transmog = function(entry)
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
		-- Fallback: resolve the appearance source and ask whether it is collected.
		--
		-- This used to unpack a fifth return from C_TransmogCollection.GetItemInfo
		-- as `isCollected`. That function returns exactly two values --
		-- appearanceID and sourceID -- so the fifth was always nil and this branch
		-- could only ever fall through to the "not loaded" message below. It was a
		-- fallback that never fell back.
		if C_TransmogCollection.GetItemInfo and C_TransmogCollection.GetSourceInfo then
			local _, sourceID = C_TransmogCollection.GetItemInfo(entry.itemID)
			if sourceID then
				local info = C_TransmogCollection.GetSourceInfo(sourceID)
				if info and info.isCollected ~= nil then
					return info.isCollected == true, "transmog"
				end
			end
		end
		return nil, "Appearance data has not finished loading yet."
	end

	checkers.housing = function(entry)
		if not C_HousingCatalog or not C_HousingCatalog.GetCatalogEntryInfoByItem then
			return nil, "HousingCatalog API unavailable."
		end
		if type(entry.itemID) ~= "number" then
			return nil, "Housing entry missing itemID."
		end
		-- pcall guards against Lua errors thrown by the API during catalog reloads
		-- (e.g. zone transitions), matching the same pattern used by HousingCompanion
		-- and AllTheThings for robustness.
		local ok, info = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, entry.itemID, true)
		if not ok or not info then
			return nil, "Housing catalog data not loaded yet."
		end
		-- Primary ownership check: totalNumStored + numPlaced + totalNumPlaced.
		-- entrySubtype (0=Invalid, 1=Unowned, 2=OwnedModified, 3=OwnedUnmodified) is
		-- documented as the ownership signal but has been observed to stay 1 even for
		-- owned items (Blizzard API inconsistency confirmed in-game). The quantity fields
		-- are reliable: storage-loaded items show totalNumStored>0 when owned.
		local totalOwned = (info.totalNumStored or 0) + (info.numPlaced or 0) + (info.totalNumPlaced or 0)
		if totalOwned > 0 then
			return true, "housing"
		end
		-- Fallback to entrySubtype for items where quantity fields are absent or zero.
		-- subtype 0/nil = catalog not merged yet → nil (unknown).
		-- subtype 1 = API reports Unowned; guard with _housingStorageReady to avoid
		-- false-negative flicker during zone transitions where storage briefly clears.
		local subtype = info.entryID and info.entryID.entrySubtype
		if not subtype or subtype == 0 then
			return nil, "Housing catalog data not loaded yet."
		end
		if subtype == 1 and not SC._housingStorageReady then
			return nil, "Housing storage not loaded yet."
		end
		return (subtype ~= 1), "housing"
	end

	checkers.mystery = function(entry)
		if entry.steps and #entry.steps > 0 then
			local allDone = true
			for _, step in ipairs(entry.steps) do
				if SC:GetStepStatus(step) ~= "done" then
					allDone = false
					break
				end
			end
			if allDone then
				return true, "mystery"
			end
		end
		return nil, "Reward unknown – in active investigation"
	end

	checkers.manual = function(entry)
		return nil, entry.note or "Manual check"
	end
end

function SC:CheckEntry(entry)
	-- Always check questID first — most secrets flag a hidden quest on completion,
	-- and this is more reliable than API-specific checks (e.g. ensemble transmog
	-- items). Hoisted out of the chain so it reads as the rule it is rather than
	-- as the first of nine branches.
	if type(entry.questID) == "number" and SC:IsQuestDone(entry.questID) then
		return true, "quest"
	end

	local checker = checkers[entry.kind]
	if not checker then
		-- Names the offending kind, where the chain's fall-through said only
		-- "Unknown kind". /secrets validate reports these up front.
		return nil, "Unknown kind: " .. tostring(entry.kind)
	end
	return checker(entry)
end

-- Returns the total count across step.itemID or any ID in step.itemIDs (whichever is set).
local function StepItemCount(step)
	if step.itemIDs then
		local total = 0
		for _, id in ipairs(step.itemIDs) do
			total = total + C_Item.GetItemCount(id, true, nil, nil, true)
		end
		return total
	elseif step.itemID then
		return C_Item.GetItemCount(step.itemID, true, nil, nil, true)
	end
	return 0
end

-- True when the collectible a step's item unlocks is already owned.
--
-- "Claim the collectible" steps name the item that grants it -- a pet cage, a
-- mount item, an ensemble, a decor item. Every one of those is consumed the
-- moment it is used, so GetItemCount reads 0 from then on and the step can
-- never show done on its own merits. It stays red forever after being
-- completed, which is only masked because stepsOverrideOnDone paints all steps
-- green once the parent entry is collected -- so the step check is wrong and
-- invisible at the same time, and becomes visible the moment debug mode turns
-- that override off.
--
-- Toys and housing were already handled here; mounts, appearances and pets were
-- not. Pets take an explicit step.speciesID rather than resolving one from the
-- item, because the field position of speciesID in GetPetInfoByItemID's return
-- list is not worth depending on.
local function StepCollectibleOwned(step)
	local itemID = step.itemID
	if type(itemID) ~= "number" then return false end

	if PlayerHasToy and PlayerHasToy(itemID) then return true end

	if step.speciesID and C_PetJournal and C_PetJournal.GetNumCollectedInfo then
		local numOwned = C_PetJournal.GetNumCollectedInfo(step.speciesID)
		if numOwned and numOwned > 0 then return true end
	end

	if C_MountJournal and C_MountJournal.GetMountFromItem and C_MountJournal.GetMountInfoByID then
		local mountID = C_MountJournal.GetMountFromItem(itemID)
		if type(mountID) == "number" then
			if select(11, C_MountJournal.GetMountInfoByID(mountID)) == true then return true end
		end
	end

	if C_TransmogCollection and C_TransmogCollection.PlayerHasTransmog
			and C_TransmogCollection.PlayerHasTransmog(itemID) == true then
		return true
	end

	-- Housing items go to the catalog, not to bags, on purchase.
	if C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
		local ok, hinfo = pcall(C_HousingCatalog.GetCatalogEntryInfoByItem, itemID, true)
		if ok and hinfo then
			local hTotal = (hinfo.totalNumStored or 0) + (hinfo.numPlaced or 0) + (hinfo.totalNumPlaced or 0)
			if hTotal > 0 then return true end
		end
	end

	return false
end

-- True when the step's item is currently equipped.
--
-- GetItemCount counts bags and banks but not equipped slots, so a step that
-- reads "obtain X and equip it" flips back to missing the instant the player
-- does the second half of what it asked -- unless they happen to be carrying a
-- spare.
local function StepItemEquipped(step)
	if type(step.itemID) ~= "number" then return false end
	local isEquipped = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
	if not isEquipped then return false end
	local ok, equipped = pcall(isEquipped, step.itemID)
	return ok and equipped == true
end

-- Returns the status of a single progress step:
--   "done"    – quest flagged completed
--   "ready"   – quest not done, but item(s) are in bags/bank
--   "missing" – quest not done and item(s) not found
-- True when the step's quest, or any of them, is flagged complete.
--
-- questIDs (plural) is for one action that carries a different quest id per
-- faction: Mrrl's "A Safer Place" escort is 55983 on Alliance and 55530 on
-- Horde, so a Horde character who had done it still read as incomplete.
-- Checking every id is simpler than resolving the player's faction, and it is
-- also correct for a character who completed it on the other one.
local function StepQuestCompleted(step)
	if not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then return false end
	if step.questID and C_QuestLog.IsQuestFlaggedCompleted(step.questID) then
		return true
	end
	if step.questIDs then
		for _, id in ipairs(step.questIDs) do
			if C_QuestLog.IsQuestFlaggedCompleted(id) then return true end
		end
	end
	return false
end

-- Whether a step is quest-backed at all, however it names its quests. Several
-- branches below read "has a quest" as "holding this item is a prerequisite
-- rather than the completion", so they have to see questIDs too.
local function StepHasQuest(step)
	return step.questID ~= nil or step.questIDs ~= nil
end

function SC:GetStepStatus(step)
	if StepQuestCompleted(step) then
		return "done"
	end
	if step.criteriaID and step.achievementID and GetAchievementCriteriaInfoByID then
		local _, _, criteriaCompleted = GetAchievementCriteriaInfoByID(step.achievementID, step.criteriaID)
		if criteriaCompleted then return "done" end
	end
	if step.achievementID then
		local _, _, _, completed = GetAchievementInfo(step.achievementID)
		if completed then return "done" end
	end
	if step.renownReq and C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel then
		local current = C_MajorFactions.GetCurrentRenownLevel(step.renownReq.factionID)
		if current and current >= step.renownReq.level then return "done" end
		return "missing"
	end
	if step.mindseekerReq then
		local count = 0
		for _, e in ipairs(SC.entries or {}) do
			if e.mindSeeker and SC:GetEntryStatus(e) == "collected" then
				count = count + 1
			end
		end
		if count >= step.mindseekerReq then return "done" end
		return "missing"
	end
	if step.repReq then
		local data = C_Reputation and C_Reputation.GetFactionDataByID and
		C_Reputation.GetFactionDataByID(step.repReq.factionID)
		local standingID = data and data.reaction or 0
		if standingID >= step.repReq.standingID then return "done" end
		return "missing"
	end
	if SC:ResolveSubsteps(step) then
		-- If the parent item is already in bags, it's done regardless of substep state
		-- (substep items may be consumed on combine, e.g. Quartered Ancient Rings)
		if (step.itemID or step.itemIDs) and StepItemCount(step) >= (step.count or 1) then return "done" end
		-- If a final item is required but not yet obtained, stay red — substep rows show per-key progress
		if step.itemID or step.itemIDs then return "missing" end
		-- No final item: derive status purely from substep completion
		local done, total = SC:GetSubstepProgress(step)
		if done >= total then return "done" end
		return "missing"
	end
	if step.itemID or step.itemIDs then
		local have = StepItemCount(step)
		if have >= (step.count or 1) then
			-- No questID means having the item IS completion (e.g. ring drops, climb rewards).
			-- With a questID, the item is a prerequisite you're holding but haven't used yet → yellow.
			if not StepHasQuest(step) then return "done" end
			return "ready"
		end
		-- Not in bags. That is not the same as not done: the item may have been
		-- consumed into the collection it unlocks, or be equipped right now.
		if StepCollectibleOwned(step) then return "done" end
		if StepItemEquipped(step) then
			-- Same rule as the in-bags branch above: with a questID the item is a
			-- prerequisite being held, without one, having it is the completion.
			if not StepHasQuest(step) then return "done" end
			return "ready"
		end
	end
	return "missing"
end

-- Returns the effective substep list for a step, resolving factionSubsteps by the
-- player's current faction when present, falling back to step.substeps.
function SC:ResolveSubsteps(step)
	if step.factionSubsteps then
		local fkey = (UnitFactionGroup and UnitFactionGroup("player") == "Alliance") and "alliance" or "horde"
		return step.factionSubsteps[fkey]
	end
	return step.substeps
end

-- Returns (doneCount, total) for a step with substeps.
-- Collection: doneCount = number of substeps whose item/quest is completed.
-- Chain:      doneCount = index of the currently-held item (0 = nothing held).
function SC:GetSubstepProgress(step)
	local subs = SC:ResolveSubsteps(step)
	if not subs then return 0, 0 end
	if step.chain then
		local total = #subs
		local highestHeld = 0
		for idx, sub in ipairs(subs) do
			if sub.itemID and C_Item.GetItemCount(sub.itemID, true, nil, nil, true) >= 1 then
				highestHeld = idx
			end
		end
		return highestHeld, total
	else
		local done, total = 0, 0
		for _, sub in ipairs(subs) do
			local subTotal = sub.count or 1
			total = total + subTotal
			if sub.questID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
					and C_QuestLog.IsQuestFlaggedCompleted(sub.questID) then
				done = done + subTotal
			elseif sub.itemID then
				local have = C_Item.GetItemCount(sub.itemID, true, nil, nil, true)
				done = done + math_min(have, subTotal)
			end
		end
		return done, total
	end
end

SLASH_SECRETCHECKLIST1 = "/secrets"
SLASH_SECRETCHECKLIST2 = "/secretchecklist"
-- Only "options"/"settings" and the bare command were ever documented; the rest
-- existed but were undiscoverable, and an unrecognised argument silently opened
-- the window as though it had been understood.
local SLASH_HELP = {
	{ "",         "Open the Secret Checklist window" },
	{ "options",  "Open the settings panel" },
	{ "minimap",  "Toggle the minimap button" },
	{ "alert",    "Fire a test collection toast" },
	{ "validate", "Check the secret data for problems" },
	{ "debug",    "Toggle debug mode (shows real per-step state on collected secrets)" },
	{ "help",     "Show this list" },
}

local function PrintSlashHelp()
	print("|cffffcc00Secret Checklist|r — /secrets or /secretchecklist")
	for _, row in ipairs(SLASH_HELP) do
		local cmd = row[1] == "" and "/secrets" or ("/secrets " .. row[1])
		print(("  |cff88ccff%-18s|r %s"):format(cmd, row[2]))
	end
end

SlashCmdList.SECRETCHECKLIST = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

	if msg == "help" or msg == "?" then
		PrintSlashHelp()
		return
	end

	if msg == "options" or msg == "settings" then
		if SC.OpenOptionsPanel then
			SC:OpenOptionsPanel()
		end
		return
	end

	if msg == "debug" then
		SecretChecklistDB.debugMode = not SecretChecklistDB.debugMode
		if SecretChecklistDB.debugMode then
			print(
			"|cffffcc00SecretChecklist:|r Debug mode |cff00ff00enabled|r — stepsOverrideOnDone is suppressed. Type /secrets debug to disable.")
		else
			print("|cffffcc00SecretChecklist:|r Debug mode |cffff4444disabled|r.")
		end
		-- Refresh the guides panel so step colours update immediately
		if SC.onFilterChange then SC.onFilterChange() end
		return
	elseif msg == "minimap" then
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
	elseif msg == "validate" then
		if SC.ValidateData then
			SC:ValidateData()
		end
	elseif msg == "" then
		if SC.OpenCollectionsSecretsTab then
			SC:OpenCollectionsSecretsTab()
		end
	else
		-- An unrecognised argument used to open the window, which looks
		-- indistinguishable from the command having worked.
		print(("|cffffcc00Secret Checklist:|r unknown command %q."):format(msg))
		PrintSlashHelp()
	end
end
