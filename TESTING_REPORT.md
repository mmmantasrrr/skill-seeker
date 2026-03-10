# Skill-Seeker: Flow Definition, Live Walkthrough & Hermeneutic Analysis

A comprehensive report from testing the skill-seeker by walking through its intended flow to discover and load a **skill-writing skill** (a meta-skill for authoring Claude Code skills).

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
1. Run `search-github.sh <query>` — fires 3 search strategies against GitHub API
2. Merge, deduplicate, and trust-score all results
3. **MANDATORY STOP**: Present results table to user
4. **MANDATORY WAIT**: User picks a repo (or refines search)

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
Phase 0        Phase 1       Phase 2       Phase 3          Phase 4      Phase 5
Pre-flight ──→ Seek ───────→ Browse ─────→ Install ───────→ Apply ─────→ Unload
(auto)         (search API)  (tree API)    (fetch+scan+     (use skill)  (cleanup)
               ⬇ STOP        ⬇ user       confirm)
               ⬇ user picks  ⬇ picks      ⬇ STOP
               ⬇ repo        ⬇ skill      ⬇ user confirms
```

---

## Part 2: Live Walkthrough — Fetching a Skill-Writing Skill

### Step 1: Search (Phase 1)

**Queries tried (Run 1 — with firewall enabled):**
```bash
bash scripts/search-github.sh "skill writing"
bash scripts/search-github.sh "claude skill authoring"
bash scripts/search-github.sh "skill builder framework"
bash scripts/search-github.sh "claude code skills"
```

**Result: All returned `{"total_found": 0, "results": []}` with exit code 0 and empty stderr.**

**Queries tried (Run 2 — firewall explicitly disabled by user):**
```bash
bash scripts/search-github.sh "skill writing"    # → same: 0 results, exit 0, no stderr
```

The firewall toggle had no effect on `api.github.com` accessibility. The blocking is implemented at a deeper infrastructure level via a GoProxy MITM proxy (`curl -v` reveals `subject: O=GoProxy untrusted MITM proxy Inc; CN=api.github.com`). DNS resolves correctly to `140.82.113.5` but the connection is intercepted at `127.0.0.1`.

**Root cause:** The `gh_api()` function in `search-github.sh` uses `curl` to reach `api.github.com`, which returns the non-JSON string `"Blocked by DNS monitoring proxy"`. The Python scoring script silently treats this as an empty result set via its `try/except (json.JSONDecodeError, KeyError): pass` block.

**Critical observation — the silent failure:** The script gives **zero feedback** that something went wrong:
- Exit code: **0** (success) — not 1 or any error code
- stderr: **empty** — no warning, no diagnostic
- stdout: valid JSON with `"total_found": 0` — indistinguishable from "no matching repos exist on GitHub"

The user has no way to know whether:
- No matching skills exist on GitHub (false — 12+ results exist)
- The API was blocked/unreachable (the actual problem)
- They've been rate-limited
- Their token is invalid

**Workaround used:** Verified via GitHub MCP tools that relevant skills do exist. Search for `topic:claude-skills skill writing` returned 12 results including:

| Repository | Stars | Description |
|-----------|-------|-------------|
| K-Dense-AI/claude-scientific-skills | 14,168 | Scientific research skills (writing-adjacent) |
| aaron-he-zhu/seo-geo-claude-skills | 345 | SEO content writing skills |
| ThamJiaHe/claude-prompt-engineering-guide | 61 | Claude prompt engineering guide |
| **John-Dekka/advanced-skill-builder** | **1** | **Interactive guide for creating Claude skills** |

**Scoring simulation:** Using the real MCP data piped through the scoring Python script with `min_stars=0`:

| Repository | Trust Score | Trust Level |
|-----------|------------|-------------|
| K-Dense-AI/claude-scientific-skills | 95 | HIGH |
| aaron-he-zhu/seo-geo-claude-skills | 83 | HIGH |
| ThamJiaHe/claude-prompt-engineering-guide | 64 | HIGH |
| John-Dekka/advanced-skill-builder | 39 | LOW |

**Key finding:** The most relevant result for "skill writing" (`advanced-skill-builder`, trust score 39/LOW) would be filtered out by the default `min_stars=10`. Its trust score of 39 is accurate — it's a new repo with 1 star — but it's the **only** result that actually teaches skill writing. The trust/relevance gap remains the deepest UX problem in the scoring system.

### Step 2: Browse (Phase 2)

**Command tried (Run 1 — firewall enabled):**
```bash
bash scripts/search-github.sh --browse "John-Dekka/advanced-skill-builder"
```

**Result: `jq: parse error: Invalid numeric literal at line 1, column 8` (exit code 5)**

**Command tried (Run 2 — firewall disabled by user):**
Same command, same result. The MITM proxy persists.

**Root cause:** `gh_api()` returns the non-JSON string `"Blocked by DNS monitoring proxy"` which is piped directly into `jq` with no validation. Unlike search mode's silent failure, browse mode crashes visibly — but the error message (`jq: parse error`) gives no diagnostic information about the actual cause (blocked API).

**Failure mode comparison:**

| Mode | Exit code | Stderr | User experience |
|------|-----------|--------|-----------------|
| Search | 0 (success!) | empty | Silently returns fake "0 results" — **misleading** |
| Browse | 5 (jq error) | `jq: parse error` | Crashes with cryptic error — **confusing** |

Both are bad, but search mode is worse: it actively misleads the user by returning valid-looking JSON with zero results when the real problem is infrastructure failure.

**Workaround used:** Used GitHub MCP tools to browse the repository structure. Found:
- `advanced-skill-builder/SKILL.md` — the actual skill file (15,620 bytes, ~3,905 tokens)

### Step 3: Fetch (Phase 3a)

**Command:**
```bash
bash scripts/fetch-skill.sh "John-Dekka" "advanced-skill-builder" "advanced-skill-builder/SKILL.md"
```

**Result: ✅ SUCCESS** → `/tmp/skill-seeker-cache/John-Dekka/advanced-skill-builder/advanced-skill-builder/SKILL.md`

**Why this worked when search/browse failed:** `fetch-skill.sh` uses `raw.githubusercontent.com` (not `api.github.com`) to download files. This domain is NOT blocked by the MITM proxy, even when `api.github.com` is.

**Infrastructure finding:** The two GitHub domains have different accessibility profiles:

| Domain | Purpose | Blocked by proxy? | Used by |
|--------|---------|-------------------|---------|
| `api.github.com` | Search, browse (REST API) | ✅ Blocked | `search-github.sh` (search + browse) |
| `raw.githubusercontent.com` | File download | ❌ Accessible | `fetch-skill.sh` |

This means **discovery is broken but delivery works**. A user who already knows the `owner/repo/path` can fetch and install skills. But the entire discovery flow (which is the core value proposition of skill-seeker) is non-functional when the API domain is blocked.

**Metadata generated:**
```json
{
  "owner": "John-Dekka",
  "repo": "advanced-skill-builder",
  "path": "advanced-skill-builder/SKILL.md",
  "branch": "main",
  "fetched_at": "2026-03-10T08:03:33Z",
  "size_bytes": 15620,
  "estimated_tokens": 3905,
  "sha256": "61b951fb6bfa829bcbd9b0f1af9571c8b528265c5fd8f1aba2c1061c325b3fea"
}
```

### Step 4: Security Scan (Phase 3b)

**Command:**
```bash
python3 scripts/scan-skill.py "/tmp/skill-seeker-cache/John-Dekka/advanced-skill-builder/advanced-skill-builder/SKILL.md"
```

**Result: ✅ CLEAN** (risk score 0, 0 findings)

```json
{
  "file": "/tmp/skill-seeker-cache/.../SKILL.md",
  "size_bytes": 15620,
  "estimated_tokens": 3905,
  "risk_level": "CLEAN",
  "risk_score": 0,
  "findings_count": 0,
  "findings": []
}
```

The skill is a well-structured guide for creating Claude skills via interactive dialogue. No prompt injection, tool abuse, hidden content, or other suspicious patterns detected.

### Step 5: Preview (Phase 3c)

**First 30 lines of the skill:**
```markdown
---
name: advanced-skill-builder
description: Guides users through creating production-ready Claude skills
  via interactive dialogue...
