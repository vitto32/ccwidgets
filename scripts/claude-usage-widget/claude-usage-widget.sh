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
# THRESHOLDS (calculated by claude-pace, widget is display-only)
# ============================================================================
#
# WEEKLY (7-day):
#   Uses status from claude-pace (combines pace_ratio + safety_ratio):
#   - "under_pace" / "on_track" → green
#   - "over_pace"               → yellow
#   - "critical"                → red + show details
#
# 5-HOUR:
#   Uses burn_rate from claude-pace (no recalculation)
#   - Sustainable rate = 20%/h (100% / 5h)
#   - burn_rate <= 20%/h  → green (at or below sustainable)
#   - burn_rate <= 25%/h  → yellow (would exhaust in ~4h)
#   - burn_rate > 25%/h   → red ONLY IF pct_used > 50%
#                           (early bursts stay yellow)
#   - time_remaining < 1h → green (reset imminent)
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

# Weekly: use status from claude-pace (combines pace_ratio + safety_ratio)
weekly = data.get("seven_day", {})
weekly_pct = weekly.get("pct", 0)
weekly_remaining = 100 - weekly_pct
pace_ratio = weekly.get("pace_ratio", 0)
weekly_status = weekly.get("status", "on_track")

if weekly_status == "critical":
    weekly_color = "red"
    weekly_expand = f"S:{weekly_remaining:.0f}% ({pace_ratio:.1f}x)"
elif weekly_status == "over_pace":
    weekly_color = "yellow"
    weekly_expand = ""
else:
    weekly_color = "dim_green"
    weekly_expand = ""

# 5h: use burn_rate from claude-pace (no recalculation)
five_hour = data.get("five_hour", {})
five_pct = five_hour.get("pct", 0)
burn_rate = five_hour.get("burn_rate", 0)
resets_in = five_hour.get("resets_in", "0h 0m")

# Parse resets_in only for reset-imminent check
hours_remaining = 0
if "h" in resets_in:
    parts = resets_in.replace("d", " ").replace("h", " ").replace("m", "").split()
    if len(parts) >= 1:
        hours_remaining = int(parts[0])
        if len(parts) >= 2:
            hours_remaining += int(parts[1]) / 60

# Determine 5h color (sustainable = 20%/h)
# Red requires BOTH high burn rate AND >50% used
five_expand = ""
if hours_remaining < 1:
    five_color = "dim_green"
elif burn_rate <= 20:
    five_color = "dim_green"
elif burn_rate <= 25:
    five_color = "yellow"
elif five_pct <= 50:
    five_color = "yellow"
else:
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
