#!/usr/bin/env bash
# Skill-Seeker Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/install.sh | bash
#
# This script installs skill-seeker as a Claude Code plugin.
# It clones the repository into the Claude plugins directory and verifies dependencies.

set -euo pipefail

REPO_URL="https://github.com/mmmantasrrr/skill-seeker.git"
INSTALL_DIR="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/plugins}/skill-seeker"

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

# --- Dependency check ---
check_deps() {
    local missing=()
    for cmd in curl jq python3 git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}. Install them and re-run."
    fi
    ok "All dependencies found (curl, jq, python3, git)"
}

# --- Install ---
install_plugin() {
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "skill-seeker is already installed at $INSTALL_DIR"
        info "To update, run: cd $INSTALL_DIR && git pull"
        info "Or use the plugin command: /skill-seeker:update"
        exit 0
    fi

    info "Installing skill-seeker to $INSTALL_DIR ..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    if [[ -d "$INSTALL_DIR/scripts" ]]; then
        chmod +x "$INSTALL_DIR"/scripts/*.sh
    else
        warn "Scripts directory not found — plugin may not work correctly."
    fi

    ok "skill-seeker installed successfully!"
    echo ""
    info "Restart Claude Code to load the plugin."
    info "Then try: /skill-seeker:seek react hooks"
    echo ""
    info "To update later: /skill-seeker:update"
}

echo ""
echo "  🔍 Skill-Seeker Installer"
echo "  ========================="
echo ""

check_deps
install_plugin
