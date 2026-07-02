# Timestamp Inserter

Timestamp Inserter is a tiny native macOS menu-bar app for inserting a local timestamp into the currently focused text field.

It is intentionally simple:

- Runs in the background as a menu-bar app.
- Uses a global keyboard shortcut.
- Sends text input directly to the focused app.
- Does not use or overwrite the clipboard.
- Lets you edit the timestamp format and shortcut from the app menu.

Default output:

```text
2026-05-15-2030
```

Default format:

```text
yyyy-MM-dd-HHmm
```

## Download & Install

You can download the latest pre-built version from the [Releases](../../releases/latest) page.

1. Download the `Timestamp-Inserter.zip` file and extract it.
2. Drag `Timestamp Inserter.app` into your `/Applications` folder.
3. **Important:** Because this app is not signed with a paid Apple Developer certificate, macOS will block it the first time you try to open it.
   - To bypass this, **right-click** (or Control-click) `Timestamp Inserter.app` in Finder and select **Open**.
   - macOS will show a warning, but you can click **Open** anyway. You only need to do this once.

## Requirements

- macOS 12 or newer.
- Accessibility permission for inserting text into other apps.
- Xcode Command Line Tools (only if building from source).

## Install From Source

Clone the repo, then build:

```sh
./build.sh
```

The app bundle is created at:

```text
TimestampInserter/Build/Timestamp Inserter.app
```

Drag `Timestamp Inserter.app` into `/Applications`, then open it.

If macOS blocks the app because it was built locally, right-click the app, choose `Open`, then confirm.

## First Run

1. Open `Timestamp Inserter.app`.
2. Grant Accessibility permission when macOS asks.
3. If it does not prompt, open `System Settings (or System Preferences on older macOS) > Privacy & Security > Accessibility`.
4. Enable `Timestamp Inserter`.

## Usage

1. Put your cursor in any editable text field.
2. Press the configured keyboard shortcut.

Default shortcut:

```text
Control-Option-Command-T
```

The app inserts the timestamp directly into the focused field.

## Settings

Click the `TS` menu-bar item, then choose `Settings...`.

You can change:

- Timestamp format.
- Global keyboard shortcut.

Format examples:

```text
yyyy-MM-dd-HHmm      -> 2026-05-15-2030
yyyy-MM-dd-HHmmX     -> 2026-05-15-2030+07
yyyy-MM-dd-HHmmXX    -> 2026-05-15-2030+0700
yyyy-MM-dd-HHmmXXX   -> 2026-05-15-2030+07:00
yyyy-MM-dd HH:mm:ss  -> 2026-05-15 20:30:45
```

The format is interpreted by Apple `DateFormatter`.

## Development

Build:

```sh
./build.sh
```

Verify the generated app:

```sh
codesign --verify --deep --strict --verbose=2 "TimestampInserter/Build/Timestamp Inserter.app"
plutil -lint "TimestampInserter/Build/Timestamp Inserter.app/Contents/Info.plist"
```

Create a distributable zip:

```sh
./scripts/package.sh
```

The zip is written to:

```text
dist/Timestamp-Inserter.zip
```

## Project Layout

```text
.
├── TimestampInserter/
│   ├── Sources/TimestampInserter/main.swift
│   ├── Info.plist
│   └── build.sh
├── scripts/package.sh
├── .github/workflows/ci.yml
└── README.md
```

## Privacy

Timestamp Inserter needs Accessibility permission so it can send text input events to the focused app. It does not collect data, make network requests, or read the contents of the active app.

## License

MIT. See [LICENSE](LICENSE).