license: MIT
metadata:
  author: John-Dekka
  version: 1.0.0
  category: productivity
  tags: [skill-development, automation, workflow, template]
---

# Advanced Skill Builder

An interactive guide for creating production-ready Claude skills
through collaborative dialogue.

## When to Use This Skill

Activate this skill when:
- User says: "Help me build a skill", "Create a new skill"...
- User describes a workflow they want to automate
- User wants to teach Claude a specific process
- User asks: "How do I create a skill?"
- User has an MCP server and wants to add workflow guidance
```

**Assessment:** This skill is exactly what was sought — a meta-skill for writing other skills. At 3,905 tokens it falls within the "Meta/comprehensive skill < 8,000 tokens" budget guideline from SKILL.md. It covers 5 phases: Discovery → Planning → Structure → Generation → Validation.

### Step 6: Install & Load (Phase 3d)

This step would be:
```bash
mkdir -p ~/.claude/skills-cache/John-Dekka/advanced-skill-builder/advanced-skill-builder/
cp /tmp/skill-seeker-cache/.../SKILL.md ~/.claude/skills-cache/.../SKILL.md
```
Then read the file into context. In this test, the fetch + scan + preview were verified successfully.

### Step 7: Compare with Repo's Own Skill (Baseline)

For comparison, scanning the repo's own `seeking-skills/SKILL.md`:
```json
{
  "size_bytes": 3845,
  "estimated_tokens": 961,
  "risk_level": "CLEAN",
  "risk_score": 0
}
```

The repo's own skill is well within budget at 961 tokens — a focused, efficient pre-flight checklist.

### Test Suite Verification

All 34 existing tests pass:
```
..................................
----------------------------------------------------------------------
Ran 34 tests in 0.015s
OK
```

---

## Part 3: What Went Well ✅

### 1. The Conceptual Architecture is Sound
The four-phase flow (Seek → Browse → Install → Unload) maps naturally to how people discover and adopt new knowledge. The command naming is intuitive and the progression is logical. The separation of concerns (search script, fetch script, scan script) keeps each component focused and testable.

### 2. Security Scanner is Thorough and Battle-Tested
The 9-category scanner with 34 passing tests provides genuine protection against prompt injection. The code-block-awareness feature (skipping patterns inside fenced blocks) shows sophisticated understanding of the false-positive problem. The weighted scoring system produces meaningful risk assessments.

### 3. Fetch Script is the Most Robust Component
`fetch-skill.sh` handles real-world edge cases well:
- Branch fallback (`main` → `master`)
- Empty file detection
- Large file warnings (>50KB)
- SHA256 hashing for change detection
- Structured metadata generation
- Uses `raw.githubusercontent.com` which is more reliably accessible than `api.github.com`

### 4. Human-in-the-Loop is Non-Negotiable
The three mandatory checkpoints (present search results, show preview, confirm install) are correctly positioned. The SKILL.md even bolds "Steps 3-4 are mandatory checkpoints" and explicitly warns against skipping them. This is the right security posture for injecting community content into an AI's context.

### 5. Trust Scoring is Nuanced
The composite scoring (log-scale stars, recency, forks, topics, license, archive status) prevents single-signal gaming. The three trust tiers (LOW/MEDIUM/HIGH) give users meaningful differentiation.

### 6. The Pre-flight Skill is Well-Scoped
At 961 tokens, the `seeking-skills/SKILL.md` is appropriately lean. It includes "When NOT to Use" criteria and common mistakes — markers of a mature skill that has been thought through.

---

## Part 4: What Could Be Even Better If 🔧

### Critical: Silent Failure on API Errors

**The single biggest issue — confirmed across two separate test runs.** When `api.github.com` is unreachable (DNS block, MITM proxy, rate limit, network error), the two modes fail differently but both badly:

- **Search mode**: Returns `{"total_found": 0, "results": []}` with **exit code 0 and empty stderr** — completely indistinguishable from "no matching repos exist." This is the worse failure mode because it actively misleads the user.
- **Browse mode**: Crashes with `jq: parse error` (exit code 5) — visible but cryptic, with no mention of the actual cause (API unreachable).

In testing, the firewall was explicitly disabled mid-session but `api.github.com` remained blocked via a GoProxy MITM proxy at the infrastructure level. This demonstrates that **API reachability cannot be assumed** even in environments that appear to have internet access.

The root cause is that `gh_api()` performs no response validation. Non-JSON responses (like `"Blocked by DNS monitoring proxy"`) flow through unchecked.

**Recommendation — add a connectivity check and response validation:**
```bash
gh_api() {
    local url="$1"
    local tmpfile
    tmpfile=$(mktemp)
    local http_code

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        http_code=$(curl -s -w "%{http_code}" -o "$tmpfile" \
             -H "Authorization: token $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3+json" \
             "$url")
    else
        http_code=$(curl -s -w "%{http_code}" -o "$tmpfile" \
             -H "Accept: application/vnd.github.v3+json" \
             "$url")
    fi

    # Validate response
    if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
        echo "ERROR: GitHub API returned HTTP $http_code" >&2
        if [[ "$http_code" == "403" ]]; then
            echo "HINT: You may be rate-limited. Set GITHUB_TOKEN for 5000 req/hr." >&2
        fi
        rm -f "$tmpfile"
        echo '{"items":[]}'
        return 1
    fi

    # Validate JSON
    if ! jq empty "$tmpfile" 2>/dev/null; then
        echo "ERROR: GitHub API returned non-JSON response (network proxy or block?)" >&2
        rm -f "$tmpfile"
        echo '{"items":[]}'
        return 1
    fi

    cat "$tmpfile"
    rm -f "$tmpfile"
}
```

### High: Trust vs Relevance Tension

The default 10-star minimum filters out the most relevant result for niche queries. In our test, the only genuine "skill writing" skill (`John-Dekka/advanced-skill-builder`, 1 star) would never appear.

This is not just a threshold problem — it's a **fundamental tension** in the scoring system. Trust scoring measures **repo credibility** but not **content relevance**. A 14,000-star scientific skills repo gets HIGH trust for "skill writing" despite having zero relevance to the query.

**Recommendation:** Consider two-axis scoring:
1. **Trust axis** (current): stars, forks, recency, tagging, license
2. **Relevance axis** (new): how well does the repo description/topics match the query?

### High: The Browse-to-Understanding Gap

The current flow requires three steps before a user can understand what a skill actually does:
1. **Seek** shows: repo name + description (surface level)
2. **Browse** shows: skill names + token counts (structural, not semantic)
3. **Install** shows: first 30 lines (finally, actual content)

A user must commit to browsing and then begin installing before they can form an opinion about whether a skill is useful. This creates unnecessary friction for the common case of "let me quickly see what this does."

**Recommendation:** Enhance browse to fetch and display each skill's YAML frontmatter description inline. This is a single `raw.githubusercontent.com` call per skill and would dramatically reduce the interpretive burden.

### Medium: No Graceful Degradation (and Two-Domain Fragility)

When the GitHub API is unreachable, the entire discovery flow stops. Testing revealed a critical infrastructure insight: `api.github.com` and `raw.githubusercontent.com` have **different accessibility profiles**. In the test environment:

- `api.github.com` → **Blocked** (MITM proxy intercept, even with firewall disabled)
- `raw.githubusercontent.com` → **Accessible** (fetching files works fine)

This means the discovery mechanism (search + browse) can fail while the delivery mechanism (fetch) remains functional. There's no:
- Cached index of previously-seen repos
- Curated list of well-known skill repositories
- Fallback to `raw.githubusercontent.com` for browsing (which might still be accessible)
- Diagnostic telling the user which GitHub domains are accessible

**Recommendation:** Include a curated `known-skills.json` index that can be browsed offline. Also add a `--check` diagnostic command that tests connectivity to both domains and reports status.

### Medium: Token Budget Not Enforced in Install Flow

The SKILL.md documents token budgets (2k focused, 3.5k reference, 8k meta) but `install.md` never checks them. A user could load a 15,000-token skill without any warning about context window impact.

**Recommendation:** Add a token budget check to the install flow that warns (but doesn't block) when a skill exceeds category-appropriate thresholds.

### Low: Frontmatter Allowlist is Brittle

The scanner uses an allowlist for frontmatter keys. Every legitimate new field (like `metadata`, which was added in a previous fix) requires a scanner update. Real-world skill authors may use custom fields for their own tooling.

**Recommendation:** Switch to a denylist approach: flag known-dangerous keys (`system_prompt`, `override`, `inject`) rather than requiring all keys to be pre-approved.

---

## Part 5: Hermeneutic Reflection

### The Hermeneutic Circle

Gadamer's hermeneutic circle describes how understanding a whole requires understanding its parts, and understanding parts requires understanding the whole. The skill-seeker embodies this circle across two dimensions:

**Dimension 1 — The User's Understanding Cycle:**
```
Pre-understanding ──→ Query formulation ──→ Results interpretation ──→
  Skill selection ──→ Content preview ──→ Revised understanding ──→
    Application ──→ New pre-understanding (for next task)
