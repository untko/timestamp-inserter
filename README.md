# Timestamp Inserter

<p align="center">
  <img src="assets/timestamp-inserter-logo-clean.svg" width="128" height="128" alt="Timestamp Inserter logo">
</p>

<p align="center">
  A tiny native macOS menu-bar app for inserting formatted timestamps into the currently focused text field.
</p>

---

## Features

- **Menu-bar only:** Runs quietly in the macOS menu bar without cluttering the Dock (`LSUIElement`).
- **Global hotkey:** Press a single keyboard shortcut from any application to insert the timestamp.
- **Direct keystroke input:** Sends text directly to the focused app without reading or overwriting your clipboard.
- **Rich preset library:** Preconfigured presets for ISO 8601 / RFC 3339, Unix epoch (seconds and milliseconds), Compact local, Email date (RFC 2822), European, US, UK, German, and custom `DateFormatter` patterns.
- **UTC or Local:** Quickly toggle whether date-based formats output in your local timezone or UTC.
- **Launch at Login:** Optional toggle in Preferences to start automatically on system startup.

Default output:

```text
2026-05-15-2030
```

Default preset:

```text
Compact local (yyyy-MM-dd-HHmm)
```

Default shortcut:

```text
Control-Option-Command-T (⌃⌥⌘T)
```

---

## Download & Install

