# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows semantic versioning where practical.

## [Unreleased]

### Added

- Multi-shortcut support with individual format profiles and global hotkey bindings (e.g., `⌃⇧S` for full timestamp, `⌃⇧D` for date only, with dynamic `+ Add Shortcut` capability).
- Top menu bar quick actions for every registered shortcut with Mac keyboard glyphs.
- Built-in "Date only" (`yyyy-MM-dd`) and "Time only" (`HH:mm:ss`) format presets.

### Changed

- Replaced the app icon with a clean monochrome clock-and-stand mark.
- Replaced the menu bar status item SF Symbol with the matching clean clock template icon.
- Upgraded menu bar dropdown to native macOS styling with a categorized "More Formats ▸" submenu, actionable top shortcut items, and clean typography without loud badges.
- Upgraded Settings window with high-contrast squircle app tile, live output preview per shortcut, Mac keyboard glyphs, and instant auto-apply.
- Updated documentation and README with the new logo, modern macOS System Settings instructions, and up-to-date app features.

### Fixed

- Fixed Settings window layout bug where `NSBox` collapsed controls into an overlapping pile at the bottom; replaced with a robust Auto Layout `CardView` container that smoothly sizes to its content.
- Fixed dark mode icon visibility in the Settings header so the clock mark remains bright and crisp in both dark and light system appearances.

## [1.0.0] - 2026-05-15

### Added

- Native menu-bar timestamp insertion app.
- Direct text insertion without using the clipboard.
- Editable timestamp format.
- Editable global keyboard shortcut.
- Accessibility settings shortcut.
- Source build and release packaging scripts.
- GitHub Actions CI.