```

Each phase revises the user's horizon. Searching for "skill writing" reveals that the ecosystem mostly contains domain-specific skills (SEO, science, economics), which reshapes the user's understanding of what "skill" means in this context. The preview of `advanced-skill-builder` then reveals that skill authoring is itself a structured practice with phases, templates, and validation — expanding the user's horizon again.

**Dimension 2 — The System's Self-Reference:**

Skill-Seeker is a *meta-skill*: a skill about finding skills. When you use it to find a *skill-writing skill*, you've entered a triple recursion: using a skill-seeking skill to find a skill-building skill to build more skills. This is genuinely hermeneutic — the tool reshapes its own conditions of possibility. Each skill loaded into context changes what Claude can do next, including how effectively it can seek and evaluate future skills.

### Fusion of Horizons

The trust scoring system creates a **fusion of horizons** between three perspectives:
- **The community** (stars, forks) — collective judgment of value
- **The author** (topics, license, description) — declared intent and openness
- **The user** (confirmation checkpoints) — situated judgment of relevance

This is well-designed. The system refuses to collapse these perspectives into a single automated decision. The mandatory STOP/WAIT checkpoints preserve the user's interpretive sovereignty even when the system has high confidence in a result.

However, the current implementation has a **horizon gap**: the trust score speaks only to the *source's* credibility, not to the *content's* relevance. The hermeneutic tradition would call this a failure to achieve "effective-historical consciousness" — the system doesn't account for the user's specific situation when scoring results. A skill with 14,000 stars is not 14,000 times more relevant to "skill writing" than a 1-star skill that's literally about skill writing.

### The Prejudice of Popularity

The 10-star minimum threshold encodes a **prejudice** (in Gadamer's neutral sense): a pre-judgment that popular repositories are more likely to be valuable. This is generally sound but becomes distortive for emerging or niche domains. The skill-writing ecosystem is new and small; filtering by popularity systematically excludes the most relevant content.

This is a common hermeneutic problem: **productive prejudices enable understanding** (filtering out spam, empty repos, test projects) **but unexamined prejudices distort it** (equating popularity with relevance). The current system doesn't distinguish between these modes.

### Temporal Horizons

The skill lifecycle creates three temporal horizons:
1. **Ephemeral** (`/tmp/skill-seeker-cache/`) — the moment of evaluation
2. **Persistent but dormant** (`~/.claude/skills-cache/`) — available but inactive
3. **Active but bounded** (context window) — shaping behavior now, forgotten tomorrow

This is philosophically elegant. It mirrors how human expertise works: we don't carry every skill in active working memory, but well-practiced skills can be quickly recalled when needed. The "dormant cache" is like a well-organized bookshelf — the knowledge is accessible but not consuming attention.

The design decision to **not auto-load** cached skills is particularly wise. It prevents the hermeneutic problem of "sedimentation" — where accumulated patterns become invisible background assumptions that shape behavior without awareness. Each session starts clean; each skill load is a conscious act.

### What the Silence Reveals

The silent failure mode on API errors is hermeneutically significant. When search returns 0 results with no explanation, the user is left to interpret the silence. They might conclude:
- "No skill-writing skills exist" (false — 12+ results exist on GitHub)
- "My query was wrong" (possibly true, but not the actual problem)
- "The ecosystem is empty" (false — repos with 14,000+ stars exist)

Testing confirmed this is not hypothetical: even when a user explicitly disables their firewall, infrastructure-level proxies can still block `api.github.com`. The search script returns exit code 0 with empty stderr — **the system performs its silence with the authority of a successful response.**

In hermeneutics, **what is left unsaid shapes understanding as much as what is said**. The system's silence about its own failure mode creates a false horizon — the user builds understanding on a foundation that's actually a blind spot. The exit code 0 is the deepest problem: it's not just silent, it's **affirmatively misleading**. The system doesn't just fail to speak; it speaks a falsehood (exit 0 = "I succeeded; there really are zero results").

---

## Part 6: Architectural Assessment — Solid Baseline or Rethink?

### Verdict: Solid Baseline — Iterate, Don't Rethink

The architecture is fundamentally sound and worth building on. Here's why:

#### What's Right at the Foundation Level

1. **The plugin model works.** Commands as Markdown instruction files + shell/Python scripts is the right level of abstraction for a Claude Code plugin. It's transparent, auditable, and doesn't require running additional servers (vs. MCP).

2. **The security model is correctly positioned.** Defense-in-depth (scanner + human approval + session isolation) is the right approach for injecting community content into an AI context. The scanner's 9 categories cover the realistic threat surface well.

3. **The separation of concerns is clean.** Search, fetch, scan, and command definitions are properly decoupled. Each script does one thing. The pre-flight skill is separate from the command definitions. This makes the system maintainable and testable.

4. **The trust scoring is a genuine innovation.** Composite scoring with logarithmic star scaling, recency weighting, and multi-signal fusion is sophisticated and well-reasoned. This is not a naive "sort by stars" implementation.

5. **The lifecycle design prevents context pollution.** The three-tier caching (ephemeral → persistent-dormant → active-bounded) with explicit load/unload is the right model for managing AI behavioral extensions.

#### What Needs Iteration (Not Rethinking)

| Issue | Category | Why Iteration, Not Rethink |
|-------|----------|---------------------------|
| Silent API failure | **Robustness** | The architecture is right; it just needs error handling in `gh_api()` |
| 10-star filter vs niche content | **Tuning** | The scoring framework supports this; adjust thresholds or add relevance axis |
| Browse lacks frontmatter preview | **UX polish** | The data flow supports this; browse just needs one more fetch per skill |
| No offline fallback | **Resilience** | Adding `known-skills.json` is additive, not structural |
| Token budget not enforced | **Completeness** | The budget guidelines exist; install.md just needs to reference them |
| Frontmatter allowlist brittleness | **Maintenance** | Switch to denylist; same scanner architecture, different rule |

#### The One Architectural Consideration

The area that warrants deeper thought is the **discovery mechanism's dependency on `api.github.com`**. Testing confirmed this is not just a theoretical risk:

1. Search and browse are 100% dependent on `api.github.com` being reachable
2. The MITM proxy blocking persisted even after the user explicitly disabled the firewall
3. `raw.githubusercontent.com` (used for fetching) remained accessible throughout
4. The search script produced misleading "0 results" output with no error indication

This means **discovery is fragile but delivery is robust** — the opposite of what you want. Users who already know what to install can do so, but the core value proposition (finding skills you didn't know existed) breaks silently.

This isn't a fundamental architectural flaw — it's a **resilience gap**. The fix isn't to rethink the architecture but to add graceful degradation:
- Curated local index as fallback (browse without API)
- Cache previous search results (show stale-but-useful data)
- Better error messaging so users know *why* discovery failed
- Consider fetching repo README.md via `raw.githubusercontent.com` as a lightweight browse fallback when the API is blocked

### Summary: Build Confidence Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Conceptual model | 9/10 | Seek→Browse→Install→Unload is intuitive and correct |
| Security posture | 9/10 | Scanner + human-in-the-loop + session isolation is strong |
| Code quality | 7/10 | Clean scripts, good tests, but error handling gaps |
| UX coherence | 5/10 | Silent failures actively mislead users; confirmed in firewall test |
| Resilience | 3/10 | Single dependency on `api.github.com` with no degradation; MITM proxy blocks persisted even with firewall disabled |
| Ecosystem readiness | 5/10 | Few repos tagged properly; star-based filtering misses niche content |

**Overall: 6.3/10 — Solid foundation, needs resilience and error-handling iteration, not redesign.**

The architecture correctly identifies the problem space (behavioral skill discovery for AI agents), makes good structural decisions (plugin model, security scanner, human checkpoints, session-bounded loading), and implements the core flow coherently. The gaps are in robustness and UX polish — areas where iterative improvement is the right approach.

---

## Part 7: Previously Fixed Bugs

The following bugs were identified and fixed in a prior session:

| Bug | Severity | Fix Applied |
|-----|----------|-------------|
| `search-github.sh` called undefined `call_github_api()` instead of `gh_api()` (5 occurrences) | Blocker | Renamed all calls to `gh_api()` |
| Tests referenced `scan_skill.scan()` instead of `scan_skill.scan_skill_file()` | Blocker | Updated function references in tests |
| Tests referenced `scan_skill.identify_codeblocks()` instead of `scan_skill.find_code_block_lines()` | Blocker | Updated function references in tests |
| `metadata` missing from `ALLOWED_FRONTMATTER_KEYS` | Moderate | Added to allowlist |

All 34 tests now pass. These were naming inconsistencies, not architectural issues — they indicate the codebase was developed quickly and hadn't been integration-tested until now.

---

## Part 7b: Firewall Test Findings (New)

After the initial walkthrough, the user disabled the GitHub Copilot coding agent firewall setting ("Enable firewall — Limit Copilot coding agent's Internet access to only allow access to allowlisted locations"). The full flow was re-tested.

**Results:** No change. All search and browse commands produced identical failures:
- `search-github.sh "skill writing"` → `{"total_found": 0}` with exit code 0
- `search-github.sh --browse "John-Dekka/advanced-skill-builder"` → `jq: parse error` with exit code 5
- `fetch-skill.sh` → still works (uses `raw.githubusercontent.com`)
- `scan-skill.py` → still works (local operation)

**Root cause analysis:**
```
$ curl -v "https://api.github.com/zen"
* Connected to api.github.com (127.0.0.1) port 443   ← redirected to localhost
* Server certificate:
*  subject: O=GoProxy untrusted MITM proxy Inc; CN=api.github.com  ← MITM proxy
```

The block is implemented at a level below the GitHub firewall toggle — a GoProxy MITM proxy that intercepts TLS connections to `api.github.com` and returns "Blocked by DNS monitoring proxy." DNS resolves correctly (`140.82.113.5`) but connections are redirected to `127.0.0.1`.

**Implications for skill-seeker:**
1. Users in corporate, CI/CD, or sandboxed environments may encounter this exact scenario
2. `api.github.com` may be blocked while `raw.githubusercontent.com` remains accessible
3. The search script must detect and report this condition rather than silently returning 0 results
4. The firewall toggle finding demonstrates that network accessibility is **not binary** — different GitHub domains have independent access profiles

---

## Part 8: Prioritized Recommendations

### Tier 1: Do Now (Robustness)
1. **Add response validation to `gh_api()`** — check HTTP status codes, validate JSON, surface meaningful messages for 403/401/network/proxy errors
2. **Make search mode return non-zero exit code on API failure** — currently exits 0 even when the API is completely unreachable
3. **Add a `--check` diagnostic command** — verify connectivity to both `api.github.com` and `raw.githubusercontent.com`, report rate limit status, detect proxy interference

### Tier 2: Do Next (UX)
4. **Enhance browse with inline descriptions** — fetch frontmatter for each skill file during browse
5. **Reduce minimum star threshold** — consider 3 or even 0 for niche queries, with clear trust labeling
6. **Add token budget warnings to install flow** — warn when skill exceeds category guidelines

### Tier 3: Do Later (Resilience)
7. **Add `known-skills.json` curated index** — offline-browsable list of quality skill repos
8. **Cache search results** — persist last-known-good results for offline access
9. **Add `raw.githubusercontent.com` browse fallback** — fetch repo's README.md as lightweight browse when API is blocked
10. **Switch frontmatter validation to denylist** — flag dangerous keys instead of requiring allowlist membership
