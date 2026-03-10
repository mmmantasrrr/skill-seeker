# Skill-Seeker Testing Report

## Test Objective

Invoke the skill-seeker skill end-to-end to search for, fetch, and evaluate a **skill-writing skill** — a meta-skill that teaches how to create Claude Code skills. This report documents what went well, what could be improved, and provides a hermeneutic analysis of the user experience flow.

---

## Test Execution Summary

### Query Used
**"skill writing"** — searching for skills that help users write/create new Claude Code skills.

### Flow Tested
```
1. Search GitHub for skill-writing skills (search-github.sh)
2. Browse a candidate repository (search-github.sh --browse)
3. Fetch the skill file (fetch-skill.sh)
4. Run security scan (scan-skill.py)
5. Review scan results and preview content
```

### Skill Found
**John-Dekka/advanced-skill-builder** — An interactive guide for creating production-ready Claude skills through structured dialogue.

---

## What Went Well ✅

### 1. Security Scanner is Thorough and Well-Designed
The 9-category scanner (`scan-skill.py`) provides comprehensive coverage against prompt injection attacks. The test suite covers all categories including instruction overrides, tool abuse, data exfiltration, hidden content, social engineering, encoded payloads, Unicode tricks, conversation injection, and frontmatter abuse. All 34 tests pass after fixes.

### 2. Code Block Awareness Prevents False Positives
The scanner correctly skips pattern matching inside fenced code blocks. This is critical because many legitimate skills include bash command examples. The `skip_in_codeblocks` flag on `TOOLABUSE_001` rules demonstrates good engineering judgment.

### 3. Fetch Script Has Sensible Defaults
- Automatic branch fallback (`main` → `master`)
- File size validation and warnings for large files (>50KB)
- SHA256 hash stored alongside fetched content for change detection
- Metadata JSON with timestamp and token estimate

### 4. Multi-Strategy Search Approach
The search script uses three complementary search strategies (topic-targeted, broad topic, description search), which maximizes discovery coverage. The deduplication and trust scoring in the embedded Python script are well-implemented.

### 5. Human-in-the-Loop is Properly Enforced
The SKILL.md, install.md, and seek.md all emphasize mandatory user confirmation checkpoints. Steps 3-4 in the core pattern are explicitly called out as mandatory.

### 6. Trust Scoring is Nuanced
The logarithmic star scaling (preventing mega-repo bias), recency scoring, and multi-signal composite scoring give users meaningful information for making informed decisions.

---

## Bugs Found and Fixed 🐛

### Critical: `search-github.sh` — Wrong Function Name (5 occurrences)
**Severity**: Blocker — the entire search and browse functionality was broken.

The script defines `gh_api()` at line 12 but calls `call_github_api()` at lines 28, 42, 97, 100, and 103. This caused immediate failure:
```
scripts/search-github.sh: line 97: call_github_api: command not found
```

**Fix**: Changed all 5 occurrences of `call_github_api` to `gh_api`.

### Critical: Test Function Name Mismatches (2 functions)
**Severity**: Blocker — all 34 tests failed.

The test file references functions that don't exist in the scanner:
- `scan_skill.scan()` → should be `scan_skill.scan_skill_file()`
- `scan_skill.identify_codeblocks()` → should be `scan_skill.find_code_block_lines()`

**Fix**: Updated all 3 references in `tests/test_scan_skill.py`.

### Moderate: `metadata` Missing from Allowed Frontmatter Keys
**Severity**: False positive — legitimate skills flagged as suspicious.

The scanner's `ALLOWED_FRONTMATTER_KEYS` set did not include `metadata`, which is used by real-world skills (e.g., `John-Dekka/advanced-skill-builder`) for author info, versioning, and categorization.

**Fix**: Added `"metadata"` to the allowed keys set.

---

## What Could Be Even Better 🔧

