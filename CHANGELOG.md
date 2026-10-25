# Changelog

## 2.1.1

- **SecretChecklist is now fully translated into Russian** — every button,
  setting and message as well as every guide. The last three strings were the
  ones shown at a merchant in Nazjatar, about whether the Crimson Tidestallion
  is in stock. Thanks again to ZamestoTV.

## 2.1.0

### The guides are now fully available in Russian

Every one of the 815 step instructions, notes and descriptions is translated —
the walkthroughs, not just the buttons and menus. On a Russian client the whole
addon now reads in Russian.

That is months of work by **ZamestoTV**, who also translated the interface and
reported most of the gaps that got fixed along the way. Thank you.

If you play in another language and fancy doing the same, the guide content is a
single file and a partial translation is genuinely useful — anything unfinished
simply falls back to English. See the README.

## 2.0.9

### Fixed

- **Updated for patch 12.1.5**, so the addon is no longer flagged out of date.
  12.1.7 on the PTR is supported too.

### New

- **The Russian guides are nearly complete** — 739 of 815 step instructions, up
  from around 300. Thanks again to ZamestoTV. Anything still untranslated reads
  in English.

### Under the hood

- Under EllesmereUI, the addon now tells EUI which tab is selected rather than
  letting it work that out. No visible change today; it prevents the tabs all
  looking unselected if EUI's own tab handling shifts underneath us.

## 2.0.8

### New

- **J'imothy has been solved, and the guide is in.** Find an Ensorcelled Cryptid
  in Silvermoon City, strip its 100 stacks of Barrier Integrity while dodging the
  arcane circles, then free him and take the Stubby Whistle. Three confirmed
  spawn points are on the first step. Anyone can help strip stacks, and everyone
  present gets a whistle.
- **The guides are being translated into Russian.** A first pass covering around
  300 of the step instructions is in, thanks again to ZamestoTV. Anything not yet
  translated still reads in English, so nothing is missing in the meantime.

### Fixed

- Under EllesmereUI, the gold border on collected icons is drawn a single screen
  pixel wide, so it no longer varies from icon to icon at some UI scales.

## 2.0.7

### Fixed

- **"A Safer Place" never counted as done on Horde.** The step only knew the
  Alliance version of the quest, so Mrrl's unlock read as incomplete for every
  Horde character who had already done it.
- **The search box overlapped the counters and the portrait** on the default
  look. It has moved into the list column.
- **The Filter button sometimes drew as bare text** with no button behind it.
- Item steps read differently from one session to the next, depending on what
  your client happened to have loaded. They are consistent now.
- The progress counters sit together in the middle rather than at opposite ends
  of the window, and the Filter button no longer shows a number that counted up
  as you narrowed the filter.
- The list scrollbar now reflects how much of the list you are seeing.

### New

- **Search by type.** Typing "pets" or "mounts" in the Guides search now shows
  that type, instead of everything whose notes happen to mention the word.
- **Item steps are clickable.** Substeps that name an item are coloured by its
  quality, show its tooltip on hover, and shift-click drops it into chat. Shift
  now works on the Overview too, alongside Ctrl.
- Opening a merchant in Nazjatar now says whether the Crimson Tidestallion is
  stocked that day, and reminds you to equip the Azsh'ari Stormsurger Cape if it
  is not on — without it the special stock is not listed at all.

## 2.0.6

- **Slitherfang added** — the first secret of patch 12.1, with the full
  walkthrough for the five-player ritual in Mythic Altar of Fangs.
- **J'imothy added.** Blizzard has confirmed the raccoon is a secret pet, but
  nobody has worked out how to get him yet. He is listed with what is known so
  far, and will start tracking properly the moment that changes.
- **Now requires patch 12.1.** Support for 12.0.7 has been dropped.

## 2.0.5

- **The Russian interface is now complete.** Every button, tab, tooltip and
  setting is translated — thanks again to ZamestoTV.

## 2.0.4

- **Mounts now use the name your Mount Journal shows.** On a non-English client
  they were the only category left in English — pets, toys and appearances were
  already translated. A few English names change as a result (Blanchy's Reins is
  now Sinrunner Blanchy), and the Overview sorts by the new names.
