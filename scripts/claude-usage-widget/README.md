# claude-usage-widget

Compact two-dot status indicator for Claude usage. Designed for terminal statuslines but usable anywhere.

## Usage

```bash
claude-usage-widget.sh
```

## Output

```
●●           # Both windows OK (green dots)
●●           # Weekly yellow, 5h green
●● S:35% (1.3x)  # Weekly critical - shows remaining % and pace
●● 5h:80% 2h     # 5h critical - shows usage and time to reset
```

## Display Logic

**First dot = Weekly (7-day)**

Uses `status` from `claude-pace` (combines pace_ratio + safety_ratio):
- Green: under_pace or on_track
- Yellow: over_pace
- Red: critical (expands to show remaining % and pace)

**Second dot = 5-hour window**

Uses `burn_rate` from `claude-pace` (sustainable = 20%/h):
- Green: burn_rate <= 20%/h or reset imminent (<1h)
- Yellow: burn_rate <= 25%/h, OR burn_rate > 25%/h but usage <= 50%
- Red: burn_rate > 25%/h AND usage > 50% (early bursts stay yellow)

## Dependencies

- `claude-pace` (must be in PATH)
- Python 3.10+
- Bash

## Integration

### ccstatusline (recommended)

```yaml
# ~/.config/ccstatusline/config.yaml
sections:
  - name: usage
    command: claude-usage-widget.sh
```

### tmux

```bash
# .tmux.conf
set -g status-right '#(claude-usage-widget.sh)'
```

### starship

```toml
# starship.toml
[custom.claude]
command = "claude-usage-widget.sh"
when = true
```
