#!/bin/bash
# git-lines.sh - Show git diff line counts
#
# Output: +added -removed (colored)
# If no changes: empty output
#
# Colors (Claude Code palette):
#   #39A660 : added lines
#   #B2596B : removed lines

git diff --numstat 2>/dev/null | awk '{a+=$1;d+=$2}END{
  g="\033[38;2;57;166;96m";r="\033[38;2;178;89;107m";n="\033[0m";gr="\033[90m"
  if(a>0||d>0) printf "%s+%d%s %s-%d%s", g, a, n, r, d, n
  else printf "%s±0%s", gr, n
}'
