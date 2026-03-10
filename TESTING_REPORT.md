# Skill-Seeker: Flow Definition, Live Walkthrough & Hermeneutic Analysis (v2)

A comprehensive report from testing the skill-seeker after implementing fixes for issues identified in v1.

**Test date:** 2026-03-10
**Environment:** GitHub Copilot coding agent sandbox, firewall disabled
**Fixes applied:** `gh_api()` validation, `--check` diagnostic, curated registry with real skills, min-stars 10→3, browse error handling

---

## Part 1: The Intended Flow — Canonical Step Order

The skill-seeker defines its flow across three source-of-truth documents. Here is the canonical order, synthesized from `SKILL.md`, the command definitions, and `ARCHITECTURE.md`:

### Phase 0: Pre-flight (Implicit)
The `seeking-skills/SKILL.md` pre-flight skill triggers automatically when Claude recognizes a domain-specific task. It evaluates whether to suggest searching for community skills.

**Decision criteria:**
- Is this a complex or specialized domain?
- Does the user already have a loaded skill that covers it?
- Has the user explicitly said not to search?

### Phase 1: Discovery (`/skill-seeker:seek <query>`)
1. **Strategy 0:** Search curated registry (`search-registry.sh`) — instant, offline, synonym-expanded
2. **Strategy 1-3:** Search GitHub API (`search-github.sh`) — live, multi-strategy, trust-scored
3. Merge, deduplicate, and present combined results
4. **MANDATORY STOP**: Present results table to user
5. **MANDATORY WAIT**: User picks a repo (or refines search)

### Phase 2: Investigation (`/skill-seeker:browse <owner/repo>`)
1. Run `search-github.sh --browse <repo>` — fetch repo file tree via GitHub API
2. Identify skill files (`.claude/skills/*/SKILL.md` + general `.md` heuristics)
3. Present skills table with names, descriptions, token counts, paths
4. User picks specific skill(s) to install

### Phase 3: Commitment (`/skill-seeker:install <owner/repo/path>`)
1. Parse target into owner/repo/path
2. Run `fetch-skill.sh` — download via `raw.githubusercontent.com`, cache locally
3. Run `scan-skill.py` — 9-category security scan
4. **If HIGH/CRITICAL**: Block + show findings, require explicit acknowledgment
5. **If CLEAN/LOW**: Show 30-line preview + scan results
6. **MANDATORY STOP**: Ask user to confirm installation
7. Copy to `~/.claude/skills-cache/` on confirmation
8. Read skill into current context
9. Report success + summarize what the skill provides

### Phase 4: Application (Implicit)
Claude applies the loaded skill's behavioral framework to the user's task.

### Phase 5: Closure (`/skill-seeker:unload`)
1. List skills in `.claude-skills-temp/` and `/tmp/skill-seeker-cache/`
2. Present cleanup options to user
3. Clean selected directories on confirmation
4. Remind user that context-loaded skills persist until session ends

```
Phase 0        Phase 1          Phase 2       Phase 3          Phase 4      Phase 5
Pre-flight ──→ Seek ──────────→ Browse ─────→ Install ───────→ Apply ─────→ Unload
(auto)         (registry+API)   (tree API)    (fetch+scan+     (use skill)  (cleanup)
               ⬇ STOP                        confirm)
               ⬇ user picks    ⬇ user        ⬇ STOP
               ⬇ repo          ⬇ picks       ⬇ user confirms
                                ⬇ skill
```

---

## Part 2: Live Walkthrough — Fetching a Skill-Writing Skill

### Step 1: Registry Search (Phase 1, Strategy 0)

**Command:**
```bash
bash scripts/search-registry.sh "skill writing"
```

**Result: ✅ SUCCESS — 11 results found instantly (no API calls)**

| # | Repository | Trust | Source |
|---|-----------|-------|--------|
| 1 | haowjy/creative-writing-skills | MEDIUM | registry |
| 2 | metaskills/skill-builder | MEDIUM | registry |
| 3 | blader/humanizer | HIGH | registry |
| 4 | lishix520/academic-paper-skills | HIGH | registry |
| 5 | zebbern/agent-skills-authoring | MEDIUM | registry |

