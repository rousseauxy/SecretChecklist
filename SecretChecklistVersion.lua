-- SecretChecklistVersion.lua
-- Broadcasts the addon version over group/raid chat and notifies the player
-- if a newer version is detected from another party member (same as ElvUI does).

local SC = _G.SecretChecklist
if not SC then return end

local ADDON_PREFIX  = "SC_VERSIONCHK"
local ADDON_VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(
    "SecretChecklist", "Version") or "0.0.0"

-- Convert "major.minor.patch" to a sortable integer for numeric comparison.
-- e.g. "1.8.4" → 10804
local function VersionToInt(v)
    local maj, min, patch = (v or "0"):match("^(%d+)%.?(%d*)%.?(%d*)")
    return (tonumber(maj)   or 0) * 10000
         + (tonumber(min)   or 0) * 100
         + (tonumber(patch) or 0)
end

local MY_VERSION_INT = VersionToInt(ADDON_VERSION)
local versionWarned  = false  -- only print once per session
local groupSize      = 0
local myFullName     = nil    -- resolved lazily after login

local function GetMyFullName()
    if not myFullName then
        local name, realm = UnitFullName("player")
        if name then
            realm = (realm and realm ~= "") and realm or GetRealmName()
            myFullName = name .. "-" .. realm
        end
    end
    return myFullName
end

local function SendVersion()
    local payload = tostring(MY_VERSION_INT)
    if IsInRaid() then
        local ch = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE))
                    and "INSTANCE_CHAT" or "RAID"
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, payload, ch)
    elseif IsInGroup() then
        local ch = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE))
                    and "INSTANCE_CHAT" or "PARTY"
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, payload, ch)
    end
end

-- Register prefix so incoming messages are delivered to CHAT_MSG_ADDON.
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local versionFrame = CreateFrame("Frame")
versionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
versionFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
versionFrame:RegisterEvent("CHAT_MSG_ADDON")

versionFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Delay broadcast so the game is fully loaded and group state is settled.
        C_Timer.After(10, SendVersion)

    elseif event == "GROUP_ROSTER_UPDATE" then
        local newSize = GetNumGroupMembers()
        if newSize > groupSize then
            -- A new member joined – re-announce after a short delay.
            C_Timer.After(3, SendVersion)
        end
        groupSize = newSize

    elseif event == "CHAT_MSG_ADDON" then
        -- CHAT_MSG_ADDON args: prefix, message, channel, sender
        if arg1 ~= ADDON_PREFIX then return end

        -- Ignore our own broadcasts.
        local me = GetMyFullName()
        if me and arg4 == me then return end
        if arg4 == UnitName("player") then return end

        local theirInt = tonumber(arg2)
        if theirInt and theirInt > MY_VERSION_INT and not versionWarned then
            versionWarned = true
            print(string.format(
                "|cffffcc00SecretChecklist:|r A newer version is available "
                .. "(detected from %s). Your version: |cffaaaaaa%s|r",
                arg4, ADDON_VERSION))
        end
    end
end)
