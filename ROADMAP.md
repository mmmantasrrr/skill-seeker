# Skill-Seeker Project Roadmap

*A living document describing where Skill-Seeker has been, where it is now, and where it's going.*

---

## ✅ Completed Milestones

### v0.1.0 — Foundation (Initial Release)
**Status**: Released 2026-03-10

The first public release established the core discovery pipeline:

- **Curated registry** (`registry.json`) with verified, community-validated skills
- **Hybrid search**: registry (instant, offline) + GitHub API (live, comprehensive)
- **Security scanner** with 9 detection categories (instruction overrides, command injection, data exfiltration, hidden content, social engineering, encoded payloads, and more)
- **Trust scoring system** based on stars, activity, and community validation
- **Query synonym expansion** for better discoverability (e.g., "react" → "component", "hooks", "frontend")
- **Four commands**: `/seek`, `/browse`, `/install`, `/unload`
- **Caching system** for fetched skills (`~/.claude/skills-cache/`)
- **GITHUB_TOKEN support** for higher API rate limits
- Comprehensive documentation: ARCHITECTURE.md, CONTRIBUTING-REGISTRY.md, RESEARCH-SKILL-DISCOVERY.md

---

### v2.0.0 — Friction Reduction
**Status**: Implemented 2026-03-10

All seven phases from the [BRAINSTORM.md](BRAINSTORM.md) friction analysis were implemented:

#### Phase A: Context Overhead Reduction ✅
- Slimmed `SKILL.md` from ~961 tokens to ~200 tokens (79% reduction in permanent overhead)
- Moved security protocol, token budgets, and operational details into command files
- SKILL.md is now a pure trigger: when to suggest, when NOT to suggest

#### Phase B: Combined Search Script ✅
- Created `scripts/search-combined.sh` — merges registry + GitHub results
- Automatic deduplication by repository name (registry takes priority)
- Unified JSON output with source attribution
- Eliminates Claude's manual JSON merging during search

#### Phase C: Registry Quick-Install ✅
- `/skill-seeker:install <registry-id>` resolves repo+path from registry
- `scripts/resolve-skill-id.sh` handles IDs with or without `-v1` suffix
- Reduces known-skill flow from 4 steps to 2 steps

#### Phase D: Status Command ✅
- New `/skill-seeker:status` command
- Shows loaded skills, token counts, context budget consumed

#### Phase E: Project Skill Profiles ✅
- `.skill-seeker-profile.json` in project root declares preferred skills
- Pre-flight SKILL.md suggests profile skills on session start
- Human-in-the-loop: still requires user approval

#### Phase F: Cache Reload ✅
- New `/skill-seeker:reload` command
- Loads previously installed skills from `~/.claude/skills-cache/`
- SHA256 integrity check — skips re-fetch and re-scan for unchanged files

#### Phase G: Auto-Browse for Verified Skills ✅
- HIGH trust verified registry results auto-browse, collapsing seek+browse into one step
- Security checkpoint at install remains mandatory

---

## 🔭 Planned Phases

### v2.1 — Quality of Life
**Priority: High | Estimated effort: 1–2 weeks**

These are targeted improvements to existing functionality with high user impact and low implementation risk:

- **Skill update notifications**: When reloading from cache, detect if the upstream skill has a newer version and alert the user
- **Profile inheritance**: Allow `.skill-seeker-profile.json` to extend a base/org-level profile (e.g., `"extends": "~/.claude/base-profile.json"`)
- **Multi-skill batch install**: Install multiple skills in one command (`/skill-seeker:install 2,4,6` from browse results)
- **Slim `unload.md` further**: Reduce from current ~150 tokens to ~80 tokens (command is rarely needed; context stays until session ends)
- **Improved error messages**: When GitHub API is rate-limited or blocked, surface actionable advice (set GITHUB_TOKEN, retry, use registry only)

---

### v2.2 — Multi-Source Discovery
**Priority: Medium | Estimated effort: 2–3 weeks**

Expand skill discovery beyond GitHub:

- **GitLab search**: Add `scripts/search-gitlab.sh` and integrate into `search-combined.sh`
- **GitHub Code Search**: Switch to GitHub's code search API for better signal/noise ratio (finds skills by content, not just repo metadata)
- **Local skill directories**: Allow searching a local path (e.g., `~/my-skills/`) for private/team skills not on any registry
- **Update `search-combined.sh`** to handle 3+ sources with consistent trust normalization

---

### v2.3 — Skill Ecosystem Health
**Priority: Medium | Estimated effort: 2–3 weeks**

