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

## Output

JSON with two windows:

```json
{
  "five_hour": {
    "pct": 15.2,
    "resets_in": "3h 45m",
    "burn_rate": 12.1
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
