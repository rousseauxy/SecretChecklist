-- German (DE) locale
local LOCALE = GetLocale()
if LOCALE ~= "deDE" then return end

local L = _G.SecretChecklistLocale or {}

-- General
L["ADDON_NAME"] = "Geheimnisse-Checkliste"
L["ADDON_LOADED"] = "Geladen. Gib /secrets ein, um zu öffnen."

-- UI Elements
L["WINDOW_TITLE"] = "Geheimnisse-Checkliste"
-- L["PROGRESS_FORMAT"] = "%d/%d" -- Use default
-- L["PAGE_FORMAT"] = "Seite %d / %d"

-- Filter
L["FILTER"] = "Filter"
L["FILTER_WITH_COUNT"] = "Filter (%d)"
L["FILTER_BY_STATUS"] = "Nach Status filtern"
L["FILTER_BY_TYPE"] = "Nach Typ filtern"
L["FILTER_ALL"] = "Alle"
L["FILTER_COLLECTED"] = "Gesammelt"
L["FILTER_MISSING"] = "Fehlend"
L["FILTER_SELECT_ALL"] = "Alle auswählen"
L["FILTER_DESELECT_ALL"] = "Alle abwählen"
L["FILTER_STATUS_ALL"] = "Alle"
L["FILTER_STATUS_COLLECTED"] = "Gesammelt"
L["FILTER_STATUS_MISSING"] = "Fehlt"
L["FILTER_STATUS_UNKNOWN"] = "Unbekannt"

-- Entry Types (singular)
L["KIND_TOY"] = "Spielzeug"
L["KIND_MOUNT"] = "Reittier"
L["KIND_PET"] = "Haustier"
L["KIND_ACHIEVEMENT"] = "Erfolg"
L["KIND_TRANSMOG"] = "Transmog"
L["KIND_QUEST"] = "Quest"
L["KIND_SPELL"] = "Zauber"
L["KIND_MANUAL"] = "Manuell"

-- Entry Types (plural - for filter menu)
L["KIND_TOYS"] = "Spielzeuge"
L["KIND_MOUNTS"] = "Reittiere"
L["KIND_PETS"] = "Haustiere"
L["KIND_ACHIEVEMENTS"] = "Erfolge"
L["KIND_TRANSMOGS"] = "Transmog"
L["KIND_QUESTS"] = "Quests"

-- Tooltips
L["TOOLTIP_CLICK"] = "Klicken, um Fenster umzuschalten"
L["TOOLTIP_CLICK_TOGGLE"] = "Klicken, um Fenster umzuschalten"
L["TOOLTIP_DRAG"] = "Ziehen zum Bewegen"
L["TOOLTIP_DRAG_MOVE"] = "Ziehen zum Bewegen"
L["TOOLTIP_COLLECTED"] = "Gesammelt"
L["TOOLTIP_NOT_COLLECTED"] = "Nicht gesammelt"
L["TOOLTIP_COMPLETED"] = "Abgeschlossen"
L["TOOLTIP_NOT_COMPLETED"] = "Nicht abgeschlossen"

-- Settings
L["SETTINGS_TITLE"] = "SecretChecklist"
L["SETTINGS_MINIMAP"] = "Minimap-Button anzeigen"
L["SETTINGS_MINIMAP_BUTTON"] = "Minimap-Button anzeigen"
L["SETTINGS_MINIMAP_DESC"] = "SecretChecklist-Minimap-Button anzeigen oder verbergen."
L["SETTINGS_MINIMAP_BUTTON_DESC"] = "SecretChecklist-Minimap-Button anzeigen oder verbergen."

-- Slash Commands
L["CMD_OPTIONS"] = "Öffne Einstellungen..."
L["CMD_MINIMAP_SHOW"] = "Minimap-Button angezeigt."
L["CMD_MINIMAP_HIDE"] = "Minimap-Button ausgeblendet."

-- Status Messages
L["DATA_NOT_READY"] = "Sammlungsdaten noch nicht bereit. Versuche, Sammlungen einmal zu öffnen."
L["UNKNOWN_ENTRY"] = "(unbekannt)"
L["UNKNOWN"] = "(unbekannt)"

_G.SecretChecklistLocale = L
