# Testing skill-seeker from a Development Branch

This guide explains how to test changes from a development branch before merging to main.

## Method 1: Test Locally with --plugin-dir (Recommended for Quick Testing)

The fastest way to test changes without installing:

```bash
# Clone the specific branch
git clone -b <branch-name> https://github.com/mmmantasrrr/skill-seeker.git
cd skill-seeker

# Run Claude Code with this plugin directory
claude --plugin-dir .
```

**Inside Claude Code:**
```
/skill-seeker:seek react hooks
```

**Pros:**
- No installation required
- Changes immediately available
- Easy to test multiple branches
- No need to uninstall

**Cons:**
- Only works for current session
- Need to specify `--plugin-dir` each time

## Method 2: Install from Development Branch

To test the full installation experience with marketplace integration:

### Step 1: Uninstall Current Version (if installed)

```bash
# Remove existing installation
claude plugin uninstall skill-seeker
claude plugin marketplace remove skill-seeker
```

Or use the uninstall script:
```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/uninstall.sh | bash
```

### Step 2: Add Marketplace from Dev Branch

```bash
# Add marketplace pointing to your dev branch
claude plugin marketplace add mmmantasrrr/skill-seeker#<branch-name>
```

For example, to test this PR's branch:
```bash
claude plugin marketplace add mmmantasrrr/skill-seeker#claude/fix-skill-seeker-installation-error
```

### Step 3: Install Plugin

```bash
claude plugin install skill-seeker@skill-seeker
```

### Step 4: Test Installation

**Restart Claude Code**, then test:
```
/skill-seeker:seek react hooks
```

## Method 3: Test Install Script from Dev Branch

To test the one-line install script from a development branch:

```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/<branch-name>/install.sh | bash
```

For this PR's branch:
```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/claude/fix-skill-seeker-installation-error/install.sh | bash
```

## Verification Checklist

After installation, verify these work correctly:

### 1. Basic Commands
```
/skill-seeker:seek react hooks
/skill-seeker:browse
/skill-seeker:status
```

### 2. Search Functionality
```
# In Claude Code, ask Claude:
"Find me a skill for Python testing"
"Search for frontend design skills"
```

### 3. Installation Flow
```
# Ask Claude to install a skill:
"Install the metaskills-skill-builder skill"
```

### 4. Security Scanning
Check that security scan output appears during installation

### 5. Plugin Marketplace Integration
```
/plugin list
# Should show skill-seeker in the list

/plugin marketplace list
# Should show skill-seeker marketplace
```

## Troubleshooting Dev Branch Testing

### Issue: Marketplace parse error

If you get:
```
Failed to parse marketplace file... plugins.0.source: Invalid input
```

**Solution:** The branch hasn't been updated with the schema fix yet. Try:
1. Check if `.claude-plugin/marketplace.json` has `"source": "./"` field
2. If missing, the branch needs to be updated

### Issue: Old version still active

**Solution:**
```bash
# Force remove cached plugin data
rm -rf ~/.claude/plugins/skill-seeker

# Then reinstall
claude plugin marketplace add mmmantasrrr/skill-seeker#<branch-name>
claude plugin install skill-seeker@skill-seeker
```

### Issue: Changes not reflected

**Solution:**
1. Restart Claude Code completely
2. Check plugin was updated: `/plugin list`
3. Verify correct version in output

## Comparing Branches

To test differences between main and a dev branch:

```bash
# Terminal 1: Test main branch
git clone https://github.com/mmmantasrrr/skill-seeker.git main-test
cd main-test
claude --plugin-dir .

# Terminal 2: Test dev branch
git clone -b <branch-name> https://github.com/mmmantasrrr/skill-seeker.git dev-test
cd dev-test
claude --plugin-dir .
```

Compare behavior side-by-side.

## Automated Testing Script

Save this as `test-branch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-main}"
REPO_URL="https://github.com/mmmantasrrr/skill-seeker.git"

echo "Testing branch: $BRANCH"

# Cleanup
rm -rf /tmp/skill-seeker-test
git clone -b "$BRANCH" "$REPO_URL" /tmp/skill-seeker-test
cd /tmp/skill-seeker-test

echo ""
echo "Validating marketplace.json..."
if command -v jq &>/dev/null; then
    jq empty .claude-plugin/marketplace.json && echo "✓ Valid JSON"
else
    echo "⚠ jq not installed, skipping JSON validation"
fi

echo ""
echo "Validating plugin.json..."
if command -v jq &>/dev/null; then
    jq empty .claude-plugin/plugin.json && echo "✓ Valid JSON"
fi

echo ""
echo "Checking required files..."
for file in .claude-plugin/marketplace.json .claude-plugin/plugin.json install.sh uninstall.sh; do
    if [[ -f "$file" ]]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo ""
echo "Testing with --plugin-dir:"
echo "Run: claude --plugin-dir /tmp/skill-seeker-test"
```

Usage:
```bash
chmod +x test-branch.sh
./test-branch.sh claude/fix-skill-seeker-installation-error
```

## Reporting Issues

When reporting problems with a dev branch, include:

1. Branch name being tested
2. Installation method used (Method 1, 2, or 3)
3. Full error output
4. Output of: `/plugin list` and `/plugin marketplace list`
5. Claude Code version: `claude --version`

## Clean Up After Testing

```bash
# Uninstall test installation
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/uninstall.sh | bash

# Remove test directories
rm -rf /tmp/skill-seeker-test main-test dev-test

# Reinstall stable version (if desired)
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/install.sh | bash
```
