#!/bin/bash
# claude-model.sh - Show the active Claude Code model
#
# Flags (combine any):
#   --emoji         Show model emoji (🤖 💻 👶)
#   --model         Show full model name (Opus, Sonnet, Haiku)
#   --model-short   Show short model name (OP, SN, HK)
#   --color         Enable ANSI color output
#   --update-check  Append ↑ X.Y.Z when a newer Claude Code version is available
#                   (checks npm, cached for 60 minutes in /tmp/claude-update-cache.json)
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
show_update_check=0
has_flags=0

for arg in "$@"; do
  case "$arg" in
    --emoji)        show_emoji=1;        has_flags=1 ;;
    --model)        show_model=1;        has_flags=1 ;;
    --model-short)  show_model_short=1;  has_flags=1 ;;
    --color)        show_color=1;        has_flags=1 ;;
    --update-check) show_update_check=1; has_flags=1 ;;
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
  white=$(  printf '\033[38;2;255;255;255m')
  ink=$(    printf '\033[38;2;30;30;46m')
  coral=$(  printf '\033[38;2;194;49;40m')
  mint_bg=$( printf '\033[48;2;108;215;202m')
  gold_bg=$( printf '\033[48;2;255;198;1m')
  muted=$(  printf '\033[38;2;161;176;184m')
  reset=$(  printf '\033[0m')
else
  gray="" yellow="" red="" white="" ink="" coral="" mint_bg="" gold_bg="" muted="" reset=""
fi

effort_suffix=""
if [[ -n "$CLAUDE_EFFORT_HINT" && "$CLAUDE_EFFORT_HINT" != "high" ]]; then
  effort_suffix=" ~"
fi

render() {
  local base_color="$1" emoji="$2" name="$3" short="$4" short_style="$5"
  local pieces=()

  if (( show_emoji )); then
    pieces+=("${base_color}${emoji}${reset}")
  fi

  if (( show_model )); then
    pieces+=("${base_color}${name}${reset}")
  fi

  if (( show_model_short )); then
    pieces+=("${short_style}${short}${reset}")
  fi

  if [[ -n "$effort_suffix" ]]; then
    pieces+=("${base_color}${effort_suffix}${reset}")
  fi

  printf '%s' "${pieces[*]}"
}

case "$model_id" in
  *opus*)   render "$gray"   "🤖" "Opus"   "OP" "$white" ;;
  *sonnet*) render "$yellow" "💻" "Sonnet" "SN" "${mint_bg}${ink}" ;;
  *haiku*)  render "$red"    "👶" "Haiku"  "HK" "${gold_bg}${coral}" ;;
  *)
    name=$(echo "$input" | jq -r '.model.display_name // "?"' 2>/dev/null)
    printf "${muted}${name}${reset}"
    ;;
esac

# Update check: compare local version against npm, 60-min cache
if (( show_update_check )); then
  cache_file="/tmp/claude-update-cache.json"
  cache_max=3600
  need_fetch=1
  update_version=""

  if [[ -f "$cache_file" ]]; then
    cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    now=$(date +%s)
    if (( now - cache_mtime < cache_max )); then
      need_fetch=0
      update_version=$(jq -r '.update_version // ""' "$cache_file" 2>/dev/null)
    fi
  fi

  if (( need_fetch )); then
    current=$(claude --version 2>/dev/null | awk '{print $1}')
    latest=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
    update_version=""
    if [[ -n "$current" && -n "$latest" && "$current" != "$latest" ]]; then
      newer=$(printf '%s\n%s' "$current" "$latest" | sort -V | tail -1)
      [[ "$newer" == "$latest" ]] && update_version="$latest"
    fi
    printf '{"update_version":"%s"}\n' "$update_version" > "$cache_file" 2>/dev/null
  fi

  if [[ -n "$update_version" ]]; then
    upd_color=$'\033[38;2;255;200;50m'
    printf " ${upd_color}↑ %s${reset}" "$update_version"
  fi
fi
