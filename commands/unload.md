---
name: unload
description: Clean up temporary skill files from the current session
user-invokable: true
args: []
---

Clean up temporary skill files. Note: Skills already in context remain until the session ends.

## Steps

1. Check for temporary files:
   ```bash
   ls -la .claude-skills-temp/ /tmp/skill-seeker-cache/ 2>/dev/null
   ```

2. Ask the user what to clean: temp, cache, both, or nothing.

3. On confirmation, clean selected directories:
   ```bash
   rm -rf .claude-skills-temp/*      # Project temp
   rm -rf /tmp/skill-seeker-cache/*  # Fetch cache
   ```

4. Note: Files are cleaned, but skills already read into context remain until session ends. Use `/skill-seeker:status` to see loaded skills.
