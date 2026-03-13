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
#   Uses status from claude-pace (unified elapsed_tolerance curve).
#   Same inverse-sqrt scaling as weekly — no ad-hoc thresholds.
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

# 5h: use status from claude-pace (unified elapsed_tolerance curve)
five_hour = data.get("five_hour", {})
five_pct = five_hour.get("pct", 0)
five_status = five_hour.get("status", "on_track")

five_expand = ""
if five_status == "critical":
    five_color = "red"
    five_expand = f"5h:{five_pct:.0f}%"
elif five_status == "over_pace":
    five_color = "yellow"
else:
    five_color = "dim_green"

# Output format: weekly_color|weekly_dot|five_color|five_dot|expansion|stale_color|stale_icon
expansion = ""
if weekly_expand:
    expansion = weekly_expand
if five_expand:
    if expansion:
        expansion += " "
    expansion += five_expand

# Stale data detection
stale_color = ""
stale_icon = ""
if data.get("_stale"):
    from datetime import datetime, timezone
    fetched_at = data.get("fetched_at", "")
    stale_color = "yellow"
    if fetched_at:
        try:
            fetched_dt = datetime.fromisoformat(fetched_at)
            age_secs = (datetime.now(timezone.utc) - fetched_dt).total_seconds()
            if age_secs > 3 * 3600:
                stale_color = "red"
        except Exception:
            stale_color = "red"
    stale_icon = "\uf071"

print(f"{weekly_color}|●|{five_color}|●|{expansion}|{stale_color}|{stale_icon}")
PYTHON
)

# Parse output
IFS='|' read -r weekly_color weekly_dot five_color five_dot expansion stale_color stale_icon <<< "$OUTPUT"

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

if [ -n "$stale_icon" ]; then
    s_col=$(get_color "$stale_color")
    printf " ${s_col}%s${reset}" "$stale_icon"
fi