- **The theme and Guides tab style settings are translatable**, including the
  individual options. They were English on every client before.
- **The addon's website and bug-report links now work.** Both pointed at a
  repository that no longer exists, so anyone trying to report something from
  the CurseForge or Wago page hit a dead end.
- **The "a group member has a newer version" notice works again.** It had been
  misreading its own version number since it was added, so on most releases it
  simply never fired.

Thanks to ZamestoTV for the Russian translation and for reporting the
localisation gaps, and to claytonkimber for the dead links.

## 2.0.3

- **Radiant Singer** now says up front that you need the Gift of Oddsight buff:
  without it the Divine Flame cannot be targeted at all. The raid-setup step
  explains where the buff comes from and that only one person in the raid needs
  to own the item.

## 2.0.2

- **The Beledar assignment popup now matches your UI theme** instead of using
  a plain tooltip background, and follows ElvUI or EllesmereUI when you use
  them.
- Tidier layout: the title no longer overlaps the "via SecretChecklist" label,
  the close button sits properly in the header, and the emote button is easier
  to hit.
- The popup remembers where you drag it.

## 2.0.1

- **Fixed an error that fired every time you changed target**, introduced in
  2.0.0. It also tainted execution, which can cause problems in other addons
  and in Blizzard's own interface. Please update.

## 2.0.0

A large maintenance release. Everything below is something you can see or use.

### New

- **Search box in the Guides tab.** Finds a secret by its name, its zone, or
  anything mentioned in its steps — searching "Kosumoth" or "Tazavesh" works as
  well as searching the item name.
- **The whole Overview row is clickable**, not just the icon. Clicking a
  secret's name used to do nothing.
- **Checkmark and cross icons** for collected and missing, so status no longer
  depends on telling red from green.
- **The window remembers where you put it.** Dragging it worked before, but the
  position was forgotten on every reload.
- **EllesmereUI theme** now marks collected secrets with the same gold border
  the other themes use, instead of leaving them looking identical to missing
  ones.
- **Guide content can be translated**, not just the interface. Step
  instructions, notes and descriptions are all translatable now — see the
  README if you would like to help with a language.
- `/secrets help` lists every command, and `/secrets validate` checks the
  secret data for problems.

### Fixed

- **A Lua error on every login.** It also silently disabled the Beledar
  Orchestra helper entirely.
- **Browsing the checklist reset your Collections journal filters.** If you had
  the Mount Journal set to "Not Collected", paging through the Overview quietly
  cleared it.
- **Steps stayed red after you claimed the reward.** Pet, mount and appearance
  steps checked your bags for an item that is consumed the moment you use it —
  Unfazed Diver's final step, for one. Steps for equipped gear had the same
  problem: equipping the item made the step go red.
- **Achievement tooltips stuck on "Retrieving data".**
- **Step notes did not reopen** after collapsing and expanding the progress
  list, and took two clicks to close afterwards.
- **Steps with only a waypoint** were drawn with a large empty gap above the
  button.
- **The Guides tab style setting** was forgotten on every reload.
- **Setting a waypoint inside a dungeon** could throw an error if you do not
  have TomTom. It now explains itself instead. Steps with several waypoints say
  so rather than silently placing only the first.
- **The About tab's copy box** showed the Discord link even when you had
  clicked the Warcraft Secrets one.

### Under the hood

Faster to load and lighter on memory, especially the Guides tab, and a good
deal of old code removed. None of this changes how the addon behaves.

---

## 1.x

Older releases. These notes were written for maintainers rather than players,
and name the API calls and root causes behind each fix.

