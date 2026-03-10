#!/usr/bin/env bash
# Skill-Seeker Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/install.sh | bash
#
# This script:
# 1. Clones skill-seeker to ~/.skill-seeker/
# 2. Sets up the skill in the current project's .claude/skills/ directory
#    so Claude Code actually discovers and loads it.

set -euo pipefail

REPO_URL="https://github.com/mmmantasrrr/skill-seeker.git"
INSTALL_DIR="$HOME/.skill-seeker"

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

# --- Clone/update the repo ---
install_repo() {
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Updating existing installation at $INSTALL_DIR ..."
        git -C "$INSTALL_DIR" pull --ff-only origin main 2>/dev/null || \
            git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || \
            warn "Could not update — using existing version."
        ok "skill-seeker is up to date."
    else
        info "Cloning skill-seeker to $INSTALL_DIR ..."
        rm -rf "$INSTALL_DIR"
        git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
        ok "Repository cloned."
    fi

    chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true
}

# --- Set up skill in the current project ---
setup_project_skill() {
    local project_dir=""

    # Find project root (look for .git, package.json, etc.)
    if [[ -d ".git" ]] || [[ -f "package.json" ]] || [[ -f "Cargo.toml" ]] || \
       [[ -f "go.mod" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Makefile" ]]; then
        project_dir="$(pwd)"
    fi

    if [[ -n "$project_dir" ]]; then
        local skills_dir="$project_dir/.claude/skills/seeking-skills"
        mkdir -p "$skills_dir"
        cp "$INSTALL_DIR/skills/seeking-skills/SKILL.md" "$skills_dir/SKILL.md"
        ok "Skill installed to $skills_dir/SKILL.md"
        info "Claude Code will load the seeking-skills skill in this project."
    else
        warn "Not inside a project directory — skipping project-level setup."
    fi

    echo ""
    ok "Installation complete!"
    echo ""
    info "To add skill-seeker to any project, run inside the project:"
    echo ""
    echo "    mkdir -p .claude/skills/seeking-skills"
    echo "    cp ~/.skill-seeker/skills/seeking-skills/SKILL.md .claude/skills/seeking-skills/SKILL.md"
    echo ""
    info "Then start Claude Code in that project — the skill loads automatically."
    info "Try asking: \"Find me a skill for react hooks\""
    echo ""
    info "To update later: cd ~/.skill-seeker && git pull"
}

echo ""
echo "  🔍 Skill-Seeker Installer"
echo "  ========================="
echo ""

check_deps
install_repo
setup_project_skill
