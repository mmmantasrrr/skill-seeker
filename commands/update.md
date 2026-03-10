---
name: update
description: Check for and apply updates to the skill-seeker plugin
user-invokable: true
args: []
---

Check for new versions of skill-seeker and apply updates.

## Steps

1. Read the current version from plugin.json:
   ```bash
   cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | grep '"version"' | head -1
   ```

2. Fetch the latest version from GitHub (without modifying the working tree):
   ```bash
   cd "${CLAUDE_PLUGIN_ROOT}" && git fetch origin main 2>&1
   ```

3. Check if updates are available:
   ```bash
   cd "${CLAUDE_PLUGIN_ROOT}" && git log HEAD..origin/main --oneline 2>/dev/null
   ```

4. **If no updates**: Report that skill-seeker is already up to date.

5. **If updates available**: Show the user what changed:
   - Number of new commits
   - Summary of changes (commit messages)
   - Ask for confirmation before applying

6. On confirmation, apply the update:
   ```bash
   cd "${CLAUDE_PLUGIN_ROOT}" && git pull origin main 2>&1
   ```

7. Verify the update succeeded by reading the new version:
   ```bash
   cat "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | grep '"version"' | head -1
   ```

8. Report the result:
   - Previous version → new version
   - Suggest restarting Claude Code if there were significant changes

## Output Format

### When up to date:
```
✅ skill-seeker is up to date (v0.2.0)
```

### When updates are available:
```
🔄 Updates available for skill-seeker

Current: v0.1.0
Latest:  v0.2.0

Changes:
- Added update command for easier maintenance
- Improved registry search performance
- Fixed browse mode error handling

Apply update? (yes/no)
```

### After successful update:
```
✅ skill-seeker updated: v0.1.0 → v0.2.0

Restart Claude Code to fully load the updated plugin.
```

## Notes

- Updates are pulled from the main branch via git
- Local modifications (if any) may cause merge conflicts
- The registry.json is also updated, providing access to newly verified skills
- If the update fails, the plugin remains on the current version
