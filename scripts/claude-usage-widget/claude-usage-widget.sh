#!/bin/bash
# claude-usage-widget.sh - Compact Claude usage indicator for ccstatusline
#
# ============================================================================
# DISPLAY LOGIC
# ============================================================================
#
# Layout: Two dots (weekly, 5h) + optional expansion when critical
#
# DOTS (always visible):
#   ●●  ← first dot = weekly status, second dot = 5h status
#
# COLORS:
#   - Dim green   : ok (under_pace, on_track)
#   - Yellow      : attention (slightly over pace)
#   - Red         : critical (significantly over pace)
#
# EXPANSION (only when critical):
#   Weekly critical: ●🔴 S:65% (1.3x)  ← remaining % + pace_ratio
#   5h critical:     ●● 5h:80% 3h      ← usage % + time to reset
#
# ============================================================================
# THRESHOLDS
# ============================================================================
#
# WEEKLY (7-day):
#   - pace_ratio <= 1.0  → green (on track)
#   - pace_ratio <= 1.2  → yellow (attention)
#   - pace_ratio > 1.2   → red + show details
#
# 5-HOUR:
#   Uses "intensity" = burn rate relative to time remaining
#   - burn_rate = pct_used / hours_elapsed_in_window
#   - Thresholds:
#     - burn_rate <= 10%/h  → green
#     - burn_rate <= 15%/h  → yellow
#     - burn_rate > 15%/h   → red ONLY IF pct_used > 50%
#                             (early bursts stay yellow, real danger needs both)
#     - time_remaining < 1h → green (reset imminent)
#
# ============================================================================

# Get usage data (uses cache if fresh)
DATA=$(claude-pace 2>/dev/null || echo '{}')

# Colors (truecolor RGB)
dim_green="\033[38;2;100;160;100m"   # muted green for "ok"
yellow="\033[38;2;255;200;50m"       # warm yellow for attention
red="\033[38;2;255;85;85m"           # vivid red for critical
gray="\033[90m"                       # fallback/error
reset="\033[0m"

# Parse data with Python for reliability
OUTPUT=$(python3 - "$DATA" << 'PYTHON'
import json
import sys

try:
    data = json.loads(sys.argv[1])
except:
    # Fallback if no data
    print("gray|●|gray|●|")
    sys.exit(0)

# Weekly calculations
weekly = data.get("seven_day", {})
weekly_pct = weekly.get("pct", 0)
weekly_remaining = 100 - weekly_pct
pace_ratio = weekly.get("pace_ratio", 0)

if pace_ratio <= 1.0:
    weekly_color = "dim_green"
    weekly_expand = ""
elif pace_ratio <= 1.2:
    weekly_color = "yellow"
    weekly_expand = ""
else:
    weekly_color = "red"
    weekly_expand = f"S:{weekly_remaining:.0f}% ({pace_ratio:.1f}x)"

# 5-hour calculations
five_hour = data.get("five_hour", {})
five_pct = five_hour.get("pct", 0)
resets_in = five_hour.get("resets_in", "0h 0m")

# Parse resets_in to get hours remaining
hours_remaining = 0
if "d" in resets_in:
    parts = resets_in.replace("d", " ").replace("h", " ").replace("m", "").split()
    if len(parts) >= 2:
        hours_remaining = int(parts[0]) * 24 + int(parts[1])
elif "h" in resets_in:
    parts = resets_in.replace("h", " ").replace("m", "").split()
    if len(parts) >= 1:
        hours_remaining = int(parts[0])
        if len(parts) >= 2:
            hours_remaining += int(parts[1]) / 60

# Calculate burn rate: how much % per hour we're consuming
# hours_elapsed = 5 - hours_remaining
hours_elapsed = 5 - hours_remaining
if hours_elapsed <= 0:
    hours_elapsed = 0.1
burn_rate = five_pct / hours_elapsed  # %/hour

# Determine 5h status
# Red requires BOTH high burn rate AND >50% used (early bursts are ok)
five_expand = ""
if hours_remaining < 1:
    # Reset imminent, don't worry
    five_color = "dim_green"
elif burn_rate <= 10:
    five_color = "dim_green"
elif burn_rate <= 15:
    five_color = "yellow"
elif five_pct <= 50:
    # High burn rate but still under 50% - just yellow, early burst is ok
    five_color = "yellow"
else:
    # High burn rate AND over 50% - real danger
    five_color = "red"
    five_expand = f"5h:{five_pct:.0f}%"

# Output format: weekly_color|weekly_dot|five_color|five_dot|expansion
expansion = ""
if weekly_expand:
    expansion = weekly_expand
if five_expand:
    if expansion:
        expansion += " "
    expansion += five_expand

print(f"{weekly_color}|●|{five_color}|●|{expansion}")
PYTHON
)

# Parse output
IFS='|' read -r weekly_color weekly_dot five_color five_dot expansion <<< "$OUTPUT"

# Map color names to ANSI
get_color() {
    case "$1" in
        dim_green) echo -e "$dim_green" ;;
        yellow)    echo -e "$yellow" ;;
        red)       echo -e "$red" ;;
        *)         echo -e "$gray" ;;
    esac
}

# Build output
w_col=$(get_color "$weekly_color")
f_col=$(get_color "$five_color")

printf "${w_col}●${reset}${f_col}●${reset}"

if [ -n "$expansion" ]; then
    # Use red for expansion text (use %s to avoid % in expansion being interpreted)
    printf " ${red}%s${reset}" "$expansion"
fi