**Synonym expansion applied:** "skill writing" expanded to `["content-creation", "creative-writing", "skill", "writing"]`

**Key improvement over v1:** In v1 testing, search returned 0 results because `api.github.com` was blocked by a MITM proxy. The registry provides guaranteed fallback results with zero network dependency.

### Step 2: GitHub API Search (Phase 1, Strategies 1-3)

**Command:**
```bash
bash scripts/search-github.sh "skill writing"
```

**Result: ✅ SUCCESS — 14 results with `api_status: "ok"`**

| # | Repository | Stars | Trust |
|---|-----------|-------|-------|
| 1 | K-Dense-AI/claude-scientific-skills | 14,172 | HIGH |
| 2 | blader/humanizer | 8,184 | HIGH |
| 3 | aaron-he-zhu/seo-geo-claude-skills | 347 | HIGH |
| 4 | dongbeixiaohuo/writing-agent | 101 | HIGH |
| 5 | metaskills/skill-builder | 88 | MEDIUM |

**Key improvement over v1:** Now returns 14 results vs 11 previously because min-stars was lowered from 10 to 3. The `api_status` field in the JSON output explicitly confirms the API is working.

### Step 3: Connectivity Check (New)

**Command:**
```bash
bash scripts/search-github.sh --check
```

**Result:**
```
✅ api.github.com — reachable (HTTP 200)
✅ raw.githubusercontent.com — reachable (HTTP 200)
🔑 GITHUB_TOKEN is set
   Search rate limit: unknown/unknown remaining
```

**Key improvement over v1:** This command didn't exist. Users now have a self-service diagnostic for connectivity issues.

### Step 4: Browse (Phase 2)

**Command:**
```bash
bash scripts/search-github.sh --browse "metaskills/skill-builder"
```

**Result: ✅ SUCCESS — 7 skills found**

| # | Skill | Tokens | Format |
|---|-------|--------|--------|
| 1 | converting-sub-agents-to-skills | 4,682 | markdown |
| 2 | editing-skills-guide | 3,196 | markdown |
| 3 | metadata-requirements | 2,313 | markdown |
| 4 | nodejs-and-cli-patterns | 3,396 | markdown |
| 5 | skill-best-practices | 3,423 | markdown |
| 6 | skill-structure-and-format | 1,204 | markdown |
| 7 | skill-template | 1,073 | markdown |

**Key improvement over v1:** In v1, browse crashed with `jq: parse error` when the API was blocked. Now it validates the response and returns a descriptive error with an empty skills array if the API is unreachable.

### Step 5: Fetch (Phase 3a)

**Command:**
```bash
bash scripts/fetch-skill.sh "metaskills" "skill-builder" "reference/skill-best-practices.md"
```

**Result: ✅ SUCCESS**
```
/tmp/skill-seeker-cache/metaskills/skill-builder/reference/skill-best-practices.md
```

Metadata generated:
```json
{
  "owner": "metaskills",
  "repo": "skill-builder",
  "path": "reference/skill-best-practices.md",
  "branch": "main",
  "fetched_at": "2026-03-10T08:29:30Z",
  "size_bytes": 13692,
  "estimated_tokens": 3423,
  "sha256": "..."
}
```

### Step 6: Security Scan (Phase 3b)

**Command:**
```bash
python3 scripts/scan-skill.py "/tmp/skill-seeker-cache/metaskills/skill-builder/reference/skill-best-practices.md"
```

**Result: ✅ CLEAN** (risk score 0, 0 findings)

### Step 7: Preview (Phase 3c)

**First 30 lines:**
```markdown
# Skill Best Practices Reference

## Core Philosophy

**Create skills that provide just enough guidance for Claude to perform tasks effectively.**

Key principles:
1. Challenge every piece of information: "Does Claude really need this?"
2. Use progressive disclosure (fat reference files, skinny SKILL.md)
3. Be concise and actionable
4. Provide specific, complete examples
5. Leverage CLI tools and Node.js
...
```

**Assessment:** A high-quality reference guide for skill authoring. At 3,423 tokens it fits within the "Reference guide < 3,500 tokens" budget. Covers structural best practices, progressive disclosure patterns, and concrete examples.

