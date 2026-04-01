-- =============================================================
-- BeledarHelper.lua
-- Minimal BeledarOrchestra player client for SecretChecklist.
--
-- Listens on the "BeledarOrch" addon message prefix for MEASURE,
-- OVERRIDE, START, and RETRY messages broadcast by a raid leader
-- running BeledarOrchestra, then shows a compact popup to the
-- current player with their assigned emote for the active measure.
--
-- Automatically disabled if BeledarOrchestra itself is loaded so
-- no duplicate popups ever appear.
-- =============================================================

local BH_PREFIX   = "BeledarOrch"
local BH_NPC_ID   = 255888   -- Divine Flame of Beledar (Hallowfall)
local BH_ZONE_ID  = 2215     -- Hallowfall

-- =============================================
-- EMOTE DEFINITIONS (mirrors BeledarOrchestra)
-- =============================================
local BH_EMOTES = {
    CHEER       = { command = "CHEER",        display = "/cheer"        },
    SING        = { command = "SING",         display = "/sing"         },
    DANCE       = { command = "DANCE",        display = "/dance"        },
    VIOLIN      = { command = "VIOLIN",       display = "/violin"       },
    APPLAUD     = { command = "APPLAUD",      display = "/applaud"      },
    CONGRATS    = { command = "CONGRATULATE", display = "/congratulate" },
    ROAR        = { command = "ROAR",         display = "/roar"         },
    PLACEHOLDER = { command = nil,            display = "?"             },
}

