# SecretChecklist

A World of Warcraft addon that helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, transmog, quests, housing items, and other hidden content.

<img width="914" height="720" alt="secretschecklist" src="https://github.com/user-attachments/assets/d0d06a62-8bbb-4bd8-abd0-d9652839c642" />
<img width="952" height="718" alt="secretschecklist_filters" src="https://github.com/user-attachments/assets/363432c4-9b31-453a-bc35-37c9f91e7b0d" />

## Features

- **Minimap Button**: Quick access with a draggable minimap button
- **Collections Journal Tab**: Beautiful UI integrated into WoW's Collections interface
- **Automated Checking**: Automatically checks your collection status for pre-defined secret collectibles
- **Advanced Filtering**: Filter by status (All/Collected/Missing) and type (Mounts, Pets, Toys, Achievements, Quests, Transmog, Housing)
- **Bulk Filter Controls**: Select All / Deselect All buttons for quick filter management
- **Visual Feedback**: Icons are colored when collected, greyed out when missing
- **Progress Bar**: Track your completion percentage across all filters
- **Guides Tab**: Detailed view of each secret with description, wowhead guide link, and an interactive 3D model viewer
- **3D Model Viewer**: Previews mounts, pets, transmog worn on your character, housing items, and weapons in a live model scene
- **Click-to-Navigate**: Click any icon in the Overview to jump directly to its Guides entry; Ctrl+Click inserts an item or achievement link into your active chat box
- **Custom Lists**: Easily edit the list to track the secrets you want
- **Pre-Configured**: Comes with 39 secrets ready to track

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

The addon comes pre-configured with **39 secret collectibles**:

### Mounts (18)
- Blanchy's Reins
- Bound Shadehound
- Crimson Tidestallion
- Fathom Dweller (Kosumoth)
- Felreaver Deathcycle (Voidfire Deathcycle)
- Keys to Incognitro, the Indecipherable Felcycle
- Long-Forgotten Hippogryph
- Lucid Nightmare
- Mimiron's Jumpjets
- Nazjatar Blood Serpent
- Nilganihmaht Control Ring
- Otto
- Pattie's Cap
- Riddler's Mind-Worm
- Slime Serpent
- The Hivemind
- Thrayir, Eyes of the Siren
- Xy Trustee's Gearglider

### Pets (12)
- Baa'l's Darksign
- Courage
- Glimr's Cracked Egg
- Gortham
- Hungering Claw (Kosumoth)
- Jenafur
- Phoenix Wishwing
- Sun Darter Hatchling
- Terky
- Tobias' Leash
- Uuna
- Wicker Pup

### Toys (3)
- Black Dragon's Challenge Dummy
- Cartel Transmorpher
- Enlightened Hearthstone

### Achievements (3)
- Leaders of Scholomance (Necromantic Knowledge)
- Mind-Seeker
- You Conduit!

### Transmog (1)
- Waist of Time

### Quests (1)
- Wan'be's Buried Goods

### Housing (1)
- Shu'halo Perspective Painting

### Saving Your Preferences

Your filter preferences and minimap button position are automatically saved to SavedVariables when you log out or exit WoW:
- Filter settings (status and type selections)
- Minimap button position and visibility
- These settings persist across characters and sessions

## Version History

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
