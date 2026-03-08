-- French (FR) locale
local LOCALE = GetLocale()
if LOCALE ~= "frFR" then return end

local L = _G.SecretChecklistLocale or {}

-- Add French translations here
-- L["ADDON_NAME"] = "Liste des Secrets"
-- L["FILTER"] = "Filtre"
-- etc.

_G.SecretChecklistLocale = L
