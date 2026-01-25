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
- Green: pace_ratio <= 1.0
- Yellow: pace_ratio <= 1.2
- Red: pace_ratio > 1.2 (expands to show details)

**Second dot = 5-hour window**
- Green: burn_rate <= 10%/h or reset imminent (<1h)
- Yellow: burn_rate <= 15%/h, OR burn_rate > 15%/h but usage <= 50%
- Red: burn_rate > 15%/h AND usage > 50% (early bursts stay yellow)

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