-- =============================================
-- MEASURES TABLE (from BeledarOrchestra v0.4.29)
-- =============================================
local BH_MEASURES = {
    [1] = {
        [1]="VIOLIN",  [2]="CONGRATS", [3]="VIOLIN",  [4]="ROAR",    [5]="CONGRATS", [6]="APPLAUD", [7]="SING",    [8]="CHEER",   [9]="ROAR",    [10]="DANCE",
        [11]="SING",   [12]="CONGRATS",[13]="ROAR",   [14]="CHEER",  [15]="SING",    [16]="CHEER",  [17]="CHEER",  [18]="CHEER",  [19]="APPLAUD",[20]="SING",
        [21]="APPLAUD",[22]="DANCE",   [23]="VIOLIN", [24]="DANCE",  [25]="VIOLIN",  [26]="DANCE",  [27]="SING",   [28]="CHEER",  [29]="DANCE",  [30]="DANCE",
        [31]="DANCE",  [32]="APPLAUD",[33]="ROAR",   [34]="SING",   [35]="APPLAUD", [36]="SING",   [37]="CHEER",  [38]="DANCE",  [39]="CHEER",  [40]="VIOLIN",
    },
    [2] = {
        [1]="ROAR",    [2]="CONGRATS", [3]="CHEER",   [4]="ROAR",    [5]="APPLAUD",  [6]="ROAR",    [7]="APPLAUD", [8]="SING",    [9]="APPLAUD", [10]="ROAR",
        [11]="SING",   [12]="VIOLIN",  [13]="CHEER",  [14]="SING",   [15]="ROAR",    [16]="CHEER",  [17]="APPLAUD",[18]="DANCE",  [19]="APPLAUD",[20]="SING",
        [21]="ROAR",   [22]="CHEER",   [23]="CHEER",  [24]="SING",   [25]="SING",    [26]="SING",   [27]="SING",   [28]="DANCE",  [29]="CHEER",  [30]="CHEER",
        [31]="ROAR",   [32]="APPLAUD", [33]="ROAR",   [34]="APPLAUD",[35]="APPLAUD", [36]="APPLAUD",[37]="ROAR",   [38]="SING",   [39]="ROAR",   [40]="SING",
    },
    [3] = {
        [1]="APPLAUD", [2]="SING",     [3]="APPLAUD", [4]="ROAR",    [5]="VIOLIN",   [6]="SING",    [7]="SING",    [8]="APPLAUD", [9]="ROAR",    [10]="APPLAUD",
        [11]="DANCE",  [12]="APPLAUD", [13]="VIOLIN", [14]="DANCE",  [15]="ROAR",    [16]="CONGRATS",[17]="SING",  [18]="SING",   [19]="CHEER",  [20]="CONGRATS",
        [21]="APPLAUD",[22]="APPLAUD", [23]="SING",   [24]="VIOLIN", [25]="DANCE",   [26]="SING",   [27]="SING",   [28]="ROAR",   [29]="APPLAUD",[30]="CHEER",
        [31]="DANCE",  [32]="DANCE",   [33]="SING",   [34]="ROAR",   [35]="SING",    [36]="ROAR",   [37]="VIOLIN", [38]="CHEER",  [39]="APPLAUD",[40]="VIOLIN",
    },
    [4] = {
        [1]="SING",    [2]="VIOLIN",   [3]="CONGRATS",[4]="SING",    [5]="DANCE",    [6]="DANCE",   [7]="VIOLIN",  [8]="DANCE",   [9]="CONGRATS",[10]="ROAR",
        [11]="SING",   [12]="CHEER",   [13]="SING",   [14]="SING",   [15]="DANCE",   [16]="SING",   [17]="SING",   [18]="CHEER",  [19]="SING",   [20]="APPLAUD",
        [21]="CONGRATS",[22]="CONGRATS",[23]="ROAR",  [24]="ROAR",   [25]="ROAR",    [26]="SING",   [27]="ROAR",   [28]="DANCE",  [29]="ROAR",   [30]="ROAR",
        [31]="CONGRATS",[32]="CHEER",  [33]="APPLAUD",[34]="DANCE",  [35]="ROAR",    [36]="DANCE",  [37]="CHEER",  [38]="DANCE",  [39]="DANCE",  [40]="CHEER",
    },
    [5] = {
        [1]="SING",    [2]="APPLAUD",  [3]="CONGRATS",[4]="CHEER",   [5]="APPLAUD",  [6]="CONGRATS",[7]="CHEER",   [8]="SING",    [9]="CONGRATS",[10]="SING",
        [11]="DANCE",  [12]="CHEER",   [13]="CHEER",  [14]="DANCE",  [15]="SING",    [16]="ROAR",   [17]="DANCE",  [18]="ROAR",   [19]="SING",   [20]="CHEER",
        [21]="APPLAUD",[22]="ROAR",    [23]="CONGRATS",[24]="SING",  [25]="SING",    [26]="SING",   [27]="CHEER",  [28]="APPLAUD",[29]="SING",   [30]="DANCE",
        [31]="SING",   [32]="SING",    [33]="APPLAUD",[34]="ROAR",   [35]="SING",    [36]="VIOLIN", [37]="ROAR",   [38]="VIOLIN", [39]="SING",   [40]="CHEER",
    },
    [6] = {
        [1]="VIOLIN",  [2]="DANCE",    [3]="SING",    [4]="CONGRATS",[5]="CONGRATS", [6]="SING",    [7]="VIOLIN",  [8]="APPLAUD", [9]="SING",    [10]="CHEER",
        [11]="CHEER",  [12]="CHEER",   [13]="VIOLIN", [14]="SING",   [15]="DANCE",   [16]="SING",   [17]="VIOLIN", [18]="ROAR",   [19]="DANCE",  [20]="CHEER",
        [21]="CHEER",  [22]="VIOLIN",  [23]="SING",   [24]="CONGRATS",[25]="SING",   [26]="SING",   [27]="APPLAUD",[28]="SING",   [29]="SING",   [30]="ROAR",
        [31]="SING",   [32]="SING",    [33]="SING",   [34]="ROAR",   [35]="CHEER",   [36]="CHEER",  [37]="SING",   [38]="CHEER",  [39]="ROAR",   [40]="ROAR",
    },
    [7] = {
        [1]="ROAR",    [2]="SING",     [3]="SING",    [4]="SING",    [5]="SING",     [6]="VIOLIN",  [7]="CONGRATS",[8]="CONGRATS",[9]="CHEER",   [10]="VIOLIN",
        [11]="SING",   [12]="CHEER",   [13]="ROAR",   [14]="CHEER",  [15]="ROAR",    [16]="CONGRATS",[17]="APPLAUD",[18]="ROAR",  [19]="VIOLIN", [20]="VIOLIN",
        [21]="CHEER",  [22]="DANCE",   [23]="ROAR",   [24]="ROAR",   [25]="APPLAUD", [26]="SING",   [27]="ROAR",   [28]="CHEER",  [29]="SING",   [30]="SING",
        [31]="APPLAUD",[32]="SING",    [33]="DANCE",  [34]="CONGRATS",[35]="VIOLIN", [36]="CHEER",  [37]="ROAR",   [38]="CHEER",  [39]="ROAR",   [40]="ROAR",
    },
    [8] = {
        [1]="CONGRATS",[2]="SING",     [3]="CONGRATS",[4]="SING",    [5]="SING",     [6]="SING",    [7]="DANCE",   [8]="CHEER",   [9]="SING",    [10]="VIOLIN",
        [11]="APPLAUD",[12]="CHEER",   [13]="CHEER",  [14]="DANCE",  [15]="SING",    [16]="DANCE",  [17]="ROAR",   [18]="ROAR",   [19]="CHEER",  [20]="ROAR",
        [21]="DANCE",  [22]="ROAR",    [23]="SING",   [24]="APPLAUD",[25]="DANCE",   [26]="CONGRATS",[27]="CHEER", [28]="CHEER",  [29]="CHEER",  [30]="SING",
        [31]="SING",   [32]="SING",    [33]="ROAR",   [34]="SING",   [35]="CHEER",   [36]="CHEER",  [37]="SING",   [38]="SING",   [39]="CHEER",  [40]="VIOLIN",
    },
    [9] = {
        [1]="DANCE",   [2]="APPLAUD",  [3]="CONGRATS",[4]="ROAR",    [5]="VIOLIN",   [6]="APPLAUD", [7]="DANCE",   [8]="PLACEHOLDER",[9]="ROAR",  [10]="SING",
        [11]="APPLAUD",[12]="DANCE",   [13]="CONGRATS",[14]="ROAR",  [15]="CHEER",   [16]="DANCE",  [17]="CHEER",  [18]="APPLAUD",[19]="SING",   [20]="ROAR",
        [21]="SING",   [22]="SING",    [23]="CONGRATS",[24]="CHEER", [25]="SING",    [26]="APPLAUD",[27]="SING",   [28]="SING",   [29]="ROAR",   [30]="DANCE",
        [31]="CONGRATS",[32]="ROAR",  [33]="CONGRATS",[34]="DANCE",  [35]="CONGRATS",[36]="ROAR",   [37]="SING",   [38]="CHEER",  [39]="CONGRATS",[40]="APPLAUD",
    },
    [10] = {
        [1]="SING",    [2]="DANCE",    [3]="ROAR",    [4]="VIOLIN",  [5]="DANCE",    [6]="ROAR",    [7]="CHEER",   [8]="VIOLIN",  [9]="VIOLIN",  [10]="DANCE",
        [11]="APPLAUD",[12]="CHEER",   [13]="CHEER",  [14]="CHEER",  [15]="CHEER",   [16]="SING",   [17]="DANCE",  [18]="ROAR",   [19]="CHEER",  [20]="ROAR",
        [21]="CHEER",  [22]="CHEER",   [23]="CHEER",  [24]="DANCE",  [25]="CHEER",   [26]="CONGRATS",[27]="SING",  [28]="CHEER",  [29]="SING",   [30]="VIOLIN",
        [31]="SING",   [32]="APPLAUD", [33]="SING",   [34]="DANCE",  [35]="CHEER",   [36]="VIOLIN", [37]="ROAR",   [38]="SING",   [39]="CHEER",  [40]="APPLAUD",
    },
    [11] = {
        [1]="ROAR",    [2]="ROAR",     [3]="VIOLIN",  [4]="CHEER",   [5]="ROAR",     [6]="DANCE",   [7]="CONGRATS",[8]="VIOLIN",  [9]="VIOLIN",  [10]="DANCE",
        [11]="CONGRATS",[12]="APPLAUD",[13]="DANCE",  [14]="ROAR",   [15]="APPLAUD", [16]="SING",   [17]="CHEER",  [18]="SING",   [19]="APPLAUD",[20]="APPLAUD",
        [21]="ROAR",   [22]="SING",    [23]="APPLAUD",[24]="DANCE",  [25]="CHEER",   [26]="VIOLIN", [27]="SING",   [28]="CHEER",  [29]="ROAR",   [30]="CHEER",
        [31]="ROAR",   [32]="DANCE",   [33]="CHEER",  [34]="ROAR",   [35]="CONGRATS",[36]="VIOLIN", [37]="CONGRATS",[38]="CONGRATS",[39]="VIOLIN",[40]="CHEER",
    },
    [12] = {
        [1]="ROAR",    [2]="SING",     [3]="VIOLIN",  [4]="DANCE",   [5]="SING",     [6]="VIOLIN",  [7]="ROAR",    [8]="DANCE",   [9]="CONGRATS",[10]="CHEER",
        [11]="ROAR",   [12]="SING",    [13]="VIOLIN", [14]="SING",   [15]="ROAR",    [16]="ROAR",   [17]="VIOLIN", [18]="SING",   [19]="APPLAUD",[20]="VIOLIN",
        [21]="SING",   [22]="CONGRATS",[23]="APPLAUD",[24]="APPLAUD",[25]="APPLAUD", [26]="PLACEHOLDER",[27]="DANCE",[28]="VIOLIN",[29]="DANCE",  [30]="CHEER",
        [31]="SING",   [32]="CHEER",   [33]="SING",   [34]="CONGRATS",[35]="ROAR",  [36]="DANCE",  [37]="CHEER",  [38]="APPLAUD",[39]="CHEER",  [40]="DANCE",
    },
    [13] = {
        [1]="SING",    [2]="DANCE",    [3]="CHEER",   [4]="SING",    [5]="ROAR",     [6]="ROAR",    [7]="CHEER",   [8]="VIOLIN",  [9]="SING",    [10]="SING",
        [11]="ROAR",   [12]="SING",    [13]="SING",   [14]="CHEER",  [15]="APPLAUD", [16]="ROAR",   [17]="CHEER",  [18]="ROAR",   [19]="DANCE",  [20]="ROAR",
        [21]="APPLAUD",[22]="ROAR",    [23]="ROAR",   [24]="CHEER",  [25]="SING",    [26]="SING",   [27]="SING",   [28]="SING",   [29]="ROAR",   [30]="CHEER",
        [31]="ROAR",   [32]="ROAR",    [33]="SING",   [34]="DANCE",  [35]="SING",    [36]="APPLAUD",[37]="DANCE",  [38]="ROAR",   [39]="APPLAUD",[40]="CHEER",
    },
    [14] = {
        [1]="APPLAUD", [2]="SING",     [3]="ROAR",    [4]="CONGRATS",[5]="DANCE",    [6]="CHEER",   [7]="APPLAUD", [8]="DANCE",   [9]="APPLAUD", [10]="DANCE",
        [11]="ROAR",   [12]="ROAR",    [13]="CHEER",  [14]="CHEER",  [15]="SING",    [16]="APPLAUD",[17]="SING",   [18]="APPLAUD",[19]="ROAR",   [20]="ROAR",
        [21]="SING",   [22]="CHEER",   [23]="CHEER",  [24]="DANCE",  [25]="ROAR",    [26]="APPLAUD",[27]="APPLAUD",[28]="ROAR",   [29]="DANCE",  [30]="ROAR",
        [31]="ROAR",   [32]="SING",    [33]="ROAR",   [34]="DANCE",  [35]="DANCE",   [36]="APPLAUD",[37]="APPLAUD",[38]="CHEER",  [39]="ROAR",   [40]="APPLAUD",
    },
    [15] = {
        [1]="APPLAUD", [2]="ROAR",     [3]="VIOLIN",  [4]="CHEER",   [5]="APPLAUD",  [6]="SING",    [7]="APPLAUD", [8]="SING",    [9]="CHEER",   [10]="DANCE",
        [11]="CONGRATS",[12]="DANCE",  [13]="SING",   [14]="VIOLIN", [15]="SING",    [16]="CHEER",  [17]="CHEER",  [18]="DANCE",  [19]="SING",   [20]="SING",
        [21]="SING",   [22]="ROAR",    [23]="SING",   [24]="APPLAUD",[25]="ROAR",    [26]="SING",   [27]="APPLAUD",[28]="ROAR",   [29]="ROAR",   [30]="CHEER",
        [31]="SING",   [32]="APPLAUD", [33]="ROAR",   [34]="APPLAUD",[35]="ROAR",    [36]="ROAR",   [37]="APPLAUD",[38]="DANCE",  [39]="SING",   [40]="VIOLIN",
    },
    [16] = {
        [1]="CONGRATS",[2]="ROAR",     [3]="ROAR",    [4]="DANCE",   [5]="VIOLIN",   [6]="CHEER",   [7]="SING",    [8]="ROAR",    [9]="SING",    [10]="DANCE",
        [11]="DANCE",  [12]="APPLAUD", [13]="CHEER",  [14]="DANCE",  [15]="CHEER",   [16]="CHEER",  [17]="SING",   [18]="CHEER",  [19]="APPLAUD",[20]="VIOLIN",
        [21]="CHEER",  [22]="SING",    [23]="APPLAUD",[24]="DANCE",  [25]="CHEER",   [26]="ROAR",   [27]="APPLAUD",[28]="VIOLIN", [29]="SING",   [30]="SING",
        [31]="VIOLIN", [32]="ROAR",    [33]="CONGRATS",[34]="DANCE", [35]="DANCE",   [36]="CHEER",  [37]="DANCE",  [38]="APPLAUD",[39]="CHEER",  [40]="APPLAUD",
    },
    [17] = {
        [1]="SING",    [2]="DANCE",    [3]="CHEER",   [4]="CHEER",   [5]="CHEER",    [6]="DANCE",   [7]="VIOLIN",  [8]="ROAR",    [9]="APPLAUD", [10]="SING",
        [11]="SING",   [12]="CHEER",   [13]="SING",   [14]="VIOLIN", [15]="APPLAUD", [16]="CONGRATS",[17]="PLACEHOLDER",[18]="ROAR",[19]="DANCE", [20]="ROAR",
        [21]="APPLAUD",[22]="APPLAUD", [23]="SING",   [24]="CHEER",  [25]="CHEER",   [26]="SING",   [27]="VIOLIN", [28]="APPLAUD",[29]="ROAR",   [30]="ROAR",
        [31]="CONGRATS",[32]="CHEER",  [33]="APPLAUD",[34]="CHEER",  [35]="VIOLIN",  [36]="ROAR",   [37]="CHEER",  [38]="CONGRATS",[39]="CONGRATS",[40]="DANCE",
    },
    [18] = {
        [1]="SING",    [2]="VIOLIN",   [3]="CHEER",   [4]="SING",    [5]="ROAR",     [6]="ROAR",    [7]="CHEER",   [8]="ROAR",    [9]="DANCE",   [10]="DANCE",
        [11]="PLACEHOLDER",[12]="APPLAUD",[13]="VIOLIN",[14]="CONGRATS",[15]="DANCE",[16]="CHEER",  [17]="CHEER",  [18]="SING",   [19]="CHEER",  [20]="SING",
        [21]="SING",   [22]="ROAR",    [23]="CHEER",  [24]="SING",   [25]="ROAR",    [26]="CHEER",  [27]="DANCE",  [28]="DANCE",  [29]="DANCE",  [30]="ROAR",
        [31]="VIOLIN", [32]="APPLAUD", [33]="VIOLIN", [34]="CHEER",  [35]="VIOLIN",  [36]="SING",   [37]="CHEER",  [38]="CONGRATS",[39]="CHEER",  [40]="ROAR",
    },
    [19] = {
        [1]="VIOLIN",  [2]="APPLAUD",  [3]="APPLAUD", [4]="SING",    [5]="APPLAUD",  [6]="CONGRATS",[7]="VIOLIN",  [8]="SING",    [9]="DANCE",   [10]="CHEER",
        [11]="SING",   [12]="APPLAUD", [13]="SING",   [14]="SING",   [15]="VIOLIN",  [16]="DANCE",  [17]="APPLAUD",[18]="DANCE",  [19]="APPLAUD",[20]="ROAR",
        [21]="CHEER",  [22]="SING",    [23]="VIOLIN", [24]="CHEER",  [25]="CHEER",   [26]="DANCE",  [27]="CHEER",  [28]="CHEER",  [29]="ROAR",   [30]="SING",
        [31]="CHEER",  [32]="CHEER",   [33]="APPLAUD",[34]="SING",   [35]="ROAR",    [36]="ROAR",   [37]="CHEER",  [38]="DANCE",  [39]="CONGRATS",[40]="VIOLIN",
    },
    [20] = {
        [1]="SING",    [2]="CHEER",    [3]="DANCE",   [4]="ROAR",    [5]="SING",     [6]="APPLAUD", [7]="SING",    [8]="APPLAUD", [9]="CONGRATS",[10]="APPLAUD",
        [11]="SING",   [12]="DANCE",   [13]="VIOLIN", [14]="SING",   [15]="ROAR",    [16]="VIOLIN", [17]="APPLAUD",[18]="DANCE",  [19]="VIOLIN", [20]="DANCE",
        [21]="DANCE",  [22]="SING",    [23]="SING",   [24]="DANCE",  [25]="APPLAUD", [26]="ROAR",   [27]="CHEER",  [28]="DANCE",  [29]="CONGRATS",[30]="APPLAUD",
        [31]="PLACEHOLDER",[32]="ROAR",[33]="APPLAUD",[34]="SING",   [35]="ROAR",    [36]="DANCE",  [37]="CONGRATS",[38]="ROAR",  [39]="DANCE",  [40]="APPLAUD",
    },
    [21] = {
        [1]="APPLAUD", [2]="CONGRATS", [3]="CONGRATS",[4]="DANCE",   [5]="APPLAUD",  [6]="CONGRATS",[7]="CONGRATS",[8]="CONGRATS",[9]="DANCE",   [10]="ROAR",
        [11]="ROAR",   [12]="DANCE",   [13]="SING",   [14]="CONGRATS",[15]="ROAR",   [16]="VIOLIN", [17]="SING",   [18]="DANCE",  [19]="CONGRATS",[20]="SING",
        [21]="APPLAUD",[22]="CHEER",   [23]="CHEER",  [24]="APPLAUD",[25]="APPLAUD", [26]="VIOLIN", [27]="DANCE",  [28]="APPLAUD",[29]="ROAR",   [30]="CHEER",
        [31]="DANCE",  [32]="ROAR",    [33]="VIOLIN", [34]="CHEER",  [35]="CONGRATS",[36]="APPLAUD",[37]="ROAR",   [38]="VIOLIN", [39]="SING",   [40]="CHEER",
    },
    [22] = {
        [1]="VIOLIN",  [2]="ROAR",     [3]="ROAR",    [4]="ROAR",    [5]="SING",     [6]="CHEER",   [7]="CHEER",   [8]="CHEER",   [9]="SING",    [10]="ROAR",
        [11]="VIOLIN", [12]="CHEER",   [13]="ROAR",   [14]="DANCE",  [15]="APPLAUD", [16]="CHEER",  [17]="APPLAUD",[18]="ROAR",   [19]="DANCE",  [20]="DANCE",
        [21]="CHEER",  [22]="SING",    [23]="DANCE",  [24]="APPLAUD",[25]="CHEER",   [26]="SING",   [27]="DANCE",  [28]="CHEER",  [29]="VIOLIN", [30]="DANCE",
        [31]="CHEER",  [32]="CHEER",   [33]="CHEER",  [34]="SING",   [35]="DANCE",   [36]="ROAR",   [37]="DANCE",  [38]="CHEER",  [39]="DANCE",  [40]="CHEER",
    },
    [23] = {
        [1]="CONGRATS",[2]="SING",     [3]="CONGRATS",[4]="APPLAUD", [5]="ROAR",     [6]="ROAR",    [7]="CONGRATS",[8]="DANCE",   [9]="VIOLIN",  [10]="APPLAUD",
        [11]="DANCE",  [12]="SING",    [13]="SING",   [14]="APPLAUD",[15]="SING",    [16]="CONGRATS",[17]="CHEER", [18]="VIOLIN", [19]="SING",   [20]="DANCE",
        [21]="VIOLIN", [22]="APPLAUD", [23]="CHEER",  [24]="ROAR",   [25]="VIOLIN",  [26]="APPLAUD",[27]="VIOLIN", [28]="PLACEHOLDER",[29]="APPLAUD",[30]="SING",
        [31]="DANCE",  [32]="CHEER",   [33]="ROAR",   [34]="VIOLIN", [35]="APPLAUD", [36]="ROAR",   [37]="APPLAUD",[38]="ROAR",   [39]="DANCE",  [40]="APPLAUD",
    },
    [24] = {
        [1]="APPLAUD", [2]="APPLAUD",  [3]="APPLAUD", [4]="SING",    [5]="DANCE",    [6]="APPLAUD", [7]="ROAR",    [8]="SING",    [9]="DANCE",   [10]="CONGRATS",
        [11]="APPLAUD",[12]="DANCE",   [13]="ROAR",   [14]="ROAR",   [15]="CHEER",   [16]="SING",   [17]="CHEER",  [18]="SING",   [19]="CHEER",  [20]="APPLAUD",
        [21]="CONGRATS",[22]="DANCE",  [23]="SING",   [24]="SING",   [25]="ROAR",    [26]="CHEER",  [27]="ROAR",   [28]="CONGRATS",[29]="CHEER",  [30]="SING",
        [31]="CHEER",  [32]="CHEER",   [33]="SING",   [34]="DANCE",  [35]="ROAR",    [36]="CONGRATS",[37]="APPLAUD",[38]="APPLAUD",[39]="ROAR",   [40]="CHEER",
    },
    [25] = {
        [1]="DANCE",   [2]="APPLAUD",  [3]="ROAR",    [4]="VIOLIN",  [5]="APPLAUD",  [6]="SING",    [7]="SING",    [8]="CONGRATS",[9]="CHEER",   [10]="CONGRATS",
        [11]="APPLAUD",[12]="CHEER",   [13]="APPLAUD",[14]="APPLAUD",[15]="CHEER",   [16]="ROAR",   [17]="ROAR",   [18]="SING",   [19]="ROAR",   [20]="DANCE",
        [21]="DANCE",  [22]="DANCE",   [23]="CHEER",  [24]="DANCE",  [25]="CONGRATS",[26]="SING",   [27]="APPLAUD",[28]="APPLAUD",[29]="SING",   [30]="CHEER",
        [31]="SING",   [32]="DANCE",   [33]="DANCE",  [34]="APPLAUD",[35]="CHEER",   [36]="SING",   [37]="DANCE",  [38]="CHEER",  [39]="VIOLIN", [40]="SING",
    },
}

