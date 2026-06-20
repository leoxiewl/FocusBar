# FocusBar &nbsp;·&nbsp; [中文版](README_CN.md)

A macOS menu-bar app that lives in your MacBook's notch — hover to see what matters most.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What is it?

FocusBar is a lightweight focus anchor that sits permanently in the notch area of MacBook Pro. It doesn't replace your task manager — it keeps your most important things visible without switching apps.

Hover over the notch → a glass panel slides down showing everything you need to stay on track.

## Features

- **Now working** — write what you're doing right now, supports multiple parallel tasks
- **Today's Top 3** — the 3 most important things to finish today, with checkboxes
- **This week's Top 3** — the 3 most important things to push forward this week, with checkboxes
- **Pin** — click the pin icon to keep the panel permanently visible on your desktop
- **Markdown storage** — all data is saved as plain Markdown files (`2026-06-20.md`, `2026-W25.md`), fully compatible with Obsidian and any text editor
- **Configurable directory** — choose where your data lives; migration prompt when switching directories
- **ISO 8601 calendar** — weeks start on Monday, week keys follow `YYYY-Wnn` format

## Screenshots

> Hover the MacBook notch to reveal the panel

*(add your screenshot here)*

## Requirements

- macOS 13 Ventura or later
- MacBook Pro 2021 or later (notch required)

## Installation

### Option A — Download (recommended)

1. Download `FocusBar.zip` from [Releases](../../releases)
2. Unzip and move **FocusBar.app** into your Applications folder
3. Launch FocusBar — it appears in the notch area automatically

> **First launch:** macOS will block the app because it's unsigned. Right-click **FocusBar.app → Open** and confirm, or run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/FocusBar.app
> ```

### Option B — Build from source

Requires [Xcode 15+](https://developer.apple.com/xcode/) and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/YOUR_USERNAME/focusbar.git
cd focusbar
brew install xcodegen
xcodegen generate
open FocusBar.xcodeproj
```

Then press **⌘R** in Xcode to run.

## Usage

| Action | Result |
|---|---|
| Hover over the notch | Panel slides down |
| Click any text | Edit inline — press Enter or click away to save |
| Click a checkbox | Toggle task completion |
| Click the pin icon | Keep panel open permanently |
| Click the gear icon | Open Settings (change storage directory) |
| Move mouse away | Panel auto-closes after 300 ms (when not pinned) |

## Data Storage

FocusBar stores everything as human-readable Markdown files:

```
~/Documents/FocusBarData/
├── 2026-06-20.md   ← today's tasks + current focus
├── 2026-06-21.md
└── 2026-W25.md     ← this week's top 3
```

You can change the storage directory in Settings. When switching directories, FocusBar asks whether to migrate existing files to the new location.

## Built With

- **Swift + SwiftUI + AppKit** — native macOS, no Electron
- **NSVisualEffectView** — authentic macOS glass blur
- **Markdown files** — plain text storage, Obsidian-compatible
- **xcodegen** — project file generated from `project.yml`
- No third-party dependencies

## Project Structure

```
FocusBar/
├── App/
│   ├── FocusBarApp.swift       # @main entry point
│   └── AppDelegate.swift       # window setup, mouse tracking, menu bar icon
├── Models/
│   ├── Task.swift              # FocusTask, DayRecord, WeekRecord
│   └── MarkdownStore.swift     # read/write Markdown files, calendar awareness
├── Utils/
│   ├── NotchHelper.swift       # notch position calculation
│   └── CalendarHelper.swift    # ISO 8601 week keys
└── Windows/
    ├── NotchWindow.swift       # transparent placeholder in the notch
    ├── PanelController.swift   # expand/collapse animation, pin logic
    ├── PanelView.swift         # SwiftUI panel UI
    └── SettingsView.swift      # settings window
```

## License

MIT — see [LICENSE](LICENSE)
