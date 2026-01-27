# claude-pace

Claude usage tracker with pace calculation. Fetches usage data from Anthropic's OAuth API and calculates whether you're on track for your weekly quota.

## Usage

```bash
# JSON output (default) - for scripting/statuslines
claude-pace

# Human-readable output
claude-pace --pretty

# Force refresh (bypass 5-min cache)
claude-pace --force
```

### Compact statusline mode

Composable flags for a compact statusline bar:

```bash
claude-pace --always-on-7d                          # ●● w:60>57
claude-pace --always-on-5h                          # ●● h:04≈32
claude-pace --always-on-7d --always-on-5h           # ●● w:60>57 h:04≈32
claude-pace --always-on-7d --no-dots                # w:60>57
claude-pace --always-on-7d --units                  # ●● w:3.0>2.2
claude-pace --always-on-7d --remaining              # ●● w:40>43
claude-pace --always-on-7d --units --remaining      # ●● w:4.0>4.8
claude-pace --always-on-7d --pace                   # ●● w:1.05x
claude-pace --always-on-7d --always-on-5h --pace    # ●● w:1.05x h:0.61x
```

| Flag | Description |
|------|-------------|
| `--always-on-7d` | Show weekly window segment |
| `--always-on-5h` | Show 5-hour window segment |
| `--no-dots` | Hide status dots (`●●`) |
| `--units` | Show days/hours instead of percentages |
| `--remaining` | Show remaining instead of used |
| `--pace` | Show pace ratio (e.g. `w:1.05x`) instead of values |

**Format:** `prefix:left<sym>right`

- `prefix` — `w` (weekly) or `h` (5-hour)
- `left` — usage% or elapsed time (flipped with `--remaining`)
- `right` — time% or quota consumed (flipped with `--remaining`)
- `sym` — pace symbol from the table below

**Pace symbols:**

| Symbol | Pace ratio | Meaning |
|--------|-----------|---------|
| `≪` | < 0.5 | Well under pace |
| `<` | 0.5 – 0.8 | Under pace |
| `≈` | 0.8 – 0.9 | On track |
| `>` | 0.9 – 1.2 | Over pace |
| `≫` | > 1.2 | Well over pace |

**Dot colors:** first dot = weekly status, second dot = 5h status.

| Color | Status |
|-------|--------|
| Green (`●`) | on_track / under_pace |
| Yellow (`●`) | over_pace |
| Red (`●`) | critical |

## Output

JSON with two windows:

```json
{
  "five_hour": {
    "pct": 15.2,
    "resets_in": "3h 45m",
    "burn_rate": 12.1,
    "pace_ratio": 0.61,
    "hours_elapsed": 2.5,
    "hours_remaining": 2.5,
    "status": "on_track"
  },
  "seven_day": {
    "pct": 45.0,
    "pace_ratio": 0.95,
    "status": "on_track",
    "days_remaining": 3.2
  }
}
```

**Pace ratio interpretation:**
- `<= 0.8` - under_pace (banking quota)
- `<= 1.0` - on_track (sustainable)
- `<= 1.3` - over_pace (will likely hit limit)
- `> 1.3` - critical (throttle imminent)

## Requirements

- Python 3.10+
- macOS (uses Keychain for Claude Code OAuth token)
- `jq` (optional, for shell parsing)

## Caching

Results are cached for 5 minutes at `~/.cache/claude-pace/usage.json` to minimize API calls.