-- =============================================
-- MODULE STATE
-- =============================================
local bh_active  = false   -- set true after ADDON_LOADED check passes
local bh_state   = {
    currentMeasure   = nil,
    overrides        = {},
    measureLocked    = false,
    measureStarted   = false,
    countdownEndTime = nil,
    danceMoving      = false,
    danceComplete    = false,
    closed           = false,  -- player manually closed popup this session
}
local bh_ui      = {}
local bh_frame   = CreateFrame("Frame")

-- =============================================
-- HELPERS
-- =============================================
local function BH_IsTargetFlame()
    local id = UnitCreatureID("target")
    return id and tonumber(id) == BH_NPC_ID
end

local function BH_IsHallowfall()
    return C_Map.GetBestMapForUnit("player") == BH_ZONE_ID
end

local function BH_GetRaidSlot()
    local members = {}
    if IsInRaid() then
        for i = 1, 40 do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name then
                table.insert(members, {
                    subgroup = subgroup or 9,
                    raidIndex = i,
                    unit = "raid" .. i,
                })
            end
        end
    elseif IsInGroup() then
        local num = GetNumGroupMembers()
        for i = 1, num do
            local unit = (i == num) and "player" or ("party" .. i)
            local name = UnitFullName(unit)
            if name then
                table.insert(members, {
                    subgroup = 1,
                    raidIndex = i,
                    unit = unit,
                })
            end
        end
    else
        return 1  -- solo testing: treat as slot 1
    end
    table.sort(members, function(a, b)
        if a.subgroup ~= b.subgroup then return a.subgroup < b.subgroup end
        return a.raidIndex < b.raidIndex
    end)
    for visualSlot, member in ipairs(members) do
        if member.unit and UnitIsUnit(member.unit, "player") then
            return visualSlot
        end
    end
    return nil
