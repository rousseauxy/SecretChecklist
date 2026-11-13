# SecretChecklist

A World of Warcraft addon that helps you track and check your progress on secret collectibles including mounts, pets, toys, achievements, transmog, quests, housing items, and other hidden content.

Works in both retail and **WoW: Forever** from the same download. Each game shows only its own secrets.

![Overview tab](https://github.com/user-attachments/assets/e752b2e7-075d-41ef-b74a-14d1027a32e8)
![Guides tab](https://github.com/user-attachments/assets/8808e138-7a3d-4de9-ac0e-2846abf0217d)
![EllesmereUI theme](https://github.com/user-attachments/assets/74a6cb6d-c402-470c-aabb-885791f35136)

## Download

- [CurseForge](https://www.curseforge.com/wow/addons/secretchecklist)
- [Wago Addons](https://addons.wago.io/addons/secretchecklist)

## Features

- **Minimap Button**: Quick access with a draggable minimap button
- **Collections-style Journal**: A standalone window styled after WoW's Collections interface
- **Automated Checking**: Automatically checks your collection status for pre-defined secret collectibles
- **Advanced Filtering**: Filter by status (All/Collected/Missing) and type (Mounts, Pets, Toys, Achievements, Quests, Transmog, Housing, Mysteries)
- **Bulk Filter Controls**: Select All / Deselect All buttons for quick filter management; menu stays open while selecting
- **Visual Feedback**: Icons are colored when collected, greyed out when missing
- **Progress Counters**: Live "collected / total" counts for all secrets and, in retail, for Mind-Seeker secrets
- **Guides Tab**: Detailed view of each secret with description, wowhead guide link, and an interactive 3D model viewer
- **Search**: Find any secret by name, zone, or anything mentioned in its steps — searching "Kosumoth" or "Tazavesh" works as well as searching the item name
- **Progress Steps**: Step-by-step walkthrough per secret with click-to-waypoint support (via TomTom or built-in arrow)
- **3D Model Viewer**: Previews mounts, pets, transmog worn on your character, housing items, and weapons in a live model scene
- **Click-to-Navigate**: Click any icon in the Overview to jump directly to its Guides entry; Shift+Click (or Ctrl+Click) inserts an item or achievement link into your active chat box
- **Mystery Category**: Track community secrets still being investigated (e.g. active discoveries from the Secret Finding Discord)
- **Custom Lists**: Easily edit the list to track the secrets you want
- **Pre-Configured**: Comes with 54 retail secrets and 4 WoW: Forever secrets ready to track
- **Live Requirement Checks**: Step progress automatically checks renown level, faction reputation, and Mind-Seeker secret count from the game API — shown inline as e.g. `(5 / 8)` when not yet complete
- **Themes**: Default, ElvUI, and EllesmereUI looks, matching whichever UI you run
- **Accessible Status Icons**: Collected and missing are marked with a checkmark and a cross, not colour alone
- **Collection Toasts**: A toast pops up the moment a tracked secret is collected, so you know it registered
- **Remembers Its Place**: Window position, filters, theme and minimap button all persist across sessions and characters
- **Beledar Orchestra Helper** (retail): Built-in raid client for the Radiant Singer secret — see [Beledar Orchestra Helper](#beledar-orchestra-helper)
- **Translatable**: Both the interface and the guide content itself can be translated — see [Translating](#translating)
- **About Tab**: Always-visible About tab with addon credits and community links

## Installation

1. Download the latest release or clone this repository
2. Extract the `SecretChecklist` folder to `World of Warcraft\_retail_\Interface\AddOns\`
   (for WoW: Forever, `World of Warcraft\_forever_\Interface\AddOns\`)
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
| `/secrets alert` | Fire a test collection toast |
| `/secrets validate` | Check the secret data for problems |
| `/secrets debug` | Toggle debug mode (shows the real per-step state on collected secrets) |
| `/secrets help` | List these commands |

- **Click an overview icon** to jump directly to that entry's full guide in the Guides tab
- **Shift+Click an overview icon** to insert an item or achievement link into your active chat box (Ctrl+Click also works)

### Using Filters

- **Status Filter**: Click the "Status: All" dropdown to show only Collected or Missing items
- **Type Filter**: Click the "Filter" button to select which types to display (Mounts, Pets, Toys, etc.)
- **Quick Actions**: Use "Select All" or "Deselect All" to quickly manage type filters
- **Progress Counters**: Show your overall collected / total counts regardless of active filters

### Saving Your Preferences

Everything you change is written to SavedVariables and comes back at your next
login, on every character:

- Filter settings (status and type selections)
- Window position and the Guides tab layout style
- Theme choice
- Minimap button position and visibility

## Tracked Secrets

Comes pre-configured with **54 secret collectibles** across mounts, pets, toys, achievements, transmog, quests, housing, and mysteries — with more being added regularly.

### WoW: Forever

Forever is a separate client (internally called "Camelot"), so it has its own
secrets in `data/ForeverEntries.lua`. `SecretChecklist_Camelot.toc` loads that
file instead of `data/SecretEntries.lua`, and leaves out the retail-only Beledar
helper. Everything else (the window, guides, waypoints and toasts) is shared.

It starts with the Alcaz Operative Insignia, the Cozy Sleeping Bag chain, and
two chains the community is still solving: Dawn Waker and the manual scavenger
hunt. Your saved settings are kept separately per game.

## Beledar Orchestra Helper

The Radiant Singer secret needs a 40-player raid performing a set sequence of
emotes at the Divine Flame of Beledar in Hallowfall. SecretChecklist ships a
small player-side client for that, so **only the raid leader needs the
[BeledarOrchestra](https://www.curseforge.com/wow/addons/beledarorchestra)
addon** — everyone else can just have SecretChecklist.

- Target the Divine Flame in Hallowfall and a compact popup appears with your
  raid slot and the emote you have been assigned for the current measure.
- The emote button performs it for you; the popup counts down when the leader
  starts a measure and locks in once you have bowed.
- It follows your theme (Default, ElvUI or EllesmereUI) and remembers where you
  drag it.
- It disables itself automatically if you have BeledarOrchestra installed, so
  you never get two popups.

## Translating

The interface ships in 11 languages. Guide content is translated into Russian
(apart from the newest WoW: Forever lines); the German file exists but is still
empty, and every other language falls back to English. Help very much wanted.

Two separate files, because they are two different jobs:

| File | Contents |
|---|---|
| `localisation/<locale>.lua` | Interface labels — buttons, tabs, tooltips, settings |
| `localisation/data/<locale>.lua` | Guide content — every step label, note, source and description |

Guide content is keyed by its English text rather than by an id, so nothing in
the data file needs changing to add a language, and a partly finished
translation falls back to English string by string rather than all at once.

To start a new language, or to pick up strings added since the last pass:

```
python tools/extract-strings.py --locale frFR
```

It writes `localisation/data/frFR.lua` with every string from both the retail
and the WoW: Forever data listed, and preserves any translations already there,
so it is safe to re-run. Add the new file to
`localisation/locale.xml` alongside the others.

Notes for translators:

- A line left empty falls back to English. Nothing breaks if you skip one.
- Placeholders such as `%d` and `%s` may be moved to suit your word order, but
  each one must appear exactly once in the translation.
- Changing an English string in the data file orphans its translation; re-running
  the extractor shows which strings need another look.

Pull requests with a new or improved locale are very welcome.

## Version History

See [CHANGELOG.md](CHANGELOG.md). Per-release notes are also on the
[releases page](https://github.com/rousseauxy/SecretChecklist/releases).

## Releasing

Pushing a tag is the whole release. `release.yml` runs the BigWigs packager,
which publishes to GitHub, CurseForge and Wago in one go — it takes about ten
seconds end to end, and cancelling the run afterwards does not unpublish
anything. Treat `git push origin <tag>` as the irreversible step.

Before tagging:

1. **Rewrite `RELEASE_NOTES.md`.** It holds only the version being released and
   is what CurseForge and Wago show as that upload's notes. `CHANGELOG.md` is
   the cumulative history and is no longer in that path — if it were, every
   release page would repeat every earlier release underneath it. CI fails the
   release when the heading does not match the tag, so a forgotten rewrite is
   caught rather than published.
2. **Add the matching `CHANGELOG.md` entry**, in the same commit.
3. **Tag without a `v` prefix.** 1.x used `v1.9.11`; 2.0.0 onward uses `2.0.6`.
   The tag becomes the addon's version string verbatim, so mixing the two
   produces `## Version: v2.0.4` in the packaged `.toc`.
4. **Annotate the tag** (`git tag -a`) — the packager requires it.

## Credits & References

The transmog 3D model viewer logic (armor display on player character with slot zoom and camera handling) is based on the implementation from **[AppearanceTooltip](https://www.curseforge.com/wow/addons/appearancetooltip)** by [Kemayo](https://www.curseforge.com/members/kemayo/projects). Specifically, the `DressUpModel` + `TryOn` + `Dress()` pattern and `Model_ApplyUICamera` usage were adapted from that addon's source.

The Beledar Orchestra helper speaks the addon message protocol defined by **[BeledarOrchestra](https://www.curseforge.com/wow/addons/beledarorchestra)** by [Samsbase](https://github.com/samsbase), so a raid leader running that addon drives SecretChecklist users automatically. The measure data it ships with comes from the same community effort.

All secrets featured in this addon were discovered by the community over at the **[Secret Finding Discord](https://discord.gg/wowsecrets)** — the home of WoW secret hunters. A huge thanks to everyone there for their incredible detective work.

## Code Quality

This addon was created with the assistance of GitHub Copilot and Claude AI. The code is:

- **Clean and Performant**: Optimized for minimal overhead and fast execution
- **Global Namespace Safe**: Free of unnecessary global variables that pollute the WoW environment
- **Modern API**: Uses current WoW APIs without deprecated functions
- **Continuously Checked**: Every push runs luacheck, an XML well-formedness check and a packager dry-run in CI
- **Audited**: Code has been reviewed using Ketho's WoW API extension to ensure quality standards

`/secrets validate` checks the secret data against the live game — schema, cross-references between entries, and whether each waypoint's map actually accepts one. Useful if you keep your own edits to `data/SecretEntries.lua` or `data/ForeverEntries.lua`; run it in the client the file belongs to.

## Author

Created by Calaglyn - Emerald Dream (EU)

## License

This addon is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

You are free to use, modify, and distribute this addon, but any derivative work **must**:
- Be released under the same GPL-3.0 license
- Include prominent attribution crediting **SecretChecklist by Calaglyn** as the original work
- Make the source code available

See the [LICENSE](LICENSE) file for full details.
