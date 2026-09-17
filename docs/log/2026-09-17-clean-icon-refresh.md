---
title: Clean clock-and-stand app icon refresh
date: 2026-09-17
type: design-log
---

# Clean clock-and-stand app icon refresh

## Why

The original icon read as a clock but did not carry the compact, grounded silhouette from the reference direction. The new mark combines a round clock dial, a rounded L-shaped hand, a sculpted stand, and a separated lower bar.

## What changed

- Added the editable source at `design/timestamp-inserter-logo-clean.svg`.
- Replaced `TimestampInserter/AppIcon.icns` with the monochrome mark.
- Rendered the icon with a transparent background and standard 1024px macOS icon geometry.

## Verification

- SVG parses with `xmllint`.
- App build completes with `./build.sh`.
- The built app contains the replacement icon byte-for-byte.
- Code signature and `Info.plist` validation pass.
