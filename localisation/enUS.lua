-- English (US) - Default locale
local L = {}

-- General
L["ADDON_NAME"] = "Secrets Checklist"
L["ADDON_LOADED"] = "Loaded. Type /secrets to open."

-- UI Elements
L["WINDOW_TITLE"] = "Secrets Checklist"
L["PAGE_FORMAT"] = "Page %d / %d"
L["SECRETS"] = "Secrets"
L["MIND_SEEKER"] = "Mind-Seeker"

-- Filter
L["FILTER"] = "Filter"
L["FILTER_WITH_COUNT"] = "Filter (%d)"
L["FILTER_BY_STATUS"] = "Filter by Status"
L["FILTER_BY_TYPE"] = "Filter by Type"
L["FILTER_ALL"] = "All"
L["FILTER_COLLECTED"] = "Collected"
L["FILTER_MISSING"] = "Missing"
L["FILTER_SELECT_ALL"] = "Select All"
L["FILTER_DESELECT_ALL"] = "Deselect All"
-- Entry Types (singular)
L["KIND_TOY"] = "Toy"
L["KIND_MOUNT"] = "Mount"
L["KIND_PET"] = "Pet"
L["KIND_ACHIEVEMENT"] = "Achievement"
L["KIND_TRANSMOG"] = "Transmog"
L["KIND_QUEST"] = "Quest"
L["KIND_MANUAL"] = "Manual"

-- Entry Types (plural - for filter menu)
L["KIND_TOYS"] = "Toys"
L["KIND_MOUNTS"] = "Mounts"
L["KIND_PETS"] = "Pets"
L["KIND_ACHIEVEMENTS"] = "Achievements"
L["KIND_TRANSMOGS"] = "Transmog"
L["KIND_QUESTS"] = "Quests"

-- Tooltips
L["TOOLTIP_CLICK_TOGGLE"] = "Click to toggle window"
L["TOOLTIP_DRAG_MOVE"] = "Drag to move"
L["TOOLTIP_COLLECTED"] = "Collected"
L["TOOLTIP_NOT_COLLECTED"] = "Not collected"
L["TOOLTIP_COMPLETED"] = "Completed"
L["TOOLTIP_NOT_COMPLETED"] = "Not completed"

-- Settings
L["SETTINGS_TITLE"] = "SecretChecklist"
L["SETTINGS_MINIMAP_BUTTON"] = "Show Minimap Button"
L["SETTINGS_MINIMAP_BUTTON_DESC"] = "Show or hide the SecretChecklist minimap button."

-- Slash Commands
L["CMD_OPTIONS"] = "Opening settings..."
L["CMD_MINIMAP_SHOW"] = "Minimap button shown."
L["CMD_MINIMAP_HIDE"] = "Minimap button hidden."

-- Status Messages
L["DATA_NOT_READY"] = "Collection data not ready yet. Try opening Collections once."
L["UNKNOWN"] = "(unknown)"

-- Make the locale table available globally
local LOCALE = GetLocale()
if LOCALE == "enUS" or LOCALE == "enGB" then
	_G.SecretChecklistLocale = L
end

return L
