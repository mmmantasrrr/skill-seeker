#!/usr/bin/env bash
# Skill-Seeker Uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/uninstall.sh | bash
#
# Uninstalls skill-seeker using Claude Code's native plugin system.

set -euo pipefail

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

echo ""
echo "  🔍 Skill-Seeker Uninstaller"
echo "  ============================"
echo ""

# Check for claude CLI
if ! command -v claude &>/dev/null; then
    error "Claude Code CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code/setup"
fi

# Uninstall the plugin
info "Uninstalling skill-seeker plugin..."
if output=$(claude plugin uninstall skill-seeker 2>&1); then
    ok "Plugin uninstalled."
else
    if echo "$output" | grep -qi "not installed\|not found"; then
        warn "Plugin was not installed."
    else
        warn "Could not uninstall plugin: $output"
        info "Try manually in Claude Code: /plugin uninstall skill-seeker"
    fi
fi

# Remove the marketplace
info "Removing skill-seeker marketplace..."
if output=$(claude plugin marketplace remove skill-seeker 2>&1); then
    ok "Marketplace removed."
else
    if echo "$output" | grep -qi "not found\|not added"; then
        warn "Marketplace was not added."
    else
        warn "Could not remove marketplace: $output"
        info "Try manually in Claude Code: /plugin marketplace remove skill-seeker"
    fi
fi

echo ""
ok "skill-seeker has been uninstalled!"
echo ""
info "If you had skills installed via skill-seeker, they remain in ~/.claude/skills/"
info "To remove them: rm -rf ~/.claude/skills/*"
echo ""