- **1.11.0**: Added an EllesmereUI theme built on EllesmereUI 8.6's public skinning API (`EllesmereUI.RegisterSkin`) — the window, tabs, buttons and toasts are painted by EUI itself and track the accent colour, window style and UI font set on your EUI profile, live. Theme colour entries may now be functions so a palette can resolve per read instead of being frozen at load; `ApplyTheme` no longer overwrites the saved theme when it falls back to Default because a host addon has not loaded yet (this previously erased the choice at every login). Also fixed `RefreshAlertTheme` never running — its guard referenced a local declared later in the file, so the name resolved to a nil global and existing toasts were never re-skinned on a theme change
- **1.10.1**: Fixed the Shu'halo Perspective painting re-firing its "Secret Collected" toast on zone transitions (an early `HOUSING_STORAGE_UPDATED` with `totalNumStored=0` produced a spurious missing→collected swing; a confirmed-collected housing snapshot is now sticky) and made step status housing-aware so the "Buy painting" step reads as done from housing storage rather than bags
- **1.10.0**: Added Unfazed Diver secret, fix housing ownership detection
- **1.9.13**: Updated toc for 12.0.7
- **1.9.12**: Updated waypoints for Crimson Tidestallion (faction based waypoints)
- **1.9.11**: Updated toc for 12.0.5
- **1.9.10**: Fixed Mind-Seeker tracking flags: added `mindSeeker = true` to Sun Darter Hatchling (#16) and Ensemble: Fashion of the Fanatic Felcyclist (#34); removed incorrect `mindSeeker = true` from Cartel Transmorpher (not part of the 34 tracked secrets)
- **1.9.9**: Improved Secrets of Azeroth completion reliability and step structure: (1) Bound Shadehound codex flow now nests "Buy Partial Rune Codex" + all three rune pages as substeps under the combine step so progression is grouped correctly in the UI; removed fragile parent `questID=63668` dependency and rely on resulting item progress (`Intact Rune Codex`) instead; (2) added achievement-criteria fallback support in step status checks (`achievementID` + `criteriaID`) to handle secret quests that do not always report as completed; applied to Whodunnit chain steps in Tricked-Out Thinking Cap (Secret 1-15), including Secret 2 (Tuskarr Ceremonial Spear), so criteria completion now marks steps done even when quest flags are inconsistent
- **1.9.8**: Fixed housing decor (Shu'halo Perspective Painting) flickering between collected/missing when entering or exiting instances (BG/raid/dungeon) — root cause was `entrySubtype=1` being ambiguous: it means both "genuinely unowned" AND "storage not loaded yet" since housing storage is lazy-loaded by the game and only populates on first housing catalog UI open; fixed with three cooperating changes: (1) `SC._housingStorageReady` flag — reset to `false` by `HOUSING_CATALOG_CATEGORY_UPDATED` (catalog rebuilding), set to `true` by `HOUSING_STORAGE_UPDATED` (ownership confirmed); `CheckEntry` now returns `nil` (unknown, no flicker) for `subtype=1` while not ready; (2) added `HOUSING_STORAGE_UPDATED` event alongside `HOUSING_STORAGE_ENTRY_UPDATED` so bulk storage reloads on zone transitions are captured; (3) proactively trigger storage load on every `PLAYER_ENTERING_WORLD` via `C_HousingCatalog.CreateCatalogSearcher().RunSearch()` (same technique as AllTheThings) so ownership data loads at login and after every instance exit without requiring the player to open the housing UI; also wrapped `GetCatalogEntryInfoByItem` in `pcall` to match HousingCompanion/ATT defensive pattern
- **1.9.7**: Fixed false "Secret Collected!" toast for Shu'halo Perspective Painting (and any housing decor) firing on every login — root cause was `HOUSING_CATALOG_CATEGORY_UPDATED` (a catalog-structure event, added in v1.9.4) triggering the alert snapshot diff before ownership data had merged, writing `snapshot=false`, then the real ownership arrival looked like a missing→collected transition; fixed by using `entrySubtype` from `GetCatalogEntryInfoByItem` as the sole ownership signal (`0/nil`→unknown, `1`→unowned, `2/3`→owned) so partially-loaded catalog data returns `nil` instead of `false`; split housing event handlers so `HOUSING_CATALOG_CATEGORY_UPDATED` only triggers a UI redraw (fixes the separate 5–10 min delay before owned items appear collected), while `HOUSING_STORAGE_ENTRY_UPDATED` and `HOUSE_DECOR_ADDED_TO_CHEST` exclusively drive the alert snapshot
- **1.9.6**: Phoenix Wishwing — steps 1–3 (Glittering Phoenix Ember, Inert Phoenix Ash, Sacred Phoenix Ash) are now substeps of step 4 (Get Phoenix Ash Talisman from Zektar); substep rows now automatically render as completed (green/dimmed) when their parent step is already marked done
- **1.9.5**: Fixed Wan'be's Buried Goods quest IDs — updated entry-level `questID` from placeholder `000` to `53657`; added per-step `questID`s for steps 1–4 (`53653`–`53656` sourced from AllTheThings); corrected step 5 `questID` from `52192` to `53657`
- **1.9.4**: Warbank item detection — pass `includeAccountBank` flag to all `C_Item.GetItemCount` calls and register `PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED` to refresh counts when the warbank opens; added `itemIDs` any-of support on steps so owning any listed item marks the step active; Blanchy Day 4 now merges Empty Bucket + Bucket of Clean Water into one step via `itemIDs`; fixed `elsif` typo in StepItemCount helper
- **1.9.3**: Added BeledarHelper — a lightweight BeledarOrchestra player client built into SecretChecklist; shows a popup with your assigned emote when targeting the Divine Flame of Beledar in Hallowfall; receives the leader's measure table and overrides via the `BO_DATASYNC` / `BeledarOrch` addon message protocol so only the raid leader needs BeledarOrchestra installed; responds to BO version checks (`PING`) reporting as `SC-x.x.x`; automatically disables itself if BeledarOrchestra is loaded
- **1.9.2**: Entry-level quest checks now use `IsQuestFlaggedCompletedOnAccount` (account-wide secret completion signal); substep/step checks keep `IsQuestFlaggedCompleted` (per-character progress tracking); `stepsOverrideOnDone` now defaults to `true` for all entries — set `stepsOverrideOnDone = false` on an entry to opt out; added Voldunai Revered reputation requirement step to Wan'be's Buried Goods; temporarily removed Wan'be's questID pending in-game verification
- **1.9.1**: Fixed collection status detection: `questID` is now checked first in all entry types before kind-specific API checks — secret quests are flagged on completion and are more reliable than `PlayerHasTransmog`/`GetItemInfo` which return `false` for ensemble container items; fixes `Ensemble: Fashion of the Fanatic Felcyclist` (and any other ensemble transmog) not marking as collected; corrected questID to 91636 for the ensemble entry
- **1.9.0**: Added Russian localisation (ru-RU, contributed by ZamestoTV); fixed `Ensemble: Fashion of the Fanatic Felcyclist` entry data
- **1.8.5**: Added full walkthroughs for 12 Orb Mystery Orb 11 (Radiant Singer — 40-player raid with Beledar Orchestra Addon at Divine Flame of Beledar, Hallowfall) and Orb 12 (Dusk Lily escort in Suramar/Azsuna for Spare Key, then Hidden Footlocker in Karazhan Catacombs); added `Ensemble: Fashion of the Fanatic Felcyclist` as a new linked transmog entry with full Dusk Lily substeps; added `Radiant Singer` substeps to its linked achievement entry; added questIDs 93764/93765 for Orb 11 and 12; added version-check broadcast (`SecretChecklistVersion.lua`) that notifies you in chat when a group member has a newer version
- **1.8.4**: Fixed AddonCompartment hover crash ("Wrong object type") caused by incorrect handler signatures when using `RegisterAddon`; corrected function signatures to match `RegisterAddon` calling convention (`funcOnEnter`/`funcOnLeave` receive `(button, addonInfo)`, `func` receives `(_, menuInputData, menu)`); added settings to show/hide the minimap addon compartment button independently
- **1.8.3**: Added AddonCompartment support — Secret Checklist now appears in the minimap addon compartment dropdown; left-click toggles the window, hovering shows a tooltip, right-click gracefully noops (reserved for future options panel)
- **1.8.2**: Fixed substep anchor cascading indent (each substep row was indented 14px more than the previous); corrected Riddler's Mind-Worm quest ID for "Loot Gift of the Mind-Seekers" (47213 → 47214); added missing `questID = 58099` to Jenafur's "Collect food in Karazhan" step
- **1.8.1**: Fixed addon title typo ("Secrets Checklist" → "Secret Checklist"); added *A Most Violent Loa* achievement (Filo / Kapara kills in Zul'Aman); added substeps for multi-item collection tracking within a single step (Sargle's Fortunes); progress steps now auto-expand for uncollected secrets and auto-collapse for collected ones; fixed item-based step tracking not updating when moving items to/from the bank
- **1.8.0**: Added live requirement checks for renown, faction reputation, and Mind-Seeker secret count — incomplete steps now display current progress inline (e.g. `(5 / 8)`); added step walkthroughs for all previously missing entries (Mimiron's Jumpjets, Pattie's Cap, Tobias' Leash, Starry-Eyed Goggles, Mind-Seeker); split Mind-Seeker secret-count requirement into its own dedicated step; About tab is now always visible (no longer a hidden easter egg); added `questID` and `repReq` to Bound Shadehound steps; updated cross-references and `requires`/`requiredFor` to arrays throughout; **note: some guide walkthroughs are still a work in progress and step data may not yet be complete or fully accurate for all entries**
- **1.7.1**: Improved Guides tab UI polish — map-pin icon on waypoint button; consistent top margin when Info/Model tab bar is hidden; increased step/note font size to 12pt for readability without ElvUI; increased gap between description and progress steps header; removed duplicate filter logic; fixed quest name lookup using correct WoW API
- **1.7.0**: Added Mystery category for community-investigated secrets; added interactive Progress Steps with click-to-waypoint in Guides tab; added step-by-step walkthroughs for Blanchy's Reins, Kosumoth (Fathom Dweller + Hungering Claw), Keys to Incognitro, and 12 Orb Mystery; added Starry-Eyed Goggles (toy) and Azeroth's Greatest Detective (achievement); fixed Hungering Claw pet speciesID; filter Deselect All now shows all entries instead of hiding them; type filter menu stays open while toggling; unknown/uninvestigated secrets now shown in grey (same as missing); model viewer hidden for entry types without a 3D model
- **1.6.3**: Fixed overview icon clicks not working; fixed guides scroll position resetting on tab switch; added toast alert when a secret is newly collected
- **1.6.2**: Fixed secret icons showing incorrect collected/missing state on first open; fixed Terky model on the About tab not rendering until switching tabs
- **1.6.1**: Added Secrets of Azeroth event entries: Tricked-Out-Thinking Cap, Torch of Pyrreth, Idol of Ohn'ahra (toys) and Whodunnit! (achievement); updated screenshots
- **1.6.0**: Added ElvUI theme support with automatic detection and visual styling; enhanced scrollbar and divider polish; added About tab with addon credits, license info, and easter egg
- **1.5.1**: Click overview icons to navigate to the Guides tab entry; Ctrl+Click to insert item/achievement link into chat; Wowhead button moved to bottom of detail pane; progress counts shown on both Overview and Guides tabs
- **1.5.0**: Added Guides tab with wowhead guide links and interactive 3D model viewer (mounts, pets, transmog on player, housing items); fixed minimap button persistence; updated filter pill visual; new entries (Bound Shadehound, Felreaver Deathcycle, Keys to Incognitro, Mimiron's Jumpjets, Nazjatar Blood Serpent, Otto, Pattie's Cap, Thrayir Eyes of the Siren, Xy Trustee's Gearglider, Courage, Glimr's Cracked Egg, Sun Darter Hatchling, Terky, Tobias' Leash, Hungering Claw, Cartel Transmorpher, Leaders of Scholomance, Mind-Seeker, Wan'be's Buried Goods, Shu'halo Perspective Painting)
- **1.2.1**: Added You Conduit! achievement (Midnight) and Gortham battle pet
- **1.2.0**: Full localization system (11 languages supported), minimap button settings panel, performance optimizations, code quality audit
- **1.1.0**: Added advanced filtering system (status + type filters), Select All/Deselect All buttons, simplified slash commands, code optimization (11% reduction)
- **1.0.1**: Added status filter dropdown (All/Collected/Missing)
- **1.0.0**: Initial public release with minimap button and Collections Journal UI