### 1. Error Handling in Search Script
When the GitHub API returns an error (rate limiting, auth failure), the search script silently passes empty JSON to the Python scoring script, which returns `{"total_found": 0, "results": []}`. This gives the user **no feedback** about why no results were found.

**Recommendation**: Add HTTP status code checking to `gh_api()` and surface clear error messages:
```bash
gh_api() {
    local url="$1"
    local response http_code
    # ... capture http_code and check for 403 (rate limited), 401 (bad token), etc.
}
```

### 2. Browse Mode Fails Silently on API Errors
The `--browse` mode pipes API responses directly into `jq` without checking if the response is valid JSON. When unauthenticated or rate-limited, this produces a cryptic `jq: parse error` instead of a helpful message.

**Recommendation**: Validate API responses before parsing.

### 3. No Offline/Cached Search Fallback
If the user has no `GITHUB_TOKEN` and hits rate limits, the entire skill discovery flow stops. There's no fallback to previously cached results or a curated list of popular skill repositories.

**Recommendation**: Include a small curated index of well-known skill repositories (e.g., `K-Dense-AI/claude-scientific-skills` with 14k+ stars) that can be browsed without API calls.

### 4. Token Budget Warning in Install Flow
The install command (`install.md`) doesn't mention checking the skill's token count against budget guidelines before reading into context. The SKILL.md mentions token budgets (2k for focused, 3.5k for reference, 8k for meta-skills) but the install flow doesn't enforce them.

**Recommendation**: Add a token budget check in the install flow that warns before loading large skills.

### 5. No `--dry-run` or Preview Mode for Search
Users can't preview what search terms will match before committing to API calls. This wastes rate limit quota.

**Recommendation**: Consider a `--dry-run` flag that shows the constructed search URLs without executing them, or a verbose mode that logs each API call.

### 6. Frontmatter Validation Could Be More Flexible
The allowlist approach for frontmatter keys is brittle. New legitimate fields (like `metadata`) require scanner updates. Real-world skills may use custom fields for their own tooling.

**Recommendation**: Consider a denylist approach (flag known-dangerous keys like `system_prompt`, `override`, `injection`) rather than an allowlist, or at least reduce the severity from MEDIUM to LOW for unknown keys.

---

## Hermeneutic Analysis: Flow & User Experience

### The Circle of Understanding

From a hermeneutic perspective, the skill-seeker operates through an **iterative circle of understanding**:

1. **Pre-understanding**: The user arrives with a vague sense of what they need ("I need help with skill writing")
2. **Discovery**: The search reveals what exists in the ecosystem, expanding the user's horizon
3. **Selection**: The user interprets results through their own needs, narrowing from many to one
4. **Examination**: The security scan and preview create a new understanding of the skill's content
5. **Integration**: Loading the skill into context transforms both the user's capabilities and their understanding of what's possible
6. **Application**: Using the loaded skill reveals new questions, potentially triggering another cycle

This circular flow is well-designed. The mandatory checkpoints at steps 3-4 (present results → wait for selection) honor the user's interpretive agency rather than assuming the system knows best.

### The Horizon of Trust

The trust scoring system creates a **fusion of horizons** between:
- **Quantitative signals** (stars, forks, recency) — the community's judgment
- **Qualitative signals** (topics, license, description) — the author's intentionality
- **User judgment** — the final arbiter

This three-layer trust model is philosophically sound. However, there's a gap: the trust score only speaks to the **repository's credibility**, not the **skill's relevance to the user's task**. A HIGH trust repo might contain skills irrelevant to the query. The search could benefit from content-level relevance scoring.

### The Hermeneutic Gap: From Search to Understanding

The weakest point in the user experience is the **transition from search results to understanding what a skill actually does**. Currently:

1. **Search results** show: repo name, description, stars, trust level
2. **Browse** shows: skill names, file sizes, token counts, paths
3. **Install** shows: first 30 lines preview + scan results

