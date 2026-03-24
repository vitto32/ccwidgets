#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${SCRIPT_DIR}/claude-pace"

output=$(python3 - "$TARGET" <<'PY'
import contextlib
import io
import runpy
import sys

target = sys.argv[1]
ns = runpy.run_path(target, run_name="claude_pace_test")
pretty_print = ns["pretty_print"]

data = {
    "seven_day": {
        "pct": 35.0,
        "pace_ratio": 0.56,
        "status": "under_pace",
        "safety_ratio": 3.13,
        "runway_hours": 146.9,
        "buffer_hours": 100.1,
        "projected_eow": 55.7,
        "days_remaining": 2.6,
        "working_hours_remaining": 46.9,
        "working_hours_per_day": 18.0,
    },
    "five_hour": {
        "pct": 100.0,
        "resets_in": "0h 30m",
        "burn_rate": 22.2,
        "pace_ratio": 1.11,
        "hours_elapsed": 4.5,
        "hours_remaining": 0.5,
        "status": "critical",
    },
}

buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    pretty_print(data)

sys.stdout.write(buf.getvalue())
PY
)

red_100=$'\033[38;2;255;85;85m100%\033[0m'

if [[ "$output" != *"$red_100"* ]]; then
  printf 'FAIL exhausted 5h usage should be red\n' >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

if [[ "$output" == *"Safe rate:"* ]]; then
  printf 'FAIL exhausted 5h usage should not show safe rate\n' >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

printf 'PASS claude-pace exhausted 5h critical state\n'
