# Date Formats

Timestamp Inserter keeps the status menu focused on common choices:

- Compact local
- UK
- US
- Unix timestamp

Additional presets are available in Settings.

The default preset is `Compact local`, which uses `yyyy-MM-dd-HHmm`.

```text
2026-05-15-2030
```

This is compact, local, and naturally sortable. It is not an RFC 3339 or ISO 8601 interchange timestamp.

## Presets

| Preset | Pattern or source | Example |
| --- | --- | --- |
| Compact local | `yyyy-MM-dd-HHmm` | `2026-05-15-2030` |
| UK | `dd/MM/yyyy HH:mm:ss` | `15/05/2026 20:30:45` |
| US | `MM/dd/yyyy hh:mm:ss a` | `05/15/2026 08:30:45 PM` |
| Unix timestamp | Seconds since Unix epoch | `1778851845` |
| Unix milliseconds | Milliseconds since Unix epoch | `1778851845000` |
| RFC 3339 local | `yyyy-MM-dd'T'HH:mm:ssXXX` | `2026-05-15T20:30:45+07:00` |
| RFC 3339 local ms | `yyyy-MM-dd'T'HH:mm:ss.SSSXXX` | `2026-05-15T20:30:45.123+07:00` |
| RFC 3339 UTC | Apple `ISO8601DateFormatter` internet date-time | `2026-05-15T13:30:45Z` |
| Email date | `EEE, dd MMM yyyy HH:mm:ss Z` | `Fri, 15 May 2026 20:30:45 +0700` |

`2026-06-18T12:04:52+07:00` is best described as an RFC 3339 timestamp with a local UTC offset. RFC 3339 is a constrained Internet profile of ISO 8601.

## UTC Time

The `Insert date formats in UTC` setting changes the actual time used for date-based presets and Custom Format.

```text
Compact local, local time: 2026-05-15-2030
Compact local, UTC time:   2026-05-15-1330
```

This does not append a `+0000` suffix to compact formats. It formats the timestamp using UTC wall-clock time. Unix timestamps are unchanged because they are timezone-independent.

## Custom Patterns

Custom formats use Apple's `DateFormatter` patterns.

Common tokens:

| Token | Meaning | Example |
| --- | --- | --- |
| `yyyy` | Four-digit year | `2026` |
| `MM` | Two-digit month | `05` |
| `dd` | Two-digit day | `15` |
| `HH` | 24-hour hour | `20` |
| `mm` | Minute | `30` |
| `ss` | Second | `45` |
| `SSS` | Milliseconds | `123` |
| `'T'` | Literal `T` separator | `T` |
| `X` | ISO time zone, short | `+07` |
| `XX` | ISO time zone, compact | `+0700` |
| `XXX` | ISO time zone, colon | `+07:00` |

Examples:

```text
yyyy-MM-dd-HHmm              -> 2026-05-15-2030
yyyy-MM-dd'T'HH:mm:ssXXX     -> 2026-05-15T20:30:45+07:00
yyyy-MM-dd'T'HH:mm:ss.SSSXXX -> 2026-05-15T20:30:45.123+07:00
yyyy-MM-dd HH:mm:ss          -> 2026-05-15 20:30:45
```

References:

- [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339)
- [W3C Date and Time Formats](https://www.w3.org/TR/NOTE-datetime)
- [Unicode LDML date symbols](https://unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)