end

local function BH_GetEmote(measure, slot)
    if not measure or not slot then return "PLACEHOLDER" end
    local ov = bh_state.overrides[measure]
    if ov and ov[slot] then return ov[slot] end
    local row = BH_MEASURES[measure]
    return (row and row[slot]) or "PLACEHOLDER"
end

-- =============================================
-- UI
-- =============================================
local function BH_UpdatePopup()
    if not bh_ui.frame then return end

    -- Hide (and reset closed flag) when no longer targeting the NPC
    if not BH_IsTargetFlame() then
        if bh_ui.frame:IsShown() then bh_ui.frame:Hide() end
        bh_state.closed = false
        return
    end

    -- Player manually closed it this targeting session
    if bh_state.closed then return end

    if not bh_ui.frame:IsShown() then
        bh_ui.frame:Show()
    end

    local slot    = BH_GetRaidSlot()
    local token   = BH_GetEmote(bh_state.currentMeasure, slot)
    local emote   = BH_EMOTES[token] or BH_EMOTES.PLACEHOLDER
    local measure = bh_state.currentMeasure

    -- Measure / slot labels
    bh_ui.measureText:SetText(measure and ("Measure " .. measure) or "Waiting for measure")
    bh_ui.slotText:SetText(slot and ("Raid slot " .. slot) or "No raid slot")

    -- Modified indicator
    local isOverridden = measure and slot and bh_state.overrides[measure] and bh_state.overrides[measure][slot]
    bh_ui.modifiedText:SetShown(isOverridden and true or false)

    -- Button state
    local btn = bh_ui.button
    if bh_state.measureLocked then
        btn:SetText("Done!")
        btn:SetEnabled(false)
        btn:SetAlpha(0.5)
    elseif not measure then
        btn:SetText("Waiting...")
        btn:SetEnabled(false)
        btn:SetAlpha(0.6)
    elseif not slot then
        btn:SetText("No raid slot")
        btn:SetEnabled(false)
        btn:SetAlpha(0.6)
    elseif token == "PLACEHOLDER" then
        btn:SetText("No assignment")
        btn:SetEnabled(false)
        btn:SetAlpha(0.6)
    elseif not bh_state.measureStarted then
        if bh_state.countdownEndTime then
            local remaining = bh_state.countdownEndTime - GetTime()
            if remaining > 0 then
                btn:SetText(string.format("Get ready... %d", math.ceil(remaining)))
                btn:SetEnabled(false)
                btn:SetAlpha(0.8)
            else
                bh_state.measureStarted = true
                bh_state.countdownEndTime = nil
                btn:SetText(emote.display)
                btn:SetEnabled(true)
                btn:SetAlpha(1)
            end
        else
            btn:SetText(emote.display .. " (waiting)")
            btn:SetEnabled(false)
            btn:SetAlpha(0.6)
        end
    else
        btn:SetText(emote.display)
        btn:SetEnabled(true)
        btn:SetAlpha(1)
    end
