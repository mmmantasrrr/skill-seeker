# Installation Testing Report

## Test Environment
- Branch: `claude/fix-skill-seeker-installation-error`
- Testing Date: 2026-03-10
- Changes Made:
  1. Fixed `.claude-plugin/marketplace.json` - added `"source": "./"` field
  2. Fixed `.claude-plugin/plugin.json` - changed repository to string, removed bugs field
  3. Created `uninstall.sh` script
  4. Created `TESTING-DEV-BRANCH.md` guide
  5. Updated README with uninstall instructions

## Changes Summary

### 1. marketplace.json Schema Fix

**Problem:** PR #12 removed the `source` field entirely, but Claude Code's marketplace parser requires it for self-contained plugins.

**Root Cause:** According to Claude Code documentation, self-contained plugins (where the plugin lives in the same repository as the marketplace) must specify `"source": "./"` (with trailing slash).

**Fix Applied:**
```json
{
  "name": "skill-seeker",
  "source": "./",  // ← Added this field
  "description": "...",
  ...
}
```

**Why Previous Fix Failed:**
- Omitting the field entirely: Invalid schema
- Using `"source": "."` (without slash): Parse error
- Using `"source": "./"` (with slash): ✓ Correct

### 2. plugin.json Schema Fix (NEW)

**Problem:** Plugin installation failed with validation errors:
```
repository: Invalid input: expected string, received object
Unrecognized key: "bugs"
```

**Root Cause:** Claude Code's plugin.json schema differs from npm's package.json format. It requires simpler field types.

**Fix Applied:**
```json
// BEFORE (npm package.json style - WRONG for Claude Code):
{
  "repository": {
    "type": "git",
    "url": "https://github.com/mmmantasrrr/skill-seeker"
  },
  "bugs": {
    "url": "https://github.com/mmmantasrrr/skill-seeker/issues"
  }
}

// AFTER (Claude Code plugin.json style - CORRECT):
{
  "repository": "https://github.com/mmmantasrrr/skill-seeker"
  // bugs field removed entirely
}
```

**Key Differences Between npm package.json and Claude Code plugin.json:**

| Field | npm package.json | Claude Code plugin.json |
|-------|------------------|------------------------|
| `repository` | Object: `{"type": "git", "url": "..."}` | String: `"https://github.com/..."` |
| `bugs` | Supported: `{"url": "..."}` | **Not supported** - causes validation error |
| `homepage` | String (supported) | String (supported) ✓ |
| `keywords` | Array (supported) | Array (supported) ✓ |
| `author` | Object/String (supported) | Object with `name` field ✓ |

### 3. Uninstall Script

Created `uninstall.sh` to provide users with an easy way to remove the plugin:

**Features:**
- Uninstalls plugin via Claude CLI
- Removes marketplace entry
- Provides helpful error messages
- Warns about remaining skill files in ~/.claude/skills/
- Can be run via curl one-liner

**Usage:**
```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/uninstall.sh | bash
```

### 3. Development Testing Guide

Created comprehensive `TESTING-DEV-BRANCH.md` with:
- 3 methods for testing dev branches
- Method 1: `--plugin-dir` (fastest, no install)
- Method 2: Marketplace from specific branch
- Method 3: Install script from branch URL
- Verification checklist
- Troubleshooting guide
- Automated testing script
- Cleanup instructions

### 4. README Updates

Added sections for:
- Uninstallation instructions (one-liner + manual)
- Link to development testing guide
- Clear navigation to new features

## Testing Instructions for Users

### Quick Test (No Installation Required)

```bash
# Clone this branch
git clone -b claude/fix-skill-seeker-installation-error https://github.com/mmmantasrrr/skill-seeker.git
cd skill-seeker

# Run Claude with plugin
claude --plugin-dir .
```

Then in Claude Code:
```
/skill-seeker:seek react hooks
```

### Full Installation Test

```bash
# If you have skill-seeker installed, uninstall first
claude plugin uninstall skill-seeker 2>/dev/null || true
claude plugin marketplace remove skill-seeker 2>/dev/null || true

# Install from this branch
claude plugin marketplace add mmmantasrrr/skill-seeker#claude/fix-skill-seeker-installation-error
claude plugin install skill-seeker@skill-seeker
```

