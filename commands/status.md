---
name: status
description: Show loaded skills and context budget information for the current session
user-invokable: true
args: []
---

Display information about skills loaded in the current session and context budget usage.

## Steps

1. Review the conversation history to identify skills that were read into context:
   - Search for file reads from `~/.claude/skills-cache/`
   - Search for file reads from `.claude-skills-temp/`
   - Search for file reads from `/tmp/skill-seeker-cache/`
   - Note any skill installations that occurred during this session

2. For each loaded skill, provide:
   - Skill name (from frontmatter if available)
   - Source repository
   - Approximate token count (file size / 4 as rough estimate)
   - When it was loaded in this session

3. Calculate and display:
   - Total number of skills loaded
   - Estimated total token budget consumed by skills
   - Percentage of context used (assuming 200k context window)

4. Show cache status:
   - List skills available in `~/.claude/skills-cache/` (can be quickly reloaded)
   - Number of cached skills

## Output Format

```
## Active Skills (Current Session)

| Skill | Repository | Tokens | Loaded |
|-------|-----------|--------|--------|
| Impeccable Design | pbakaus/impeccable | ~2,400 | 10:32 AM |
| Skill Builder | metaskills/skill-builder | ~3,800 | 10:45 AM |

**Total**: 2 skills, ~6,200 tokens (~3% of context)

## Cached Skills (Available for Quick Reload)

- pbakaus/impeccable/audit
- metaskills/skill-builder/reference
- blader/humanizer/writing

Use `/skill-seeker:reload <skill>` to load from cache.
```

## Notes

- Token counts are estimates based on file size (1 token ≈ 4 characters)
- Skills remain in context until the session ends
- Cached skills can be reloaded without re-fetching or re-scanning