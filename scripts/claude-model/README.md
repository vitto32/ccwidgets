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

## Usage

```bash
echo '{"model":{"id":"claude-sonnet-4-6","display_name":"Sonnet"}}' | claude-model.sh
# → 💻 Sonnet  (yellow, from JSON fallback)

CLAUDE_MODEL_HINT=claude-opus-4-6 bash -c 'echo "{}" | claude-model.sh'
# → 🤖 Opus  (gray, from env var)
```

## Output colors

| Model   | Emoji | Color  | Hex       | Risk level                  |
|---------|-------|--------|-----------|-----------------------------|
| Opus    | 🤖    | gray   | `#a1b0b8` | safe/premium (most capable) |
| Sonnet  | 💻    | yellow | `#f1fa8c` | balanced (caution)          |
| Haiku   | 👶    | red    | `#ff5555` | fast/cheap (higher risk)    |
| unknown | —     | muted  | `#a1b0b8` | —                           |

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