end

local function BH_PressEmote()
    local slot    = BH_GetRaidSlot()
    local measure = bh_state.currentMeasure

    if not slot or not measure then
        BH_UpdatePopup()
        return
    end

    -- Allow pressing if countdown expired but flag not yet set
    if not bh_state.measureStarted then
        if bh_state.countdownEndTime and (bh_state.countdownEndTime - GetTime()) <= 0 then
            bh_state.measureStarted = true
            bh_state.countdownEndTime = nil
        else
            return
        end
    end

    if bh_state.measureLocked then return end

    local token = BH_GetEmote(measure, slot)
    local emote = BH_EMOTES[token]
    if not emote or not emote.command then return end

    DoEmote(emote.command)
    bh_state.measureLocked = true

    if IsInGroup() then
        local channel = IsInRaid() and "RAID" or "PARTY"
        C_ChatInfo.SendAddonMessage(BH_PREFIX, string.format("PERFORMED:%d:%d", measure, slot), channel)
    end

    -- DANCE requires move-then-stop; register movement tracking
    if token == "DANCE" then
        bh_frame:RegisterEvent("PLAYER_STARTED_MOVING")
        bh_frame:RegisterEvent("PLAYER_STOPPED_MOVING")
    end

    BH_UpdatePopup()
end

local function BH_CreatePopup()
    local f = CreateFrame("Frame", "SecretChecklistBeledarHelper", UIParent, "BackdropTemplate")
    f:SetSize(240, 145)
    f:SetPoint("CENTER", UIParent, "CENTER", 360, -120)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    f:Hide()
    bh_ui.frame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("Beledar Assignment")

    local sourceText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sourceText:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -10)
    sourceText:SetText("via SecretChecklist")

    local measureText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    measureText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    measureText:SetText("Waiting for measure")
    bh_ui.measureText = measureText

    local slotText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slotText:SetPoint("TOP", measureText, "BOTTOM", 0, -6)
    slotText:SetText("No raid slot")
    bh_ui.slotText = slotText

    local modifiedText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modifiedText:SetPoint("TOP", slotText, "BOTTOM", 0, -2)
    modifiedText:SetText("|cffffff00(Modified by leader)|r")
    modifiedText:Hide()
    bh_ui.modifiedText = modifiedText

    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(180, 40)
    btn:SetPoint("BOTTOM", 0, 12)
    btn:SetScript("OnClick", BH_PressEmote)
    btn:SetText("Waiting...")
    bh_ui.button = btn

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function()
        bh_state.closed = true
        f:Hide()
    end)

    BH_UpdatePopup()
