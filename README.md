# ccwidgets

CLI widgets for Claude Code and terminal statuslines. Lightweight scripts for displaying Claude usage, git status, and context metrics.

## Preview

![ccwidgets statusline preview](preview.png)

```
●● w:60>57 h:04≈32  │  feat/admin  │  +2 ~1  │  +9 -0
│                         │             │         └─ git-lines (+added -removed)
│                         │             └─────────── git-files (+new ~modified)
│                         └───────────────────────── git branch
└─────────────────────────────────────────────────── claude-pace (quota dots + pace)
```

**claude-pace compact output** (`--always-on-7d --always-on-5h`):

```
●● w:60>57 h:04≈32   # Dots + weekly + 5h (default)
●● w:3.0>2.2         # Units mode (days/hours)
●● w:40>43            # Remaining mode
w:60>57 h:04≈32      # No dots
```

Dots: first=weekly, second=5h. Colors: green (ok), yellow (over_pace), red (critical).
Symbol: `≪` `<` `≈` `>` `≫` based on pace ratio.

## Installation

```bash
# Clone the repo (pick your preferred location)
git clone https://github.com/vittodevit/ccwidgets ~/.local/ccwidgets

# Run installer (creates symlinks in ~/.local/bin)
~/.local/ccwidgets/install.sh
```

The installer will:
1. Create symlinks for all scripts in `~/.local/bin`
2. Check for required dependencies (`python3`, `jq`, `git`)
3. Warn if `~/.local/bin` is not in your PATH

### Manual Installation

If you prefer manual setup:

```bash
# Add to PATH (in ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"

# Create symlinks manually
ln -sf ~/.local/ccwidgets/scripts/claude-pace/claude-pace ~/.local/bin/
ln -sf ~/.local/ccwidgets/scripts/claude-usage-widget/claude-usage-widget.sh ~/.local/bin/
# ... etc
```

## Scripts

| Script | Purpose | Output |
|--------|---------|--------|
| `claude-pace` | Claude API usage + pace calculation | JSON, pretty, or compact statusline |
| `claude-usage-widget.sh` | Compact two-dot indicator | `●●` with colors |
| `context-pct.sh` | Context window percentage | `42%` with colors |
| `git-files.sh` | File status counts | `+3 ~2 -1` |
| `git-lines.sh` | Line diff counts | `+45 -12` |

### ccuse wrapper

All scripts are also available via the `ccuse` command:

```bash
ccuse usage            # → claude-pace --pretty (default)
ccuse usage --force    # → claude-pace --force
ccuse widget           # → claude-usage-widget.sh
ccuse context          # → context-pct.sh
ccuse git-files        # → git-files.sh
ccuse git-lines        # → git-lines.sh
```

## Integration Examples

### ccstatusline

[ccstatusline](https://github.com/anthropics/claude-code) is Claude Code's statusline system.

```yaml
# ~/.config/ccstatusline/config.yaml
sections:
  - name: git-files
    command: git-files.sh
  - name: git-lines
    command: git-lines.sh
  - name: usage
    command: claude-usage-widget.sh
  - name: context
    command: context-pct.sh
    stdin: true
```

### tmux

```bash
# ~/.tmux.conf
set -g status-right '#(git-files.sh) #(claude-usage-widget.sh)'
```

### starship

```toml
# ~/.config/starship.toml
[custom.claude]
command = "claude-usage-widget.sh"
when = true

[custom.git_files]
command = "git-files.sh"
when = "git rev-parse --git-dir 2>/dev/null"
```

### Shell prompt (bash/zsh)

```bash
# Simple integration
PS1='$(git-files.sh) $ '

# With git branch
PS1='$(git branch --show-current 2>/dev/null) $(git-files.sh) $ '
```

## Requirements

- **macOS** (claude-pace uses Keychain for OAuth token)
- **Python 3.10+** (for claude-pace)
- **jq** (for context-pct.sh)
- **Git** (for git-files/git-lines)
- **Bash** (all scripts)

## How It Works

### Claude Usage Tracking

`claude-pace` fetches usage from Anthropic's OAuth API and calculates:

- **pace_ratio**: Your current usage rate vs sustainable rate
  - `<= 0.8` = banking quota (under pace)
  - `<= 1.0` = on track to use full quota
  - `> 0.9` = warning threshold
  - `> 1.25` = critical (would exhaust ~1.4 days early)

- **safety_ratio**: Runway hours vs hours until reset
  - `> 1.5` = comfortable margin
  - `< 1.5` = warning (reduced margin)
  - `< 1.0` = critical (will exhaust before reset)

- **runway_hours**: Hours of usage remaining at current burn rate
- **buffer_hours**: Runway minus hours until reset (negative = danger)
- **burn_rate**: 5-hour window consumption speed (%/hour)

Status is determined by combining both pace and safety metrics. Safety ratio takes priority: even with a low pace_ratio, you'll see critical status if you're projected to exhaust quota before reset.

Results are cached for 5 minutes at `~/.cache/claude-pace/usage.json`.

### Color Coding

All scripts use truecolor (24-bit RGB) for consistent appearance:

| Color | Meaning | RGB |
|-------|---------|-----|
| Green | OK/Good | Various greens |
| Yellow | Attention | `255,200,50` |
| Orange | Warning | `255,165,0` |
| Red | Critical | `255,85,85` |
| Gray | Inactive | ANSI 90 |

## Configuration

### Working Hours (claude-pace)

By default, `claude-pace` calculates runway and safety metrics assuming 18 working hours per day (08:00-02:00). This reflects realistic usage patterns rather than 24/7 availability.

Create `~/.config/claude-pace/config.json` to customize:

```json
{
  "work_start": "08:00",
  "work_end": "02:00"
}
```

- Times use 24h format (`HH:MM`)
- If `work_end` < `work_start`, it's interpreted as next day (overnight work)
- Example: `"08:00"` to `"02:00"` = 18 hours/day

### Early Burst Tolerance

At low utilization (< 10%), pace-based warnings are suppressed. This prevents false alarms from early session bursts when there's plenty of time to recover.

## Customization

Scripts are simple and hackable. Each script folder has its own README with details on thresholds and output format.

To customize thresholds, edit the script directly - they're all single-file with inline documentation.

## Troubleshooting

**"claude-pace: command not found"**
- Ensure `~/.local/bin` is in your PATH
- Run `source ~/.bashrc` or restart your terminal

**"security: SecKeychainSearchCopyNext"**
- You need to be logged into Claude Code (`claude` CLI)
- The OAuth token is stored in macOS Keychain

**Colors look wrong**
- Ensure your terminal supports truecolor (most modern terminals do)
- Check `$TERM` is set to something like `xterm-256color`

## License

MIT

---

<sub>Vibe coded with [Claude Code](https://claude.ai/download) in a single session.</sub>
