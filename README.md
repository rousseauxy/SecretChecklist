# SecretChecklist

A World of Warcraft addon that helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, transmog, quests, housing items, and other hidden content.

<img width="1173" height="762" alt="cKXD4krAlE" src="https://github.com/user-attachments/assets/b4e4940b-c1d0-471d-9665-241c9bd2bdd5" />
<img width="1164" height="753" alt="gL11bkA9ow" src="https://github.com/user-attachments/assets/945a9665-e563-492b-aae6-76336934e65b" />
<img width="1042" height="783" alt="0PxHX4fTLx" src="https://github.com/user-attachments/assets/38035af6-5b34-47b6-966e-0f7895b3b885" />

## Download

- [CurseForge](https://www.curseforge.com/wow/addons/secretchecklist)
- [Wago Addons](https://addons.wago.io/addons/secretchecklist)

## Features

- **Minimap Button**: Quick access with a draggable minimap button
- **Collections Journal Tab**: Beautiful UI integrated into WoW's Collections interface
- **Automated Checking**: Automatically checks your collection status for pre-defined secret collectibles
- **Advanced Filtering**: Filter by status (All/Collected/Missing) and type (Mounts, Pets, Toys, Achievements, Quests, Transmog, Housing, Mysteries)
- **Bulk Filter Controls**: Select All / Deselect All buttons for quick filter management; menu stays open while selecting
- **Visual Feedback**: Icons are colored when collected, greyed out when missing
- **Progress Bar**: Track your completion percentage across all filters
- **Guides Tab**: Detailed view of each secret with description, wowhead guide link, and an interactive 3D model viewer
- **Progress Steps**: Step-by-step walkthrough per secret with click-to-waypoint support (via TomTom or built-in arrow)
- **3D Model Viewer**: Previews mounts, pets, transmog worn on your character, housing items, and weapons in a live model scene
- **Click-to-Navigate**: Click any icon in the Overview to jump directly to its Guides entry; Ctrl+Click inserts an item or achievement link into your active chat box
- **Mystery Category**: Track community secrets still being investigated (e.g. active discoveries from the Secret Finding Discord)
- **Custom Lists**: Easily edit the list to track the secrets you want
- **Pre-Configured**: Comes with 46 secrets ready to track
- **Live Requirement Checks**: Step progress automatically checks renown level, faction reputation, and Mind-Seeker secret count from the game API — shown inline as e.g. `(5 / 8)` when not yet complete
- **About Tab**: Always-visible About tab with addon credits and community links

## Installation

1. Download the latest release or clone this repository
2. Extract the `SecretChecklist` folder to `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart World of Warcraft or reload your UI with `/reload`

## How to Use

**Click the minimap button** to open your secret checklist in the Collections Journal. The UI displays all tracked secrets with colored icons for collected items and greyed-out icons for items you're still missing.

### Slash Commands

Both `/secrets` and `/secretchecklist` work as aliases:

| Command | Description |
|---------|-------------|
| `/secrets` | Open the SecretChecklist window |
| `/secrets options` | Open the SecretChecklist options |
| `/secrets minimap` | Toggle minimap button visibility |

- **Click an overview icon** to jump directly to that entry's full guide in the Guides tab
- **Ctrl+Click an overview icon** to insert an item or achievement link into your active chat box

### Using Filters

- **Status Filter**: Click the "Status: All" dropdown to show only Collected or Missing items
- **Type Filter**: Click the "Filter" button to select which types to display (Mounts, Pets, Toys, etc.)
- **Quick Actions**: Use "Select All" or "Deselect All" to quickly manage type filters
- **Progress Bar**: Shows your overall completion percentage regardless of active filters

## Tracked Secrets

Comes pre-configured with **46 secret collectibles** across mounts, pets, toys, achievements, transmog, quests, housing, and mysteries — with more being added regularly.

### Saving Your Preferences

Your filter preferences and minimap button position are automatically saved to SavedVariables when you log out or exit WoW:
- Filter settings (status and type selections)
- Minimap button position and visibility
- These settings persist across characters and sessions

## Version History

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
- Supports WoW Interface 120000 and 120001 (Midnight)

## Credits & References

The transmog 3D model viewer logic (armor display on player character with slot zoom and camera handling) is based on the implementation from **[AppearanceTooltip](https://www.curseforge.com/wow/addons/appearancetooltip)** by [Kemayo](https://www.curseforge.com/members/kemayo/projects). Specifically, the `DressUpModel` + `TryOn` + `Dress()` pattern and `Model_ApplyUICamera` usage were adapted from that addon's source.

All secrets featured in this addon were discovered by the community over at the **[Secret Finding Discord](https://discord.gg/wowsecrets)** — the home of WoW secret hunters. A huge thanks to everyone there for their incredible detective work.

## Code Quality

This addon was created with the assistance of GitHub Copilot and Claude AI. The code is:

- **Clean and Performant**: Optimized for minimal overhead and fast execution
- **Global Namespace Safe**: Free of unnecessary global variables that pollute the WoW environment
- **Modern API**: Uses current WoW APIs without deprecated functions
- **Audited**: Code has been reviewed using Ketho's WoW API extension to ensure quality standards

## Author

Created by Calaglyn - Emerald Dream (EU)

## License

This addon is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

You are free to use, modify, and distribute this addon, but any derivative work **must**:
- Be released under the same GPL-3.0 license
- Include prominent attribution crediting **SecretChecklist by Calaglyn** as the original work
- Make the source code available

See the [LICENSE](LICENSE) file for full details.