### Step 8: Install (Phase 3d)

**Commands:**
```bash
mkdir -p ~/.claude/skills-cache/metaskills/skill-builder/skill-best-practices/
cp /tmp/skill-seeker-cache/.../skill-best-practices.md ~/.claude/skills-cache/.../SKILL.md
```

**Result: ✅ SUCCESS** — Skill installed to persistent cache.

### Test Suite

All 34 tests pass:
```
..................................
Ran 34 tests in 0.013s — OK
```

---

## Part 3: What Went Well ✅

### 1. The Full Flow Works End-to-End
With the firewall disabled and fixes applied, every phase of the canonical flow completed successfully: registry search → GitHub search → browse → fetch → scan → preview → install. No manual workarounds were needed.

### 2. Two-Layer Search Provides Resilience
The registry search returned 11 relevant results for "skill writing" instantly. Even if the GitHub API had been blocked (as in v1 testing), users would have had meaningful results to work with. This is the critical improvement — **discovery no longer has a single point of failure**.

### 3. Error Handling is Now Honest
The `gh_api()` function now validates HTTP status codes, checks for JSON validity, and emits descriptive error messages. Search mode includes `api_status` in the JSON output ("ok", "partial", "error"). Browse mode returns valid JSON with an error field instead of crashing with `jq: parse error`.

### 4. Lowered Threshold Surfaces Niche Skills
With min-stars lowered from 10 to 3, the search returned 14 results for "skill writing" (vs 11 at min-stars=10). More importantly, repos like `metaskills/skill-builder` (88 stars, MEDIUM trust) now surface alongside the mega-repos.

### 5. The `--check` Command Enables Self-Service Debugging
Users can now run `search-github.sh --check` to test connectivity to both GitHub domains, verify auth status, and check rate limits. This would have immediately diagnosed the MITM proxy issue from v1 testing.

### 6. Security Scanner Remains Rock-Solid
The fetched skill scanned CLEAN with zero findings. The scanner correctly handled a 13,692-byte file with code blocks, markdown formatting, and technical content. All 34 tests pass without modification.

### 7. Registry Uses Real, Verified Skills
All 13 registry entries are real GitHub repositories that have been:
- Confirmed to exist via live API queries
- Browsed to verify skill file locations
- Tested with `fetch-skill.sh` to confirm downloadability
- Scanned with `scan-skill.py` for security

---

## Part 4: What Could Be Even Better If 🔧

### Medium: Registry-GitHub Result Merging is Manual
The `seek.md` command instructs Claude to run both registry and GitHub search and merge results. But this merging happens in the LLM's reasoning, not in code. A combined search script that runs both and deduplicates programmatically would be more reliable.

**Recommendation:** Create a `search-combined.sh` script that runs both searches, merges by repo name, and outputs a unified result set.

### Medium: Browse Still Requires API Access
While discovery now has an offline fallback (registry), browsing a repo's skills still requires the GitHub API. If the API is blocked, users can't browse even repos from the registry.

**Recommendation:** Store skill file paths in the registry so users can skip browse and go directly to install for registry skills.

### Low: Synonym Expansion Could Be Richer
The registry's synonym mapping is useful but manually maintained. "Skill writing" didn't directly expand to include "skill-building" because "skill" and "writing" are separate tokens that each get their own expansions.

**Recommendation:** Add multi-word synonym entries (e.g., "skill writing" → ["skill-building", "skill-authoring"]) and handle compound query matching.

### Low: Token Budget Not Enforced in Install Flow
The SKILL.md documents token budgets (2k focused, 3.5k reference, 8k meta) but `install.md` never checks them. The fetched skill at 3,423 tokens happened to fit within guidelines, but a larger skill would install without warning.

