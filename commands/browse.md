---
name: browse
description: List all skills available in a specific GitHub repository
user-invokable: true
args:
  - name: repo
    description: GitHub repository in owner/repo format (e.g., "pbakaus/impeccable")
    required: true
---

Browse the skills available in a specific GitHub repository.

## Steps

1. Fetch the repository's file tree to find skill files:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$HOME/.skill-seeker}/scripts/search-github.sh" --browse "<repo>"
   ```

2. Present all discovered skills to the user:
   - Skill name (from YAML frontmatter)
   - Description (from YAML frontmatter)
   - File size and estimated token count
   - File path within the repo

3. Ask the user which skill(s) they want to install.

4. For each selected skill, suggest `/skill-seeker:install <repo>/<path>`.

## Output Format

```
## Skills in <owner/repo>

| # | Skill | Description | Tokens | Path |
|---|-------|------------|--------|------|
| 1 | audit | Run systematic quality checks | ~1,500 | .claude/skills/audit/SKILL.md |
| ...

Pick numbers to install (e.g., "1, 3, 5"), or "all".
```
