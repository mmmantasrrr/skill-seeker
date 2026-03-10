# Design Doc: Skill-Seeker Robustness & Discovery Improvements

## Context

TESTING_REPORT.md (v1) identified several issues through a live walkthrough attempting to find and load a skill-writing skill. The issues fell into three categories:

1. **Silent failure** — `gh_api()` returns exit code 0 and valid-looking JSON even when the GitHub API is completely unreachable
2. **Fragile discovery** — The 10-star minimum and single-source (GitHub API) dependency meant niche but highly relevant skills were invisible
3. **No graceful degradation** — When `api.github.com` is blocked (common in CI/CD, corporate, and sandboxed environments), the entire discovery flow breaks with no diagnostic

## Research Inputs

The `claude/research-skill-search-collection` branch researched 6 strategies for improving discovery:
1. Multi-source federation
2. Semantic search with embeddings
3. **Curated registry with community submissions** ← selected for Phase 1
4. Smart query expansion with synonym mapping
5. Local skill cache with background indexing
6. Fuzzy filename matching

The curated registry was chosen as the highest-value, lowest-effort improvement. It solves the "skill not found" problem immediately while providing offline fallback when the GitHub API is unreachable.

## Design Decisions

### 1. `gh_api()` Response Validation

**Problem:** The function used bare `curl -s` which silently returned non-JSON strings (e.g., "Blocked by DNS monitoring proxy") on network errors. The downstream Python script's `try/except (json.JSONDecodeError, KeyError): pass` swallowed these errors, producing `{"total_found": 0}` with exit code 0.

**Solution:**
- Capture HTTP status code via `curl -w "%{http_code}"`
- Write response to temp file for validation before consuming
- Check for: connection failure (code 000), HTTP errors (4xx/5xx), non-JSON responses
- Emit descriptive stderr messages with HINT lines for common issues (rate limit, auth, proxy)
- Set `_API_ERRORS=1` flag for exit code propagation
- Return `'{}'` as safe fallback on error (not the raw broken response)

**Design choice — fail open, not fail closed:** The function returns `'{}'` on error rather than exiting immediately. This allows partial results (e.g., 1 of 3 searches succeeds) to still be useful. The `_API_ERRORS` flag and `api_status` field in the JSON output signal the degraded state.

### 2. `--check` Diagnostic Command

**Problem:** Users had no way to diagnose why search returned zero results. Was it their query? The API? A proxy? Rate limiting?

**Solution:** New `search-github.sh --check` mode that:
- Tests `api.github.com` reachability (GET /zen)
- Tests `raw.githubusercontent.com` reachability (GET a known file)
- Reports GITHUB_TOKEN presence and search rate limit remaining
- Uses emoji indicators (✅/❌/⚠️) for at-a-glance status

### 3. Lower Minimum Stars (10 → 3)

**Problem:** The 10-star minimum filtered out the most relevant results for niche queries. In testing, the only genuine "skill writing" skill had 1 star.

**Solution:** Lower to 3 stars. This still filters out empty/test repos but includes legitimate niche skills. Combined with the trust scoring system (which already deprioritizes low-star repos), this gives users visibility while maintaining quality signals.

### 4. Curated Registry (Strategy 0)

**Problem:** Discovery relied entirely on live GitHub API calls. No offline fallback, no guaranteed results for known skills.

**Solution from research branch:** `registry.json` + `search-registry.sh`

**Enhancement applied:** Replace the 8 placeholder/example entries (repos like `example/playwright-skills` that don't exist) with 13 real, verified skill repositories discovered through live API testing. All entries have been:
- Confirmed to exist on GitHub
- Browsed to verify skill file locations
- Tested with `fetch-skill.sh` to confirm downloadability
- Scanned with `scan-skill.py` for security

**Registry search is Strategy 0** — it runs before GitHub API search and provides:
- Instant results (no network needed)
- Synonym expansion (e.g., "skill writing" → finds "skill-authoring", "skill-creation")
- Offline fallback when API is blocked
- Guaranteed discovery of known high-quality skills

### 5. Two-Layer Seek Command

**Problem:** The `seek.md` command only instructed Claude to run GitHub search.

**Solution:** Updated `seek.md` to instruct Claude to:
1. Search registry first (instant)
2. Search GitHub API second (live)
3. Merge and deduplicate results
4. Present combined results with source attribution
5. Inform user of any API errors while still showing registry results

### 6. Browse Error Handling

**Problem:** When `api.github.com` was blocked, browse mode crashed with `jq: parse error` (exit code 5) — cryptic with no diagnostic.

**Solution:** Validate `gh_api()` response before passing to `jq`. On failure:
- Emit descriptive error message to stderr
- Return valid JSON with `"error"` field and empty `"skills"` array
- Exit with code 1 (not 5)
- Suggest running `--check` for diagnostics

## What Was NOT Changed

- **Security scanner** — No changes needed. Already robust with 34 passing tests.
- **fetch-skill.sh** — Already the most robust component. Uses `raw.githubusercontent.com` which has different (better) accessibility than `api.github.com`.
- **Trust scoring algorithm** — The composite scoring is sound. Only the threshold changed.
- **unload command** — No changes needed.
- **Pre-flight skill (SKILL.md)** — No changes needed.

## Implementation Summary

| File | Change | Lines |
|------|--------|-------|
| `scripts/search-github.sh` | `gh_api()` validation, `--check` mode, browse error handling, min-stars 10→3, exit code propagation | ~105 lines added |
| `registry.json` | Replaced 10 placeholder entries with 13 real verified skills | Full rewrite |
| `commands/seek.md` | Two-layer search (registry + GitHub), error reporting | ~20 lines changed |

## Future Work (Not in This PR)

Per the research document's Phase 2-5 roadmap:
- Phase 2: Multi-source search (GitLab, GitHub Code Search)
- Phase 3: Local caching and offline mode
- Phase 4: Semantic search with embeddings
- Phase 5: Community growth tools and analytics
