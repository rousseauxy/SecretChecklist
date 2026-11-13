<!-- Store-page copy for both CurseForge and Wago; both render Markdown.
     Paste into the project description on each site.
     Written to stay correct between releases: no version numbers, no
     secret counts, no changelog. If you edit it, update both sites. -->

# SecretChecklist

WoW is full of secrets the game never tells you about. SecretChecklist helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, transmog, quests, housing items, and other hidden content — and knows what you've already collected the moment you log in.

**Works in WoW: Forever too.** The same download runs in both games, and each one shows only its own secrets.

![Overview tab](https://github.com/user-attachments/assets/e752b2e7-075d-41ef-b74a-14d1027a32e8)
![Guides tab](https://github.com/user-attachments/assets/8808e138-7a3d-4de9-ac0e-2846abf0217d)
![EllesmereUI theme](https://github.com/user-attachments/assets/74a6cb6d-c402-470c-aabb-885791f35136)

## What it does

**Shows you where you stand.** Every secret in one Collections-style window, coloured when you have it, greyed when you don't, with live counters for your overall progress and, in retail, for the Mind-Seeker set.

**Walks you through the ones you're missing.** Every secret has a step-by-step guide, and steps tick themselves off as you go. Click a step with a location and it drops a map pin — using TomTom if you have it, Blizzard's own waypoints if you don't.

**Finds anything fast.** Search by name, by zone, or by anything mentioned in the steps — "Kosumoth" and "Tazavesh" both work.

**Shows you the reward** in 3D before you go after it: mounts, pets, housing decor, and appearances shown on your own character.

**Tells you when you get one**, with a toast the moment it registers.

**Tracks the mysteries too** — secrets the community is still working out, so you can follow along with what's known.

## How to use it

Click the minimap button, or type `/secrets`.

| Command | What it does |
|---|---|
| `/secrets` | Open the window |
| `/secrets options` | Open settings |
| `/secrets minimap` | Show or hide the minimap button |
| `/secrets help` | List every command |

- **Click any icon** in the Overview to jump straight to its guide
- **Shift+click** an icon to link the item or achievement into chat
- **Filter** by status and by type — the menu stays open while you tick things
- Your filters, window position, theme and minimap button are remembered between sessions and across characters

## Beledar Orchestra helper (retail)

The Radiant Singer secret needs a 40-player raid performing a set sequence of emotes at the Divine Flame of Beledar in Hallowfall. SecretChecklist includes a player-side client for it, so **only the raid leader needs the [BeledarOrchestra](https://www.curseforge.com/wow/addons/beledarorchestra) addon** — everyone else can just have SecretChecklist.

- Target the Divine Flame and a compact popup appears with your raid slot and the emote you've been assigned for the current measure
- The emote button performs it for you; the popup counts down when the leader starts a measure, and locks in once you've bowed
- It follows your theme and remembers where you drag it
- It disables itself automatically if you have BeledarOrchestra installed, so you never get two popups

## Also

- Matches your UI: Default, ElvUI or EllesmereUI, following your accent colour, window style and font
- Collected and missing use a checkmark and a cross, not colour alone
- Available in multiple languages — is yours missing or incomplete? [Help translate it](https://github.com/rousseauxy/SecretChecklist#translating); a partial translation is genuinely useful, anything unfinished just falls back to English

## Credits & References

The Beledar Orchestra helper speaks the addon message protocol defined by **[BeledarOrchestra](https://www.curseforge.com/wow/addons/beledarorchestra)** by Samsbase, so a raid leader running that addon drives SecretChecklist users automatically. The measure data it ships with comes from the same community effort.

All secrets featured in this addon were discovered by the community over at the **[Secret Finding Discord](https://discord.gg/wowsecrets)** — the home of WoW secret hunters. A huge thanks to everyone there for their incredible detective work.

The transmog 3D model viewer logic (armor display on your character with slot zoom and camera handling) is based on the implementation from **[AppearanceTooltip](https://www.curseforge.com/wow/addons/appearancetooltip)** by Kemayo.

## Code quality

This addon was created with the assistance of Claude AI. The code is:

- **Clean and performant** — optimised for minimal overhead and fast execution
- **Global namespace safe** — free of unnecessary globals that pollute the WoW environment
- **Modern API** — uses current WoW APIs, no deprecated functions
- **Continuously checked** — every push runs luacheck and a packager dry-run in CI

## Author

Created by Calaglyn — Emerald Dream (EU).

Bugs, suggestions and source: [github.com/rousseauxy/SecretChecklist](https://github.com/rousseauxy/SecretChecklist)

Licensed under **GPL-3.0**. You're free to use, modify and distribute it, but derivative work must stay GPL-3.0, credit **SecretChecklist by Calaglyn**, and make its source available.
