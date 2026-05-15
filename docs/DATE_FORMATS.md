# Date Formats

Timestamp Inserter uses Apple's `DateFormatter` patterns.

Common tokens:

| Token | Meaning | Example |
| --- | --- | --- |
| `yyyy` | Four-digit year | `2026` |
| `MM` | Two-digit month | `05` |
| `dd` | Two-digit day | `15` |
| `HH` | 24-hour hour | `20` |
| `mm` | Minute | `30` |
| `ss` | Second | `45` |
| `X` | ISO time zone, short | `+07` |
| `XX` | ISO time zone, compact | `+0700` |
| `XXX` | ISO time zone, colon | `+07:00` |

Examples:

```text
yyyy-MM-dd-HHmm      -> 2026-05-15-2030
yyyy-MM-dd-HHmmX     -> 2026-05-15-2030+07
yyyy-MM-dd-HHmmXX    -> 2026-05-15-2030+0700
yyyy-MM-dd-HHmmXXX   -> 2026-05-15-2030+07:00
yyyy-MM-dd HH:mm:ss  -> 2026-05-15 20:30:45
```
