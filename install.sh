#!/usr/bin/env bash
# Skill-Seeker Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/install.sh | bash
#
# Installs skill-seeker using Claude Code's native plugin system.

set -euo pipefail

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

echo ""
echo "  🔍 Skill-Seeker Installer"
echo "  ========================="
echo ""

# Check for claude CLI
if ! command -v claude &>/dev/null; then
    error "Claude Code CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code/setup"
fi

# Check dependencies used by skill-seeker scripts
missing=()
for cmd in curl jq python3; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing optional dependencies: ${missing[*]}"
    info "Install them for full functionality (search + security scanning)."
fi

# Add the marketplace and install the plugin
info "Adding skill-seeker marketplace..."
if output=$(claude plugin marketplace add mmmantasrrr/skill-seeker 2>&1); then
    ok "Marketplace added."
else
    if echo "$output" | grep -qi "already"; then
        ok "Marketplace already added."
    else
        warn "Could not add marketplace: $output"
        info "Try manually in Claude Code: /plugin marketplace add mmmantasrrr/skill-seeker"
    fi
fi

info "Installing skill-seeker plugin..."
if output=$(claude plugin install skill-seeker@skill-seeker 2>&1); then
    ok "Plugin installed."
else
    if echo "$output" | grep -qi "already"; then
        ok "Plugin already installed."
    else
        error "Installation failed: $output\nTry manually in Claude Code: /plugin install skill-seeker@skill-seeker"
    fi
fi

echo ""
ok "skill-seeker installed!"
echo ""
info "Open Claude Code and try: /skill-seeker:seek react hooks"
info "Or ask Claude to find you a skill for any domain."
echo ""
info "To update later, Claude Code handles it automatically."
info "Or run: /plugin marketplace update skill-seeker"