Make the registry more self-sustaining:

- **Custom scan rules**: Let users add project-specific security scan rules via `.skill-seeker-scan-rules.json`
- **Skill dependencies**: Allow a skill to declare it requires another skill (e.g., a Playwright skill requires a test-runner skill)
- **Registry auto-update check**: Detect if the local registry.json is stale and prompt the user to update skill-seeker
- **Expanded registry**: Target 30+ verified skills across more domains (Terraform, security auditing, scientific computing, writing/editing, etc.)
- **Registry submission tooling**: Streamline the process of submitting a new skill (linting, format validation, test)

---

### v3.0 — Semantic Discovery
**Priority: Medium-Low | Estimated effort: 4–6 weeks**

Move from keyword/tag matching to meaning-based discovery:

- **Embedding-based search**: Index skill READMEs and SKILL.md files with embeddings; match by semantic similarity instead of keyword overlap
- **Intent classification**: Given a user's task description, classify the intent and suggest relevant skills without requiring a search query
- **Skill recommendation engine**: "Users who loaded X also found Y useful" — collaborative filtering over anonymous usage patterns (opt-in only)
- **Usage analytics (opt-in)**: Privacy-preserving, anonymous tracking of which skills get installed and how often, to inform registry curation

> **Note**: This phase requires infrastructure beyond bash scripts (a lightweight embedding server or external API). Evaluate whether to implement in-process (Python, local model) or via an external service. MCP migration may become worthwhile at this phase.

---

### v3.1 — Community Platform
**Priority: Low | Estimated effort: 6–10 weeks**

Build the ecosystem around Skill-Seeker:

- **Browser-based skill marketplace**: Web UI for browsing, searching, and previewing skills without Claude Code
- **Skill ratings and reviews**: Let users rate skills and leave comments (GitHub Discussions integration)
- **Skill author profiles**: Registry entries link to author profiles with their full skill catalog
- **Trending skills**: Highlight recently popular or newly submitted skills
- **Weekly digest**: Optional email/RSS feed of new registry additions

---

### Long-Term Considerations

These are open questions that will inform which direction future phases take:

1. **MCP migration**: Converting from Plugin to MCP Server would enable structured tool calls, streaming results, and stateful session tracking. Current assessment: high effort for marginal gain. Re-evaluate after v3.0 when complexity may justify it.

2. **On-demand loading only**: Instead of always-active pre-flight (SKILL.md), skill-seeker could be purely reactive — only active when explicitly invoked. Zero permanent overhead, but loses proactive suggestions. Evaluate after measuring how often the pre-flight triggers usefully.

3. **Registry scaling**: At 100+ skills, the current tag-matching approach in `registry.json` may need to evolve toward a structured schema with categories, subcategories, and formal tagging taxonomy.

4. **Team/org registries**: Organizations should be able to host their own private registry (a `registry.json` at a known URL) that skill-seeker can pull from alongside the public one.

5. **Skill versioning**: Skills evolve over time. A formal version contract (semantic versioning for SKILL.md schemas) would allow `reload` to safely distinguish "same version, safe to skip re-scan" from "updated, re-scan required."

---

## 📊 Milestone Summary

| Version | Theme | Status | Impact |
|---------|-------|--------|--------|
| v0.1.0 | Foundation | ✅ Released | Core discovery pipeline |
| v2.0.0 | Friction Reduction | ✅ Released | 79% overhead cut, 7 UX improvements |
| v2.1 | Quality of Life | 🔭 Planned | Batch install, update alerts, profile inheritance |
| v2.2 | Multi-Source Discovery | 🔭 Planned | GitLab, code search, local dirs |
| v2.3 | Ecosystem Health | 🔭 Planned | Dependencies, custom scan rules, bigger registry |
| v3.0 | Semantic Discovery | 🔭 Planned | Embeddings, intent classification, analytics |
| v3.1 | Community Platform | 🔭 Planned | Web marketplace, ratings, trending |

---

## 🗳️ Influencing the Roadmap

The ordering above reflects current best judgment of user impact vs. implementation effort. Community feedback can shift priorities significantly.

To influence what gets built next:
- **Vote on issues**: Upvote existing feature requests with 👍
- **Open a feature request**: Use the [feature request template](https://github.com/mmmantasrrr/skill-seeker/issues/new/choose)
- **Contribute**: PRs for v2.1 quality-of-life improvements are especially welcome — the scope is well-defined and bounded
- **Registry submissions**: Every new verified skill added to `registry.json` advances the ecosystem regardless of code changes

---

*Last updated: 2026-03-10*