**Recommendation:** Add a token budget check to the install flow that warns (but doesn't block) when a skill exceeds category-appropriate thresholds.

---

## Part 5: Hermeneutic Reflection

### The Hermeneutic Circle — Completed

Gadamer's hermeneutic circle describes how understanding a whole requires understanding its parts, and understanding parts requires understanding the whole. In v1 testing, the circle was broken — the search phase returned silence, and the user couldn't progress. The entire interpretive process stalled at its first step.

In v2, the circle completes:

```
Pre-understanding ("I need a skill for writing skills")
  → Registry search (instant: 11 results, synonym-expanded)
  → GitHub search (live: 14 results, trust-scored)
  → Horizon revision ("there are multiple approaches to skill-building")
  → Browse (7 files in metaskills/skill-builder)
  → Deeper understanding ("skills have structure, best practices, templates")
  → Fetch + scan + preview (actual content)
  → Application (loaded into context)
  → New pre-understanding (can now write skills)
```

Each phase genuinely revises the user's horizon. The progression from "I need a skill-writing skill" to "there are 7 reference guides covering structure, editing, templates, CLI patterns, and best practices" represents real hermeneutic movement.

### Fusion of Horizons — Three Layers Now

The trust scoring system creates a **fusion of horizons** between three perspectives:
- **The community** (stars, forks) — collective judgment of value
- **The author** (topics, license, description) — declared intent and openness
- **The user** (confirmation checkpoints) — situated judgment of relevance

The registry adds a fourth perspective: **the curator** (verified status, hand-selected entries, synonym mappings). This is valuable because the curator has done interpretive work that neither the community nor the API can — they've evaluated whether a skill actually matches the search domain, not just whether its metadata contains the right keywords.

### What the Silence Revealed — And How We Fixed It

The deepest hermeneutic insight from v1 was about the silence of the system on failure. When search returned 0 results with exit code 0, it spoke a falsehood — "I succeeded; there really are zero results." This was hermeneutically destructive because it built the user's understanding on a false foundation.

The fix addresses this at multiple levels:
1. **`gh_api()` now speaks on failure** — stderr messages explain what went wrong
2. **`api_status` field tells the truth** — "ok", "partial", or "error"
3. **Non-zero exit code signals failure honestly** — exit 1 when all searches fail
4. **`--check` provides transparency** — users can see the system's own understanding of its connectivity
5. **The registry ensures the system always has something to say** — even when the API is silent, curated results provide meaningful response

In hermeneutic terms: the system has moved from **concealing its own failure** to **disclosing its situation**. This is the difference between a tool that misleads and a tool that enables understanding.

### The Prejudice of Popularity — Partially Addressed

V1 identified the 10-star minimum as an "unexamined prejudice" (in Gadamer's sense). The threshold has been lowered to 3, which helps — but the deeper tension between trust and relevance remains.

The registry partially solves this by hand-curating niche skills that wouldn't surface through popularity-based filtering. `zebbern/agent-skills-authoring` (17 stars) and `metaskills/skill-builder` (88 stars) are in the registry because a curator judged them relevant to skill-writing, regardless of star count. This is appropriate: some prejudices (spam filtering) should remain, while others (equating popularity with relevance) should be examined and corrected.

### Temporal Horizons — Unchanged and Correct

The three-tier caching design remains philosophically elegant:
1. **Ephemeral** (`/tmp/skill-seeker-cache/`) — the moment of evaluation
2. **Persistent but dormant** (`~/.claude/skills-cache/`) — available but inactive
3. **Active but bounded** (context window) — shaping behavior now, forgotten tomorrow

The decision to not auto-load cached skills prevents hermeneutic "sedimentation" — accumulated patterns becoming invisible assumptions. Each session starts clean.

---

## Part 6: Architectural Assessment — Solid Baseline to Build On

### Verdict: Solid Baseline — Iterate, Don't Rethink (Confirmed)

V1 concluded this was a solid baseline. V2 confirms it — the architecture absorbed the fixes without structural changes. Error handling was added to `gh_api()`, a new search strategy was layered in, and the flow improved. Nothing was rearchitected.

#### What's Right at the Foundation Level

1. **The plugin model works.** Commands as Markdown instruction files + shell/Python scripts is the right level of abstraction.
2. **The security model is correctly positioned.** Defense-in-depth (scanner + human approval + session isolation) handles the threat surface well.
3. **The separation of concerns is clean.** Each script does one thing. New capabilities (registry search) add as new scripts, not modifications to existing ones.
4. **The trust scoring is genuine innovation.** Composite scoring with logarithmic star scaling is well-reasoned.
5. **The lifecycle design prevents context pollution.** Three-tier caching is the right model.
6. **The two-layer search provides resilience.** Registry (offline) + GitHub API (live) means discovery works even when the network doesn't.

#### What Improved

| Issue from v1 | Status | Impact |
|--------------|--------|--------|
| Silent API failure | **Fixed** | `gh_api()` now validates responses, emits errors, sets non-zero exit codes |
| 10-star filter vs niche content | **Improved** | Lowered to 3; registry curates niche skills regardless of stars |
| No offline fallback | **Fixed** | Registry provides instant, offline results with synonym expansion |
| Browse crashes on API error | **Fixed** | Validates response before `jq`, returns descriptive error JSON |
| No connectivity diagnostic | **Fixed** | `--check` command tests both domains and reports status |

#### What Still Needs Iteration

| Issue | Category | Effort |
|-------|----------|--------|
| No combined search script | UX polish | Small — merge registry+GitHub in one script |
| Browse requires API | Resilience gap | Medium — store paths in registry for direct install |
| Synonym expansion is manual | Maintenance | Medium — consider domain/tag inheritance from registry |
| Token budget not enforced | Completeness | Small — add warning to install flow |

### Summary: Build Confidence Score (v2)

| Dimension | v1 | v2 | Notes |
|-----------|----|----|-------|
| Conceptual model | 9/10 | 9/10 | Seek→Browse→Install→Unload remains intuitive and correct |
| Security posture | 9/10 | 9/10 | Scanner + human-in-the-loop + session isolation unchanged |
| Code quality | 7/10 | 8/10 | Error handling now present; response validation in place |
| UX coherence | 5/10 | 7/10 | Honest error reporting; `--check` diagnostic; API status field |
| Resilience | 3/10 | 7/10 | Registry fallback; graceful degradation; two-domain awareness |
| Ecosystem readiness | 5/10 | 7/10 | 13 real verified skills; synonym expansion; lower threshold |

**Overall: 7.8/10 (up from 6.3/10) — Solid foundation with meaningful resilience. Ready for incremental iteration.**

The architecture correctly identifies the problem space, makes good structural decisions, and now handles failure modes honestly. The two-layer search (registry + API) ensures discovery works even in constrained environments. The remaining gaps (combined search script, registry-based browse bypass, token budget enforcement) are clearly defined and require only additive changes.

---

## Part 7: Previously Fixed Bugs (from v1)

| Bug | Severity | Fix Applied |
|-----|----------|-------------|
| `search-github.sh` called undefined `call_github_api()` instead of `gh_api()` | Blocker | Renamed all calls to `gh_api()` |
| Tests referenced `scan_skill.scan()` instead of `scan_skill.scan_skill_file()` | Blocker | Updated function references |
| Tests referenced `scan_skill.identify_codeblocks()` instead of `scan_skill.find_code_block_lines()` | Blocker | Updated function references |
| `metadata` missing from `ALLOWED_FRONTMATTER_KEYS` | Moderate | Added to allowlist |

## Part 8: Fixes Applied in This Session (v2)

| Fix | Issue | Before | After |
|-----|-------|--------|-------|
| `gh_api()` response validation | Silent failure on API errors | Exit 0, empty stderr, `{"total_found": 0}` | Exit 1, descriptive stderr, `api_status: "error"` |
| `--check` diagnostic command | No way to diagnose connectivity | (didn't exist) | Tests both GitHub domains, reports auth/rate-limit |
| Browse error handling | `jq: parse error` crash on API block | Exit 5, cryptic error | Exit 1, descriptive error JSON with empty skills |
| Min-stars 10→3 | Niche skills filtered out | "skill writing" → 11 results | "skill writing" → 14 results |
| Registry with real skills | Placeholder entries in registry | 10 example entries (repos don't exist) | 13 verified entries (all real repos) |
| Two-layer seek command | Single-source dependency | seek.md only called GitHub search | seek.md calls registry + GitHub, merges results |
