---
name: install
description: Fetch, scan, and install a specific skill from a GitHub repository
user-invokable: true
args:
  - name: target
    description: "Skill location as owner/repo/path (e.g., 'pbakaus/impeccable/.claude/skills/audit/SKILL.md')"
    required: true
---

Fetch a specific skill file from GitHub, run security scanning, and install it locally.

## Steps

1. Parse the target into owner, repo, and path components.

2. Fetch the skill file:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-skill.sh" "<owner>" "<repo>" "<path>"
   ```

3. Run the security scanner on the fetched content:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/scan-skill.py" "/tmp/skill-seeker-cache/<owner>/<repo>/<filename>"
   ```

4. **If scanner reports HIGH or CRITICAL**: Warn the user and show the specific findings. Do NOT proceed without explicit acknowledgment.

5. **If scanner reports CLEAN or LOW**: Show the user a preview (first 30 lines of the file) and the scan results.

6. Ask the user to confirm installation.

7. On confirmation, copy the skill to the local cache:
   ```bash
   mkdir -p ~/.claude/skills-cache/<owner>/<repo>/<skill-name>/
   cp /tmp/skill-seeker-cache/<owner>/<repo>/<filename> ~/.claude/skills-cache/<owner>/<repo>/<skill-name>/SKILL.md
   ```

8. Read the installed skill into the current context using the Read tool.

9. Report success and summarize what the skill provides.

## Security Protocol

**CRITICAL**: Never skip the security scan. Never auto-approve HIGH/CRITICAL findings.

The scanner checks for:
- Prompt injection patterns (instruction overrides, social engineering)
- Tool abuse instructions (shell commands, file access)
- Data exfiltration attempts (sensitive file references)
- Hidden content (HTML comments, invisible text, Unicode tricks)
- Encoded payloads (base64 with suspicious content)
- Frontmatter schema violations

## Notes

- Installed skills are cached in `~/.claude/skills-cache/` (NOT `~/.claude/skills/`)
- This prevents auto-loading in future sessions -- skills must be explicitly re-read
- A SHA256 hash is stored alongside each skill for change detection
