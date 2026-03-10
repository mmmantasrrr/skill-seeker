---
name: reload
description: Quickly load a previously installed skill from the local cache
user-invokable: true
args:
  - name: target
    description: "Skill to reload from cache (e.g., 'pbakaus/impeccable/audit' or just 'impeccable' for auto-match)"
    required: false
---

Load a previously installed skill from `~/.claude/skills-cache/` without re-fetching or re-scanning.

## Steps

1. **If no target specified**: List all cached skills:
   ```bash
   find ~/.claude/skills-cache/ -name "SKILL.md" -type f 2>/dev/null | sed 's|'$HOME'/.claude/skills-cache/||' | sed 's|/SKILL.md$||'
   ```
   Present the list to the user and ask which to reload.

2. **If target specified**: Resolve the target to a full cache path:
   - If target is a full path (owner/repo/skill), use directly
   - If target is partial (e.g., "impeccable"), search for matches in cache
   - If multiple matches found, ask user to clarify

3. Verify the cached skill exists and check its integrity:
   ```bash
   SKILL_PATH="$HOME/.claude/skills-cache/<owner>/<repo>/<skill>/SKILL.md"
   if [[ ! -f "$SKILL_PATH" ]]; then
       echo "Skill not found in cache. Use /skill-seeker:install to fetch it first."
       exit 1
   fi
   ```

4. Check if a SHA256 hash exists for integrity verification:
   ```bash
   HASH_FILE="$HOME/.claude/skills-cache/<owner>/<repo>/<skill>/SKILL.md.sha256"
   if [[ -f "$HASH_FILE" ]]; then
       EXPECTED=$(cat "$HASH_FILE")
       ACTUAL=$(sha256sum "$SKILL_PATH" | cut -d' ' -f1)
       if [[ "$EXPECTED" != "$ACTUAL" ]]; then
           echo "WARNING: Cached skill has been modified since installation."
           echo "Expected: $EXPECTED"
           echo "Actual:   $ACTUAL"
           echo "Re-fetch with /skill-seeker:install for safety, or continue at your own risk."
       fi
   fi
   ```

5. Show a brief preview (first 20 lines) and ask for confirmation.

6. On confirmation, read the skill directly into context using the Read tool.

7. Report success with a summary of what was loaded.

## Benefits of Reload

- **Fast**: No network request, no security scan needed
- **Offline**: Works without internet connection
- **Trusted**: You've already approved this skill in a previous session
- **Consistent**: Same content you used before (verified by SHA256)

## Notes

- Reloading skips the security scan because the skill was already scanned during initial install
- SHA256 integrity check ensures the cached file hasn't been tampered with
- If integrity check fails, re-install the skill for safety
- Cached skills are stored in `~/.claude/skills-cache/` and persist across sessions