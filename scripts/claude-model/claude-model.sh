#!/bin/bash
# claude-model.sh - Show the active Claude Code model
#
# Flags (combine any):
#   --emoji        Show model emoji (🤖 💻 👶)
#   --model        Show full model name (Opus, Sonnet, Haiku)
#   --model-short  Show short model name (OP, SN, HK)
#   --color        Enable ANSI color output
#
# Defaults (no flags): --emoji --model-short --color
#
# Model source priority:
#   1. CLAUDE_MODEL_HINT env var (set by wrapper aliases cco/ccs/cch)
#   2. model.id from ccstatusline JSON (fallback — may be stale)
#
# Colors (risk-coded):
#   Opus   → gray   #a1b0b8 — safe/premium (most capable)
#   Sonnet → yellow #f1fa8c — balanced (caution)
#   Haiku  → red    #ff5555 — fast/cheap (higher risk of mistakes)

show_emoji=0
show_model=0
show_model_short=0
show_color=0
has_flags=0

for arg in "$@"; do
  case "$arg" in
    --emoji)       show_emoji=1;       has_flags=1 ;;
    --model)       show_model=1;       has_flags=1 ;;
    --model-short) show_model_short=1; has_flags=1 ;;
    --color)       show_color=1;       has_flags=1 ;;
  esac
done

if (( ! has_flags )); then
  show_emoji=1
  show_model_short=1
  show_color=1
fi

input=$(cat)

if [ -n "$CLAUDE_MODEL_HINT" ]; then
  model_id="$CLAUDE_MODEL_HINT"
else
  model_id=$(echo "$input" | jq -r '.model.id // ""' 2>/dev/null)
fi

if (( show_color )); then
  gray=$(   printf '\033[38;2;161;176;184m')
  yellow=$( printf '\033[38;2;241;250;140m')
  red=$(    printf '\033[38;2;255;85;85m')
  muted=$(  printf '\033[38;2;161;176;184m')
  reset=$(  printf '\033[0m')
else
  gray="" yellow="" red="" muted="" reset=""
fi

effort_suffix=""
if [[ -n "$CLAUDE_EFFORT_HINT" && "$CLAUDE_EFFORT_HINT" != "high" ]]; then
  effort_suffix=" ~"
fi

render() {
  local color="$1" emoji="$2" name="$3" short="$4"
  local parts=()
  (( show_emoji ))       && parts+=("$emoji")
  (( show_model ))       && parts+=("$name")
  (( show_model_short )) && parts+=("$short")
  local out="${parts[*]}${effort_suffix}"
  printf "${color}${out}${reset}"
}

case "$model_id" in
  *opus*)   render "$gray"   "🤖" "Opus"   "OP" ;;
  *sonnet*) render "$yellow" "💻" "Sonnet" "SN" ;;
  *haiku*)  render "$red"    "👶" "Haiku"  "HK" ;;
  *)
    name=$(echo "$input" | jq -r '.model.display_name // "?"' 2>/dev/null)
    printf "${muted}${name}${reset}"
    ;;
esac
