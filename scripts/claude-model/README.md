# claude-model

Show the active Claude Code model name with color coding in ccstatusline.

## The problem (why this widget exists)

Claude Code's status bar receives a JSON object via stdin. The `model.id` and
`model.display_name` fields in that JSON reflect the **configured default model**
from `~/.claude/settings.json`, not the model that is actually active in the
session. This means:

- Switching with `/model` at runtime → status bar doesn't update
- Setting `CLAUDE_MODEL=claude-sonnet-4-6` in `.envrc` (direnv) → status bar ignores it
- Running multiple sessions with different models → status bars may show each other's model

**GitHub issues (all closed, none planned for fix):**
- [#9106](https://github.com/anthropics/claude-code/issues/9106) — Status bar shows wrong model name
- [#9651](https://github.com/anthropics/claude-code/issues/9651) — Incorrect model in custom footer
- [#10040](https://github.com/anthropics/claude-code/issues/10040) — /usage shows wrong model
- [#15226](https://github.com/anthropics/claude-code/issues/15226) — Status bar crosstalk in multi-session environments
- [#15467](https://github.com/anthropics/claude-code/issues/15467) — Status line gets wrong model after model switch

## The fix: `CLAUDE_MODEL_HINT`

The workaround is to set `CLAUDE_MODEL_HINT` in the shell **before** launching
Claude Code. Since Claude Code inherits the environment, all its subprocesses
(including ccstatusline and this script) also inherit it.

This widget reads `CLAUDE_MODEL_HINT` first, then falls back to `model.id` from
JSON. The hint is set/unset by the shell launcher functions (see below).

**If these bugs are fixed upstream:** remove `CLAUDE_MODEL_HINT` propagation from
the shell launchers. This script will automatically fall back to `model.id` from
JSON, which will then be accurate.

## Shell launchers (`~/.zshrc`)

Add these functions to your shell config:

```zsh
# Core launcher — called by all named variants
_cc_launch() {
  local model="$1"
  shift
  export CLAUDE_MODEL_HINT="$model"
  command claude --allow-dangerously-skip-permissions --model "$model" "$@"
  local exit_code=$?
  unset CLAUDE_MODEL_HINT
  return $exit_code
}

cco() { _cc_launch claude-opus-4-6            "$@"; }
ccs() { _cc_launch claude-sonnet-4-6          "$@"; }
cch() { _cc_launch claude-haiku-4-5-20251001  "$@"; }

# cc: auto-detects model from $CLAUDE_MODEL (direnv) or local .envrc
cc() {
  local model="${CLAUDE_MODEL:-}"
  if [[ -z "$model" && -f ".envrc" ]]; then
    model=$(grep -E '^export CLAUDE_MODEL=' .envrc 2>/dev/null \
      | head -1 | sed 's/^export CLAUDE_MODEL=//' | tr -d '"'"'")
  fi
  if [[ -n "$model" ]]; then
    _cc_launch "$model" "$@"
  else
    command claude --allow-dangerously-skip-permissions "$@"
  fi
}
```

## Flags

Combine any flags to control output. **Defaults** (no flags): `--emoji --model-short --color`.

| Flag             | Effect                                  |
|------------------|-----------------------------------------|
| `--emoji`        | Show model emoji (🤖 💻 👶)             |
| `--model`        | Show full model name (Opus, Sonnet, Haiku) |
| `--model-short`  | Show short model name (OP, SN, HK)     |
| `--color`        | Enable ANSI color output                |

## Usage

```bash
# Defaults: emoji + short name + color
echo '{}' | claude-model.sh
# → 🤖 OP  (gray)

# Full name, no color
echo '{}' | claude-model.sh --model
# → Opus

# Emoji + full name + color
echo '{}' | claude-model.sh --emoji --model --color
# → 💻 Sonnet  (yellow)

# Just the short code
echo '{}' | claude-model.sh --model-short
# → HK
```

## Output colors

Default text colors:

| Model   | Emoji | Full name | Hex       | Risk level                  |
|---------|-------|-----------|-----------|-----------------------------|
| Opus    | 🤖    | Opus      | `#a1b0b8` | safe/premium (most capable) |
| Sonnet  | 💻    | Sonnet    | `#f1fa8c` | balanced (caution)          |
| Haiku   | 👶    | Haiku     | `#ff5555` | fast/cheap (higher risk)    |
| unknown | —     | —         | `#a1b0b8` | —                           |

Short badge colors:

| Model  | Short | Text      | Background | Notes                          |
|--------|-------|-----------|------------|--------------------------------|
| Opus   | OP    | `#ffffff` | default    | keeps the terminal background  |
| Sonnet | SN    | `#1E1E2E` | `#6CD7CA`  | uses a mint badge              |
| Haiku  | HK    | `#C23128` | `#FFC601`  | uses a gold badge              |

Color logic: red = fast but prone to mistakes, yellow = balanced but watch out,
gray = most capable, safest output quality.

## Integration: ccstatusline

Add as a **Custom Command** widget in ccstatusline's interactive TUI (`bunx ccstatusline@latest`):

```
Command: claude-model.sh
Stdin: enabled   ← required (receives session JSON for fallback)
```

## Dependencies

- `jq`
- Bash
