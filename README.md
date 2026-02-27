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
- **Pre-Configured**: Comes with 32 popular secrets ready to track

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
| `/secrets minimap` | Toggle minimap button visibility |

### Using Filters

- **Status Filter**: Click the "Status: All" dropdown to show only Collected or Missing items
- **Type Filter**: Click the "Filter" button to select which types to display (Mounts, Pets, Toys, etc.)
- **Quick Actions**: Use "Select All" or "Deselect All" to quickly manage type filters
- **Progress Bar**: Shows your overall completion percentage regardless of active filters

## Tracked Secrets

The addon comes pre-configured with 32 secret collectibles including:

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

### Toys
- Enlightened Hearthstone
- Nilganihmaht Control Ring
- Black Dragon's Challenge Dummy

### Other
- Achievements
- Transmog items
- Quest chains

## Customization

### Editing the Secret List

Open `SecretEntries.lua` and edit the `SC.entries` table. Each entry follows this format:

```lua
{
    name = "Display Name",
    kind = "mount|pet|toy|achievement|quest|transmog",
    itemID = 123456,        -- Optional: item ID
    spellID = 123456,       -- Optional: spell ID
    achievementID = 12345,  -- Optional: achievement ID
    questID = 12345,        -- Optional: quest ID
    speciesID = 1234,       -- Optional: pet species ID
    mountID = 123,          -- Optional: mount ID
    matchNames = { "Alt Name 1", "Alt Name 2" }  -- Optional: alternative names
}
```

### Saving Your Preferences

Your filter preferences and minimap button position are automatically saved to SavedVariables when you log out or exit WoW:
- Filter settings (status and type selections)
- Minimap button position and visibility
- These settings persist across characters and sessions

## Troubleshooting

### Items Showing as [?] or Uncached

Some collection data needs to be loaded before the addon can check it:
1. Open the relevant Collections tab (Toys/Mounts/Pets)
2. Let it fully load
3. Run `/secrets` again

### Manual Entries

Entries marked as "manual" cannot be auto-checked unless you add an achievement/quest/spell/item ID that maps to something trackable in the game's API.

### Name Mismatches

Some trackable items use different names in-game vs. in the Collections UI (e.g., "Blanchy's Reins" vs "Blanchy"). The addon includes name fallbacks to handle these cases.

## Version History

- **1.1.0**: Added advanced filtering system (status + type filters), Select All/Deselect All buttons, simplified slash commands, code optimization (11% reduction)
- **1.0.1**: Added status filter dropdown (All/Collected/Missing)
- **1.0.0**: Initial public release with minimap button and Collections Journal UI
- Supports WoW Interface 12.0.0 and 12.0.1 (The War Within)

## Code Quality

This addon was created with the assistance of GitHub Copilot and Claude AI. The code is:

- **Clean and Performant**: Optimized for minimal overhead and fast execution
- **Global Namespace Safe**: Free of unnecessary global variables that pollute the WoW environment
- **Modern API**: Uses current WoW APIs without deprecated functions
- **Audited**: Code has been reviewed using Ketho's WoW API extension to ensure quality standards

We maintain strict quality standards for this addon. Poorly optimized code or AI-generated spaghetti code that pollutes the global namespace will be removed to ensure a reliable and efficient user experience.

## Author

Created by Calaglyn - Emerald Dream (EU)

## License

MIT License - Feel free to use, modify, and distribute