end

-- =============================================
-- MESSAGE HANDLER
-- =============================================
local function BH_HandleMessage(message)
    local parts = { strsplit(":", message) }
    local action = parts[1]

    if action == "MEASURE" then
        local n = tonumber(parts[2])
        if n == 0 then n = nil end
        bh_state.currentMeasure   = n
        bh_state.measureLocked    = false
        bh_state.measureStarted   = false
        bh_state.countdownEndTime = nil
        bh_state.danceMoving      = false
        bh_state.danceComplete    = false
        bh_frame:UnregisterEvent("PLAYER_STARTED_MOVING")
        bh_frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
        BH_UpdatePopup()

    elseif action == "OVERRIDE" then
        local measure = tonumber(parts[2])
        local slot    = tonumber(parts[3])
        local token   = parts[4]
        if measure and slot and token then
            bh_state.overrides[measure] = bh_state.overrides[measure] or {}
            bh_state.overrides[measure][slot] = token
            BH_UpdatePopup()
        end

    elseif action == "CLEAR_OVERRIDES" then
        bh_state.overrides = {}
        BH_UpdatePopup()

    elseif action == "CLEAR_MEASURE" then
        local m = tonumber(parts[2])
        if m then
            bh_state.overrides[m] = nil
            BH_UpdatePopup()
        end

    elseif action == "RETRY" then
        local m = tonumber(parts[2])
        if m == bh_state.currentMeasure then
            bh_state.measureLocked    = false
            bh_state.measureStarted   = false
            bh_state.countdownEndTime = nil
            bh_state.danceMoving      = false
            bh_state.danceComplete    = false
            bh_frame:UnregisterEvent("PLAYER_STARTED_MOVING")
            bh_frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
            BH_UpdatePopup()
        end

    elseif action == "PING" then
        -- Respond to leader version checks so SC users show as "SC-x.x.x" in
        -- BeledarOrchestra's version grid rather than "?" (no addon).
        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local ver = C_AddOns.GetAddOnMetadata("SecretChecklist", "Version") or "?"
            C_ChatInfo.SendAddonMessage(BH_PREFIX, "PONG:SC-" .. ver, channel)
        end

    elseif action == "START" then
        local m   = tonumber(parts[2])
        local dur = tonumber(parts[3]) or 10
        if m == bh_state.currentMeasure then
            bh_state.countdownEndTime = GetTime() + dur
            bh_state.measureStarted   = false
            bh_state.measureLocked    = false
            bh_state.danceMoving      = false
            bh_state.danceComplete    = false
            bh_frame:UnregisterEvent("PLAYER_STARTED_MOVING")
            bh_frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
            BH_UpdatePopup()
        end
    end
