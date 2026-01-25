#!/bin/bash
# git-files.sh - Show git file status counts
#
# Output: +added ~modified -deleted (colored)
# If clean: "✓ clean" (gray)
#
# Colors:
#   green  : added files
#   yellow : modified files
#   red    : deleted files

git status --porcelain 2>/dev/null | awk 'BEGIN{a=0;m=0;d=0}
/^\?\?/||/^A /{a++}
/^.M/||/^M./||/^.R/||/^R./{m++}
/^.D/||/^D./{d++}
END{
  g="\033[1;32m";y="\033[33m";r="\033[31m";n="\033[0m";gr="\033[90m"
  o=""
  if(a>0) o=o sprintf("%s+%d%s ",g,a,n)
  if(m>0) o=o sprintf("%s~%d%s ",y,m,n)
  if(d>0) o=o sprintf("%s-%d%s",r,d,n)
  if(length(o)>0) print o
  else printf "%s✓ clean%s", gr, n
}'
