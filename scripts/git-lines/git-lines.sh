#!/bin/bash
# git-lines.sh - Show git diff line counts
#
# Output: +added -removed (colored)
# If no changes: empty output
#
# Colors:
#   green : added lines
#   red   : removed lines

git diff --numstat 2>/dev/null | awk '{a+=$1;d+=$2}END{
  g="\033[1;32m";r="\033[31m";n="\033[0m"
  if(a>0||d>0) printf "%s+%d%s %s-%d%s", g, a, n, r, d, n
}'