Download the latest pre-built release from the [Releases](https://github.com/untko/timestamp-inserter/releases/latest) page.

1. Download `Timestamp-Inserter.zip` from the release assets and uncompress it.
2. Drag `Timestamp Inserter.app` into your `/Applications` folder.
3. Open `Timestamp Inserter.app` and configure permissions in **System Settings** (see below).

---

## System Settings & Permissions

Because Timestamp Inserter is an independent open-source utility that simulates keystrokes across applications, macOS requires granting permissions in **System Settings**:

### 1. Opening the App for the First Time (Gatekeeper)

Because this app is not signed with a paid Apple Developer certificate, macOS will block it on first open:

- **Option A (Finder):** In `/Applications`, **right-click** (or Control-click) `Timestamp Inserter.app` and choose **Open**. In the confirmation dialog, click **Open**. You only need to do this once.
- **Option B (System Settings):** If macOS blocks the app, open **System Settings > Privacy & Security**, scroll down to the **Security** section, and click **Open Anyway**.
- **Option C (Terminal):** Remove the quarantine attribute directly:
  ```sh
  xattr -d com.apple.quarantine "/Applications/Timestamp Inserter.app"
  ```

### 2. Accessibility Permission (Required for Text Insertion)

Timestamp Inserter requires Accessibility permission to insert text into other active applications via `CGEvent` without touching the clipboard.

1. When you first launch the app, macOS will prompt you to grant Accessibility access.
2. If the prompt does not appear, open **System Settings > Privacy & Security > Accessibility**.
3. Enable the toggle for **Timestamp Inserter**.
4. You can also click **Open Accessibility Settings** directly from the app's menu bar dropdown.

> **Tip after updates:** If you replace `Timestamp Inserter.app` with a newer version and timestamps stop inserting, macOS may still have the old binary signature cached. Go to **System Settings > Privacy & Security > Accessibility**, toggle **Timestamp Inserter** OFF and back ON (or remove it with `-` and re-add it).

### 3. Launch at Login (Optional)

You can configure Timestamp Inserter to start automatically whenever you log in:

- In the app's **Settings...** window (`⌘,`), check **Launch at login**.
- macOS manages this under **System Settings > General > Login Items & Extensions > Open at Login**.

---

## Usage

1. Place your cursor in any editable text field in any app (browser, code editor, terminal, notes, Slack, etc.).
2. Press the global keyboard shortcut:
   ```text
   Control-Option-Command-T (⌃⌥⌘T)
   ```
3. The formatted timestamp is inserted directly into the focused field.

---

## Menu & Settings

Click the **clock icon** in the macOS menu bar to open the menu.

From the menu, you can:
- Quickly switch between common formats (**Compact local**, **UK**, **US**, **Unix timestamp**).
- Toggle **Use UTC time** on or off.
- View your active hotkey.
- Open **Settings...** (`⌘,`) to configure additional options.

In **Settings...**:
- Choose from extended presets (RFC 3339 local, RFC 3339 UTC, RFC 3339 local ms, Email date, European, German, Unix milliseconds).
- Enter a **Custom** `DateFormatter` pattern (e.g. `yyyy/MM/dd HH:mm:ss`).
- Record a custom global keyboard shortcut.
- Toggle **Launch at login**.

### Format Examples

| Format Name | Pattern / Type | Example Output |
| :--- | :--- | :--- |
| **Compact local** | `yyyy-MM-dd-HHmm` | `2026-05-15-2030` |
| **Compact local UTC** | `yyyy-MM-dd-HHmm` | `2026-05-15-1330` |
| **RFC 3339 local** | `yyyy-MM-dd'T'HH:mm:ssXXX` | `2026-05-15T20:30:45+07:00` |
| **RFC 3339 local ms** | `yyyy-MM-dd'T'HH:mm:ss.SSSXXX` | `2026-05-15T20:30:45.123+07:00` |
| **RFC 3339 UTC** | ISO 8601 UTC | `2026-05-15T13:30:45Z` |
| **Unix timestamp** | Seconds since Epoch | `1778851845` |
| **Unix milliseconds**| Milliseconds since Epoch | `1778851845123` |
| **Email date** | `EEE, dd MMM yyyy HH:mm:ss Z` | `Fri, 15 May 2026 20:30:45 +0700` |
| **European** | `dd.MM.yyyy HH:mm:ss` | `15.05.2026 20:30:45` |
| **US** | `MM/dd/yyyy h:mm:ss a` | `05/15/2026 8:30:45 PM` |
| **UK** | `dd/MM/yyyy HH:mm:ss` | `15/05/2026 20:30:45` |

---

## Build From Source

Requirements:
- macOS 12.0 or newer.
- Xcode Command Line Tools (`xcode-select --install`).

Build the app bundle:

```sh
./build.sh
```

The output bundle is generated at:

```text
TimestampInserter/Build/Timestamp Inserter.app
```

Verify code signing and plist:

```sh
codesign --verify --deep --strict --verbose=2 "TimestampInserter/Build/Timestamp Inserter.app"
plutil -lint "TimestampInserter/Build/Timestamp Inserter.app/Contents/Info.plist"
```

Package as release zip:

```sh
./scripts/package.sh
```

---

## Project Structure

```text
.
├── TimestampInserter/
│   ├── Sources/TimestampInserter/main.swift   # Main app source (AppKit, hotkey, menu, settings)
│   ├── AppIcon.icns                          # macOS application icon bundle
│   ├── MenuBarIcon.png                       # Menu bar status item icon (18x18 @1x)
│   ├── MenuBarIcon@2x.png                    # Menu bar status item icon (36x36 @2x)
│   ├── Info.plist                            # Bundle identifiers, version, LSUIElement
│   └── build.sh                              # App compilation and code signing script
├── assets/
│   ├── timestamp-inserter-logo-clean.svg     # Clean vector source for app mark
│   ├── timestamp-inserter-clock-roller-sketches.svg
│   └── timestamp-inserter-icon-sketches.svg
├── scripts/
│   └── package.sh                            # Creates distributable zip archive
├── .github/workflows/
│   └── ci.yml                                # Automated build and GitHub Releases CI
└── README.md
```

---

## Privacy & Security

Timestamp Inserter operates strictly locally:
- It does **not** read text or passwords from your screen or other apps.
- It does **not** inspect or overwrite your system clipboard.
- It does **not** make any network requests or collect telemetry.
- Accessibility permission is used solely to dispatch keystroke events for your chosen timestamp into the active cursor position.

---

## License

MIT. See [LICENSE](LICENSE).
