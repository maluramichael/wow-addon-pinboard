# PinBoard

<!-- links:start -->
[![Support me on Ko-fi](https://malura.de/assets/badge/kofi.svg)](https://malura.de/go/kofi?ref=wow-addon-pinboard)
[![Check out my page](https://malura.de/assets/badge/malura.svg)](https://malura.de/go/site?ref=wow-addon-pinboard)
<!-- links:end -->

Save, organize, and manage your favorite map waypoints with a clean, modern UI.

## Features

- **Pin Here** — save your current location with one click
- **Import /way Commands** — paste waypoint lists from Wowhead comments or guides
- **Categories** — organize pins into groups (General, Dailies, Farming, Rares, or custom)
- **Blizzard Native Pins** — sets the built-in map pin with on-screen tracking arrow
- **Search** — instantly filter by zone name or description
- **Distance Display** — shows yards to waypoints in your current zone
- **LDB Minimap Button** — quick access with nearby waypoints in the tooltip
- **Context Menu** — right-click to edit, move, or remove waypoints
- **TomTom Integration** — optionally set a TomTom waypoint arrow alongside the native pin (requires TomTom)
- **Dark Polished UI** — clean dark theme with gold accents and hover highlights

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/pb` | Toggle the main window |
| `/pb add` | Pin your current location |
| `/pb import` | Open the import dialog |
| `/pb clear` | Clear the active waypoint |
| `/pb 54.9 27.3 Some spot` | Add and activate a waypoint |
| `/pb config` | Open the options panel |

### Main Window

- **Pin Here** — adds your current location as a new waypoint
- **Import** — opens a dialog to paste multiple /way commands at once
- **Search bar** — type to filter the list in real-time
- **Double-click** a waypoint to set it as your active map pin
- **Right-click** a waypoint for edit, move to category, or remove options
- **Category headers** — click to collapse or expand groups

### Import Format

Paste any standard /way format, one per line:

```
/way 54.9 27.3 Some location
/way Hallowfall 41.8 58.2 Caesper turn-in
/way #2215 35.4 53.8 Dark Ritual
```

### LDB / Minimap Button

- **Left-click** — toggle the main window
- **Right-click** — open options
- **Tooltip** — shows saved count, active waypoint, and nearby pins with distance

## Requirements

- World of Warcraft Retail (The War Within / Midnight)
- Ace3 libraries (included via CurseForge packaging)

## Installation

Install via [CurseForge](https://www.curseforge.com/wow/addons) or copy the `PinBoard` folder into your `_retail_\Interface\AddOns\` directory.
