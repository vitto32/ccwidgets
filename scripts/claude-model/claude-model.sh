#!/bin/bash
# claude-model.sh - Show the active Claude Code model
#
# Priority:
#   1. CLAUDE_MODEL_HINT env var (set by wrapper aliases cco/ccs/cch)
#   2. model.id from ccstatusline JSON (fallback — may be stale due to known bug)
#
# Known issue: Claude Code status bar JSON reports the model from settings config,
# not the active session model. CLAUDE_MODEL_HINT bypasses this.
# See: github.com/anthropics/claude-code/issues/9106
#
# Colors (risk-coded):
#   Opus   → gray   #a1b0b8 — safe/premium (most capable)
#   Sonnet → yellow #f1fa8c — balanced (caution)
#   Haiku  → red    #ff5555 — fast/cheap (higher risk of mistakes)
#   ?      → muted  #a1b0b8

input=$(cat)

if [ -n "$CLAUDE_MODEL_HINT" ]; then
  model_id="$CLAUDE_MODEL_HINT"
else
  model_id=$(echo "$input" | jq -r '.model.id // ""' 2>/dev/null)
fi

gray=$(   printf '\033[38;2;161;176;184m')
yellow=$( printf '\033[38;2;241;250;140m')
red=$(    printf '\033[38;2;255;85;85m')
muted=$(  printf '\033[38;2;161;176;184m')
reset=$(  printf '\033[0m')

effort_suffix=""
if [[ -n "$CLAUDE_EFFORT_HINT" && "$CLAUDE_EFFORT_HINT" != "high" ]]; then
  effort_suffix=" ~"
fi

case "$model_id" in
  *opus*)   printf "${gray}🤖 Opus${effort_suffix}${reset}" ;;
  *sonnet*) printf "${yellow}💻 Sonnet${effort_suffix}${reset}" ;;
  *haiku*)  printf "${red}👶 Haiku${effort_suffix}${reset}" ;;
  *)
    name=$(echo "$input" | jq -r '.model.display_name // "?"' 2>/dev/null)
    printf "${muted}${name}${reset}"
    ;;
esac