end

-- =============================================
-- EVENT HANDLER
-- =============================================
bh_frame:RegisterEvent("ADDON_LOADED")

bh_frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        -- If BeledarOrchestra loads (before or after us) disable the helper
        if name == "BeledarOrchestra" then
            bh_active = false
            bh_frame:UnregisterAllEvents()
            if bh_ui.frame then bh_ui.frame:Hide() end
            return
        end

        if name ~= "SecretChecklist" then return end

        -- BeledarOrchestra might already be loaded
        if C_AddOns.IsAddOnLoaded("BeledarOrchestra") then return end

        bh_active = true
        C_ChatInfo.RegisterAddonMessagePrefix(BH_PREFIX)
        BH_CreatePopup()

        bh_frame:RegisterEvent("CHAT_MSG_ADDON")
        bh_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        bh_frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        bh_frame:RegisterEvent("UNIT_AURA")
        bh_frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        bh_frame:RegisterEvent("ZONE_CHANGED")
        bh_frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        return
    end

    if not bh_active then return end

    if event == "CHAT_MSG_ADDON" then
        local prefix, message = ...
        if prefix ~= BH_PREFIX then return end
        BH_HandleMessage(message)

    elseif event == "PLAYER_TARGET_CHANGED" then
        BH_UpdatePopup()

    elseif event == "GROUP_ROSTER_UPDATE" then
        BH_UpdatePopup()

    elseif event == "UNIT_AURA" then
        -- No aura validation needed (we don't have the leader UI), ignore

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        if not BH_IsHallowfall() then
            if bh_ui.frame then bh_ui.frame:Hide() end
        end

    elseif event == "PLAYER_STARTED_MOVING" then
        -- DANCE step 1: broadcast that we started moving
        if bh_state.measureLocked and not bh_state.danceMoving then
            local slot    = BH_GetRaidSlot()
            local measure = bh_state.currentMeasure
            if slot and measure and BH_GetEmote(measure, slot) == "DANCE" then
                bh_state.danceMoving = true
                if IsInGroup() then
                    local channel = IsInRaid() and "RAID" or "PARTY"
                    C_ChatInfo.SendAddonMessage(BH_PREFIX, string.format("DANCE_MOVING:%d:%d", measure, slot), channel)
                end
            end
        end

    elseif event == "PLAYER_STOPPED_MOVING" then
        -- DANCE step 2: broadcast that we stopped moving
        if bh_state.measureLocked and bh_state.danceMoving and not bh_state.danceComplete then
            local slot    = BH_GetRaidSlot()
            local measure = bh_state.currentMeasure
            if slot and measure and BH_GetEmote(measure, slot) == "DANCE" then
                bh_state.danceComplete = true
                if IsInGroup() then
                    local channel = IsInRaid() and "RAID" or "PARTY"
                    C_ChatInfo.SendAddonMessage(BH_PREFIX, string.format("DANCE_STOPPED:%d:%d", measure, slot), channel)
                end
                bh_frame:UnregisterEvent("PLAYER_STARTED_MOVING")
                bh_frame:UnregisterEvent("PLAYER_STOPPED_MOVING")
            end
        end
    end
end)

-- OnUpdate: tick countdown and refresh button label
bh_frame:SetScript("OnUpdate", function(_, elapsed)
    if not bh_active then return end
    if not (bh_ui.frame and bh_ui.frame:IsShown()) then return end
    if not bh_state.countdownEndTime then return end
    if bh_state.measureStarted then return end

    local remaining = bh_state.countdownEndTime - GetTime()
    if remaining <= 0 then
        bh_state.measureStarted   = true
        bh_state.countdownEndTime = nil
    end
    BH_UpdatePopup()
end)