Restart Claude Code, then test:
```
/skill-seeker:seek python testing
/skill-seeker:browse anthropics/anthropic-cookbook
/skill-seeker:status
```

### Test Uninstall Script

```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/claude/fix-skill-seeker-installation-error/uninstall.sh | bash
```

Expected output:
- ✓ Plugin uninstalled
- ✓ Marketplace removed
- Info about remaining skill files

## Validation Checklist

- [x] marketplace.json is valid JSON
- [x] marketplace.json has correct "source": "./" field
- [x] plugin.json is valid JSON
- [x] plugin.json has repository as string (not object)
- [x] plugin.json has no "bugs" field
- [x] install.sh has valid bash syntax
- [x] uninstall.sh has valid bash syntax
- [x] uninstall.sh has executable permissions
- [x] README links to new files
- [x] TESTING-DEV-BRANCH.md is comprehensive
- [ ] Tested installation from branch (requires Claude CLI)
- [ ] Tested uninstall script (requires Claude CLI)
- [ ] Verified both marketplace and plugin errors are fixed (requires Claude CLI)

## Expected Outcomes

### Before These Fixes

**Issue 1 - marketplace.json parse error:**
```
❯ /plugin marketplace add mmmantasrrr/skill-seeker
✘ Failed to parse marketplace file at .../marketplace.json: Invalid schema:
plugins.0.source: Invalid input
```

**Issue 2 - plugin.json validation error:**
```
❯ /plugin install skill-seeker@skill-seeker
✘ Failed to install plugin "skill-seeker@skill-seeker": Plugin has an invalid
manifest file at .../.claude-plugin/plugin.json. Validation errors:
repository: Invalid input: expected string, received object
Unrecognized key: "bugs"
```

### After These Fixes
```
❯ /plugin marketplace add mmmantasrrr/skill-seeker
✓ Marketplace added successfully

❯ /plugin install skill-seeker@skill-seeker
✓ Plugin installed successfully

❯ /skill-seeker:seek react hooks
✓ All commands work correctly
```

## Files Changed

1. `.claude-plugin/marketplace.json` - Added `"source": "./"` field
2. `.claude-plugin/plugin.json` - Changed `repository` from object to string, removed `bugs` field
3. `uninstall.sh` - New file (executable)
4. `TESTING-DEV-BRANCH.md` - New comprehensive testing guide
5. `README.md` - Added uninstall section and dev testing link

## Known Limitations

- Cannot test actual installation without Claude CLI in CI environment
- Uninstall script assumes standard Claude Code plugin directory structure
- Testing guide assumes Unix-like environment (bash available)

## Recommendations for User

1. **Test locally first:**
   ```bash
   git clone -b claude/fix-skill-seeker-installation-error https://github.com/mmmantasrrr/skill-seeker.git
   cd skill-seeker
   claude --plugin-dir .
   ```

2. **If that works, test full installation:**
   ```bash
   claude plugin marketplace add mmmantasrrr/skill-seeker#claude/fix-skill-seeker-installation-error
   claude plugin install skill-seeker@skill-seeker
   ```

3. **Verify the fix:**
   - No parse errors during marketplace add
   - Plugin installs successfully
   - All commands work (/seek, /browse, /install, /status)

4. **Test uninstall:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/claude/fix-skill-seeker-installation-error/uninstall.sh | bash
   ```

5. **If all tests pass, merge the PR**

## Questions for User

1. Does the marketplace add without errors now?
2. Does the plugin install successfully?
3. Do all commands work as expected?
4. Does the uninstall script work correctly?
5. Is the testing documentation clear and helpful?

## Additional Notes

### marketplace.json Root Cause

Claude Code's marketplace parser distinguishes between:
- `"source": "."` → Parse error (treated as invalid)
- `"source": "./"` → Success (recognized as relative path)
- No source field → Parse error (required for self-contained plugins)

### plugin.json Root Cause

Claude Code's plugin.json schema differs from npm's package.json:
- **repository field**: Must be a simple string URL, not an object with type/url
- **bugs field**: Not supported - causes "Unrecognized key" validation error
- The plugin system expects a simpler, more streamlined schema

**Why this happened:**
The plugin.json was initially created using npm package.json conventions (with object-style repository and bugs field), but Claude Code's plugin system has its own schema requirements that are stricter and simpler.

Both issues are now documented in the codebase for future reference.
