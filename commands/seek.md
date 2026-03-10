---
name: seek
description: Search GitHub for community Claude Code skills matching a query
user-invokable: true
args:
  - name: query
    description: What kind of skill to search for (e.g., "frontend design", "terraform", "playwright testing")
    required: true
---

Search for community-created Claude Code skills matching the user's query using a two-layer search: curated registry first, then live GitHub API.

## Steps

1. Search the curated registry for instant results:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-registry.sh" "<query>"
   ```

2. Search GitHub for additional results:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-github.sh" "<query>"
   ```

3. Merge results from both sources, deduplicating by repository name.

4. Present the combined results to the user in a table format:
   - Repository name and description
   - Stars count and last updated date
   - Trust score (stars + age + known author signals)
   - Source (registry or GitHub)

5. If the GitHub search returns a warning about API errors, inform the user and note that registry results are still available.

6. Ask the user which repository they want to explore further.

7. If the user picks a repo, suggest using `/skill-seeker:browse <owner/repo>` to see its skills.

## Output Format

Present results as:

```
## Community Skills: "<query>"

| # | Repository | Stars | Updated | Trust | Source |
|---|-----------|-------|---------|-------|--------|
| 1 | owner/repo - description | 1,234 | 2026-01 | HIGH | registry |
| 2 | owner/repo - description | 456 | 2026-02 | MEDIUM | github |
| ...

Pick a number to browse, or refine your search.
```

## Notes

- Registry search is instant (no API calls, works offline)
- GitHub search requires network access and optionally `GITHUB_TOKEN` for higher rate limits
- If GitHub API is unreachable, check connectivity with `search-github.sh --check`
- Results show repos with 3+ stars by default