The gap is between step 1 (I see a repo exists) and step 3 (I can preview the content). The user must make a commitment to browse and then install before they can truly understand what a skill offers. This creates an **interpretive burden** — the user must invest effort before gaining understanding.

**Recommendation**: Consider adding a "summary" or "quick peek" feature in browse mode that fetches and displays each skill's frontmatter description inline, so users can understand skill purpose without the full install ceremony.

### Temporal Dimension: The Session Boundary

The skill lifecycle has an interesting temporal tension. Skills exist in three time horizons:

1. **Ephemeral** (`/tmp/skill-seeker-cache/`) — exists only until reboot
2. **Persistent but dormant** (`~/.claude/skills-cache/`) — survives sessions but doesn't auto-load
3. **Active but bounded** (context window) — loaded but only for this session

This tri-temporal design is excellent. It prevents the "skill accumulation" problem where loading too many skills degrades performance over time. However, the **re-read ceremony** (manually loading a cached skill each session) could feel burdensome for frequently-used skills.

### The Dialogue Structure

The command structure (`seek` → `browse` → `install` → `unload`) follows a natural conversational rhythm that mirrors how humans discover and adopt new knowledge:

1. **Seek** = "What's out there?" (exploration)
2. **Browse** = "What does this one have?" (investigation)
3. **Install** = "Let me try this" (commitment)
4. **Unload** = "I'm done with this" (closure)

This four-phase structure is intuitive and mirrors the natural learning cycle. The naming is clear and the progression is logical.

---

## Test Results Summary

| Component | Status | Notes |
|-----------|--------|-------|
| `search-github.sh` (search mode) | ✅ Fixed | Was broken — `call_github_api` not defined |
| `search-github.sh` (browse mode) | ✅ Fixed | Same function name bug |
| `fetch-skill.sh` | ✅ Works | Branch fallback, size validation, metadata all work |
| `scan-skill.py` | ✅ Works | All 9 rule categories function correctly |
| `scan-skill.py` (frontmatter) | ✅ Fixed | Added `metadata` to allowed keys |
| Test suite (34 tests) | ✅ Fixed | Fixed function name references, all pass |
| SKILL.md (pre-flight checklist) | ✅ Works | Clear, actionable, well-structured |
| Command definitions | ✅ Works | seek.md, browse.md, install.md, unload.md are clear |

### Skills Discovered During Test

| Repository | Stars | Trust | Relevance |
|-----------|-------|-------|-----------|
| K-Dense-AI/claude-scientific-skills | 14,168 | HIGH | Low (scientific focus, not skill-writing) |
| aaron-he-zhu/seo-geo-claude-skills | 345 | HIGH | Low (SEO-specific) |
| John-Dekka/advanced-skill-builder | 1 | LOW | **High** (exactly what we searched for) |
| hanlulong/econ-writing-skill | 25 | MEDIUM | Low (economics writing, not skill-writing) |

**Key observation**: The most relevant result (`advanced-skill-builder`) had the lowest trust score (1 star). This highlights the tension between **trust** and **relevance** — the current minimum star threshold of 10 would have filtered out the most relevant result entirely.

---

## Recommendations Priority

| Priority | Recommendation | Effort |
|----------|---------------|--------|
| 🔴 Done | Fix `call_github_api` → `gh_api` | Trivial |
| 🔴 Done | Fix test function name mismatches | Trivial |
| 🔴 Done | Add `metadata` to allowed frontmatter keys | Trivial |
| 🟡 High | Add error handling to `gh_api()` for rate limits | Small |
| 🟡 High | Validate API responses before `jq` parsing | Small |
| 🟢 Medium | Add curated fallback index for offline/rate-limited use | Medium |
| 🟢 Medium | Add quick-peek descriptions in browse results | Medium |
| 🔵 Low | Consider denylist approach for frontmatter validation | Small |
| 🔵 Low | Add `--dry-run` flag for search | Small |
