---
name: unload
description: List currently loaded skills and clean up temporary skill files from the current session
user-invokable: true
args: []
---

List skills that have been loaded in this session and clean up temporary files.

## Steps

1. Check for the project-level temp directory:
   ```bash
   ls -la .claude-skills-temp/ 2>/dev/null || echo "No .claude-skills-temp/ directory found"
   ```

2. Check the system-level fetch cache:
   ```bash
   ls -la /tmp/skill-seeker-cache/ 2>/dev/null || echo "No fetch cache found"
   ```

3. Present findings to the user:
   - List any skill files in `.claude-skills-temp/`
   - List any cached files in `/tmp/skill-seeker-cache/`
   - Note which skills were read into context during this session (from conversation history)

4. Ask the user what to clean up:
   - **Clean temp**: Remove `.claude-skills-temp/` contents
   - **Clean cache**: Remove `/tmp/skill-seeker-cache/` contents
   - **Clean both**: Remove both
   - **Keep all**: Don't delete anything

5. On confirmation, clean the selected directories:
   ```bash
   # If cleaning temp:
   rm -rf .claude-skills-temp/*

   # If cleaning cache:
   rm -rf /tmp/skill-seeker-cache/*
   ```

6. Inform the user:
   - Temporary files have been cleaned up
   - Skills already read into context **remain in the conversation history** until the session ends
   - This is a fundamental limitation — context cannot be selectively removed mid-session
   - Starting a new session will give a clean context without any previously loaded skills

## Important Notes

- **Context persistence**: Once a skill's content has been read into the conversation, it stays in the context window for the remainder of the session. The `unload` command cleans up files but cannot remove text from the active context.
- **Session boundary**: The true "unload" happens when the session ends and a new one begins.
- **No auto-load risk**: Skills in `~/.claude/skills-cache/` are NOT auto-loaded. They must be explicitly read each session.
