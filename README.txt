SecretChecklist

Commands:
  /secrets         -> prints collected/missing for the configured list
  /secrets verbose -> also prints short failure reasons (e.g., "not cached")
  /secrets quiet   -> turns verbose off
  /secrets where   -> explains where the report is saved on disk
  /secrets wait    -> waits 2 seconds then runs (helps if journals are still loading)
  /secrets ui      -> opens the journal-style UI list (icons greyed if missing)

Copying the results (no chat copy needed):
  1) Run /secrets in game
  2) /logout (or fully exit WoW) so SavedVariables are written
  3) Open: WTF/Account/<YourAccount>/SavedVariables/SecretChecklist.lua
     Look for SecretChecklistDB.lastReport.lines

Edit the list:
  Open SecretChecklist.lua and edit SC.entries.

Notes:
  - "manual" entries can’t be auto-checked unless you add an achievement/quest/spell/item ID that maps to something trackable.
  - Some checks depend on collection data being loaded/cached; if something shows [?] unexpectedly, open the relevant Collections tab once (Toys/Mounts/Pets) and rerun.
  - Some list entries are item names (e.g. “Blanchy’s Reins”) while Collections shows the mount/pet name (“Blanchy”). The addon includes name fallbacks for those.
