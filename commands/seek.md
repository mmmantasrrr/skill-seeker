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

1. Run the combined search script that merges registry and GitHub results:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-combined.sh" "<query>"
   ```

   **If search-combined.sh doesn't exist yet**, run both scripts separately:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-registry.sh" "<query>"
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/search-github.sh" "<query>"
   ```
   Then merge results, deduplicating by repository name.

2. Present the combined results to the user in a table format:
   - Repository name and description
   - Stars count and last updated date
   - Trust score (stars + age + known author signals)
   - Source (registry or GitHub)

3. Try 3+ query variations if initial results are poor (e.g., "design audit" → "frontend review" → "ui quality")

4. If GitHub search returns a warning about API errors, inform the user and note that registry results are still available.

5. **For HIGH trust verified registry skills**: Consider auto-browsing to show skills directly (collapse seek+browse into one step). Still require user approval for installation.

6. **Otherwise**: Ask the user which repository they want to explore further, then suggest `/skill-seeker:browse <owner/repo>`.

## Output Format

```
## Community Skills: "<query>"

| # | Repository | Stars | Updated | Trust | Source |
|---|-----------|-------|---------|-------|--------|
| 1 | owner/repo - description | 1,234 | 2026-01 | HIGH | registry |
| 2 | owner/repo - description | 456 | 2026-02 | MEDIUM | github |
| ...

Pick a number to browse, or refine your search.
```

## Core Search Pattern

**Steps 3-4 are mandatory checkpoints:**
1. Identify the domain/task category
2. Run search → get candidate repos (try 3+ query variations if needed)
3. **STOP**: Present top results with trust scores to user
4. **WAIT** for user to pick — do NOT proceed autonomously (except auto-browse for HIGH trust)

## Notes

- Registry search is instant (no API calls, works offline)
- GitHub search requires network access and optionally `GITHUB_TOKEN` for higher rate limits
- If GitHub API is unreachable, check connectivity with `search-github.sh --check`
- Results show repos with 3+ stars by default
