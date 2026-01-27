#!/bin/bash
# ccwidgets installer
# Creates symlinks in ~/.local/bin for all scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

# Colors
green="\033[32m"
yellow="\033[33m"
red="\033[31m"
dim="\033[90m"
reset="\033[0m"

info()  { echo -e "${green}✓${reset} $1"; }
warn()  { echo -e "${yellow}⚠${reset} $1"; }
error() { echo -e "${red}✗${reset} $1"; }

echo "ccwidgets installer"
echo "==================="
echo

# Check dependencies
echo "Checking dependencies..."
missing=()

command -v python3 >/dev/null 2>&1 || missing+=("python3")
command -v jq >/dev/null 2>&1 || missing+=("jq")
command -v git >/dev/null 2>&1 || missing+=("git")

if [ ${#missing[@]} -gt 0 ]; then
    warn "Missing optional dependencies: ${missing[*]}"
    echo "  Some scripts may not work without these."
    echo
fi

# Create bin directory
mkdir -p "$BIN_DIR"

# Function to create symlink
link_script() {
    local src="$1"
    local name="$2"
    local dest="${BIN_DIR}/${name}"

    # Remove existing (file or symlink)
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -f "$dest"
    fi

    ln -sf "$src" "$dest"
    chmod +x "$src"
    info "Linked: $name"
}

echo "Creating symlinks..."

# Link all scripts
link_script "${SCRIPT_DIR}/scripts/claude-pace/claude-pace" "claude-pace"
link_script "${SCRIPT_DIR}/scripts/claude-usage-widget/claude-usage-widget.sh" "claude-usage-widget.sh"
link_script "${SCRIPT_DIR}/scripts/context-pct/context-pct.sh" "context-pct.sh"
link_script "${SCRIPT_DIR}/scripts/git-files/git-files.sh" "git-files.sh"
link_script "${SCRIPT_DIR}/scripts/git-lines/git-lines.sh" "git-lines.sh"

# Link ccuse wrapper
link_script "${SCRIPT_DIR}/ccuse" "ccuse"

echo

# Check PATH
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    warn "${BIN_DIR} is not in your PATH"
    echo
    echo "  Add this to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
fi

info "Installation complete!"
echo
echo "Available commands:"
echo "  claude-pace            - Claude usage tracker"
echo "  claude-usage-widget.sh - Compact usage indicator"
echo "  context-pct.sh         - Context percentage display"
echo "  git-files.sh           - Git file status"
echo "  git-lines.sh           - Git line diff counts"
echo "  ccuse                  - Unified wrapper"
echo
echo "Run 'ccuse --help' to see all commands."
