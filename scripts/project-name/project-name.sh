#!/bin/bash
# project-name.sh - Show current project name in the status line
#
# Priority:
#   1. PROJECT_NAME env var (can be set in .envrc)
#   2. basename of current working directory
#
# Color: muted cyan #8be9fd

name="${PROJECT_NAME:-$(basename "$PWD")}"

cyan=$(printf '\033[38;2;139;233;253m')
reset=$(printf '\033[0m')

printf "${cyan}📂 ${name}${reset}"
