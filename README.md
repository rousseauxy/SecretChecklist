# SecretChecklist

A World of Warcraft addon that helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, and other hidden content.

<img width="914" height="720" alt="secretschecklist" src="https://github.com/user-attachments/assets/d0d06a62-8bbb-4bd8-abd0-d9652839c642" />
<img width="952" height="718" alt="secretschecklist_filters" src="https://github.com/user-attachments/assets/363432c4-9b31-453a-bc35-37c9f91e7b0d" />

## Features

- **Minimap Button**: Quick access with a draggable minimap button
- **Collections Journal Tab**: Beautiful UI integrated into WoW's Collections interface
- **Automated Checking**: Automatically checks your collection status for pre-defined secret collectibles
- **Advanced Filtering**: Filter by status (All/Collected/Missing) and type (Mounts, Pets, Toys, Achievements, Quests, Transmog)
- **Bulk Filter Controls**: Select All / Deselect All buttons for quick filter management
- **Visual Feedback**: Icons are colored when collected, greyed out when missing
- **Progress Bar**: Track your completion percentage across all secrets
- **Custom Lists**: Easily edit the list to track the secrets you want
- **Pre-Configured**: Comes with 33 secrets ready to track

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

### Using Filters

- **Status Filter**: Click the "Status: All" dropdown to show only Collected or Missing items
- **Type Filter**: Click the "Filter" button to select which types to display (Mounts, Pets, Toys, etc.)
- **Quick Actions**: Use "Select All" or "Deselect All" to quickly manage type filters
- **Progress Bar**: Shows your overall completion percentage regardless of active filters

## Tracked Secrets

The addon comes pre-configured with 33 secret collectibles including:

### Mounts
- Blanchy's Reins
- Lucid Nightmare
- Long-Forgotten Hippogryph
- Riddler's Mind-Worm
- The Hivemind
- Slime Serpent
- And many more...

### Pets
- Baa'l's Darksign
- Jenafur
- Uuna
- Wicker Pup
- Phoenix Wishwing
- Gortham

### Toys
- Enlightened Hearthstone
- Nilganihmaht Control Ring
- Black Dragon's Challenge Dummy

### Other
- Achievements (You Conduit!, and more)
- Transmog items
- Quest chains

### Saving Your Preferences

Your filter preferences and minimap button position are automatically saved to SavedVariables when you log out or exit WoW:
- Filter settings (status and type selections)
- Minimap button position and visibility
- These settings persist across characters and sessions

## Version History

- **1.2.1**: Added You Conduit! achievement (Midnight) and Gortham battle pet
- **1.2.0**: Full localization system (11 languages supported), minimap button settings panel, performance optimizations, code quality audit
- **1.1.0**: Added advanced filtering system (status + type filters), Select All/Deselect All buttons, simplified slash commands, code optimization (11% reduction)
- **1.0.1**: Added status filter dropdown (All/Collected/Missing)
- **1.0.0**: Initial public release with minimap button and Collections Journal UI
- Supports WoW Interface 12.0.0 and 12.0.1 (Midnight)

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
