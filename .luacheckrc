-- luacheck configuration for SecretChecklist
--
-- Run locally with:  luacheck .
-- CI runs the same command on every push and pull request.
--
-- The WoW client runs Lua 5.1 with a large set of injected globals. luacheck
-- has no built-in WoW standard library, so the API surface this addon touches
-- is declared below. A global that is genuinely missing from the client (the
-- UnitCreatureID that shipped in 1.11.0 and errored on every login) shows up
-- here as an undefined-global warning.

std = "lua51"

max_line_length = false

-- Handlers are written as function(self, event, ...) and frequently ignore
-- some parameters; that is idiomatic, not a defect.
unused_args = false

ignore = {
	"431", -- shadowing an upvalue -- pervasive and harmless with `self` in nested handlers
	"432", -- shadowing an upvalue argument -- same
}

exclude_files = {
	".release/",
}

-- Globals this addon owns and writes.
globals = {
	"SecretChecklist",
	"SecretChecklistDB",
	"SecretChecklistLocale",
	"SecretChecklistFrame",
	"SecretChecklist_AlertFrameMixin",
	"SecretChecklist_OnAddonCompartmentClick",
	"SecretChecklist_OnAddonCompartmentEnter",
	"SecretChecklist_OnAddonCompartmentLeave",
	"SLASH_SECRETCHECKLIST1",
	"SLASH_SECRETCHECKLIST2",
	"SlashCmdList",
	"UISpecialFrames",
}

-- Globals provided by the client or by optional third-party addons.
read_globals = {
	-- C_* namespaces
	"C_AddOns",
	"C_ChatInfo",
	"C_DateAndTime",
	"C_HousingCatalog",
	"C_Item",
	"C_MajorFactions",
	"C_Map",
	"C_MountJournal",
	"C_PetJournal",
	"C_QuestLog",
	"C_Reputation",
	"C_Spell",
	"C_SuperTrack",
	"C_Texture",
	"C_Timer",
	"C_ToyBox",
	"C_TransmogCollection",
	"C_UnitAuras",

	-- Widgets and UI
	"AddonCompartmentFrame",
	"AlertFrame",
	"AlertFrame_OnClick",
	"ButtonFrameTemplate_HideAttic",
	"ChatEdit_InsertLink",
	"CreateFrame",
	"GetMerchantItemLink",
	"GetMerchantNumItems",
	"hooksecurefunc",
	"IsModifiedClick",
	"DEFAULT_CHAT_FRAME",
	"GameTooltip",
	"Minimap",
	"Model_ApplyUICamera",
	"PlaySound",
	"SearchBoxTemplate_OnTextChanged",
	"Settings",
	"UIParent",
	"UiMapPoint",

	-- Constants
	"CAMERA_MODIFICATION_TYPE_DISCARD",
	"CAMERA_TRANSITION_TYPE_IMMEDIATE",
	"Constants",
	"ITEM_QUALITY_COLORS",
	"LE_PARTY_CATEGORY_HOME",
	"LE_PARTY_CATEGORY_INSTANCE",
	"RETRIEVING_DATA",
	"SOUNDKIT",

	-- Achievements, items, collections
	"GetAchievementCriteriaInfoByID",
	"GetAchievementInfo",
	"GetAchievementLink",
	"GetAddOnMetadata",
	"IsEquippedItem", -- deprecated global; used only as a fallback for C_Item.IsEquippedItem
	"PlayerHasToy",
	"WOW_PROJECT_CAMELOT", -- WoW: Forever; nil on retail
	"WOW_PROJECT_ID",

	-- Units, group and player state
	"DoEmote",
	"GetCursorPosition",
	"GetLocale",
	"GetNumGroupMembers",
	"GetRaidRosterInfo",
	"GetRealmName",
	"GetTime",
	"HasAnySecretValues",
	"IsAltKeyDown",
	"IsControlKeyDown",
	"IsInGroup",
	"IsInRaid",
	"UnitFactionGroup",
	"UnitCreatureID", -- present on some clients; always called behind a guard
	"UnitFullName",
	"UnitGUID",
	"UnitIsUnit",
	"UnitName",

	-- FrameXML helpers
	"strsplit",
	"wipe",

	-- Optional third-party addons (## OptionalDeps)
	"ElvUI",
	"EllesmereUI",
	"TomTom",
}
