# Contributing

Thanks for considering a contribution to Timestamp Inserter.

## Development Setup

Requirements:

- macOS 12 or newer.
- Xcode Command Line Tools.

Build locally:

```sh
./build.sh
```

The built app appears at:

```text
TimestampInserter/Build/Timestamp Inserter.app
```

## Pull Requests

Before opening a pull request:

1. Keep changes focused.
2. Build the app locally with `./build.sh`.
3. Verify the generated app bundle:

```sh
codesign --verify --deep --strict --verbose=2 "TimestampInserter/Build/Timestamp Inserter.app"
plutil -lint "TimestampInserter/Build/Timestamp Inserter.app/Contents/Info.plist"
```

## Code Style

- Keep the app dependency-free.
- Prefer native AppKit, Carbon hotkey registration, and Core Graphics event APIs.
- Keep UI minimal and predictable.
- Do not introduce clipboard use unless it is explicitly optional.
