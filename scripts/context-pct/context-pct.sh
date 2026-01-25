#!/bin/bash
# Context percentage with dynamic color (truecolor RGB)
#
# Reads ccstatusline JSON from stdin, extracts context_window.used_percentage,
# and outputs colored percentage based on thresholds.
#
# Thresholds:
#   0%       → gray (no context)
#   1-49%    → green (comfortable)
#   50-69%   → yellow (attention)
#   70-84%   → orange (warning)
#   85%+     → red (critical)

input=$(cat)
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | awk '{printf "%.0f", $1}')

# Truecolor RGB
gray="\033[90m"
green="\033[38;2;80;250;123m"
yellow="\033[38;2;255;255;85m"
orange="\033[38;2;255;165;0m"
red="\033[38;2;255;85;85m"
reset="\033[0m"

if [ "$pct" -eq 0 ]; then
  printf "${gray} 0%%${reset}"
elif [ "$pct" -lt 50 ]; then
  printf "${green}${pct}%%${reset}"
elif [ "$pct" -lt 70 ]; then
  printf "${yellow}${pct}%%${reset}"
elif [ "$pct" -lt 85 ]; then
  printf "${orange}${pct}%%${reset}"
else
  printf "${red}${pct}%%${reset}"
fi
