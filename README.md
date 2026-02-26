# SecretChecklist

A World of Warcraft addon that helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, and other hidden content.

## Features

- **Automated Checking**: Automatically checks your collection status for pre-defined secret collectibles
- **Interactive UI**: Journal-style UI that displays all tracked secrets with greyed-out icons for missing items
- **Custom Lists**: Easily edit the list to track the secrets you want
- **Progress Reports**: Generate reports showing what you've collected and what you're missing
- **Export to Saved Variables**: Results are saved to disk for easy copying and sharing

## Installation

1. Download the latest release or clone this repository
2. Extract the `SecretChecklist` folder to `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart World of Warcraft or reload your UI with `/reload`

## Commands

| Command | Description |
|---------|-------------|
| `/secrets` | Prints collected/missing items for the configured list |
| `/secrets verbose` | Includes short failure reasons (e.g., "not cached") |
| `/secrets quiet` | Turns verbose mode off |
| `/secrets where` | Shows where the report is saved on disk |
| `/secrets wait` | Waits 2 seconds then runs (useful if journals are still loading) |
| `/secrets ui` | Opens the journal-style UI list with visual indicators |

## Tracked Secrets

The addon comes pre-configured with 32+ secret collectibles including:

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

Open `SecretChecklist.lua` and edit the `SC.entries` table. Each entry follows this format:

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

### Accessing Results

1. Run `/secrets` in game
2. Log out or exit WoW (this writes SavedVariables to disk)
3. Open: `WTF\Account\<YourAccount>\SavedVariables\SecretChecklist.lua`
4. Look for `SecretChecklistDB.lastReport.lines`

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

- **0.3**: Current version with Collections UI tab support
- Supports WoW Interface 12.0.0 and 12.0.1 (The War Within)

## Author

Created by Local

## License

MIT License - Feel free to use, modify, and distribute
