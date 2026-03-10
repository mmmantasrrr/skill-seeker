---
name: seek
description: Search GitHub for community Claude Code skills matching a query
user-invokable: true
args:
  - name: query
    description: What kind of skill to search for (e.g., "frontend design", "terraform", "playwright testing")
    required: true
---

Search GitHub for community-created Claude Code skills matching the user's query.

## Steps

1. Run the search script to find matching repositories:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-github.sh" "<query>"
   ```

2. Present the results to the user in a table format:
   - Repository name and description
   - Stars count and last updated date
   - Trust score (stars + age + known author signals)
   - Number of skills found in the repo

3. Ask the user which repository they want to explore further.

4. If the user picks a repo, suggest using `/skill-seeker:browse <owner/repo>` to see its skills.

## Output Format

Present results as:

```
## Community Skills: "<query>"

| # | Repository | Stars | Updated | Skills | Trust |
|---|-----------|-------|---------|--------|-------|
| 1 | owner/repo - description | 1,234 | 2026-01 | 5 | HIGH |
| ...

Pick a number to browse, or refine your search.
```

## Notes

- Requires `GITHUB_TOKEN` environment variable for authenticated requests (60 req/hr without, 5000 with)
- Results are sorted by relevance score combining stars, recency, and skill count
- Only shows repos with 10+ stars by default
