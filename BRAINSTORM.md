# Brainstorm: Next Implementation Phases

*A hermeneutic reflection on what skill-seeker is, what it's becoming, and where the real leverage lies.*

---

## The Central Question: What Is Skill-Seeker's Actual Job?

Skill-seeker is a **middleman**. Its job is to get community-created behavioral frameworks (`.md` files that shape Claude's approach) from GitHub into the current Claude Code context. That's it. Once the skill is loaded, skill-seeker's job is done — the skill itself takes over.

This means skill-seeker lives under a fundamental constraint: **every token it adds to context is overhead that competes with the skill it's delivering.** A 961-token pre-flight SKILL.md that helps you find a 2,000-token design audit skill means 32% of the total skill-relevant context is overhead. That matters.

### Current Token Budget

| Component | Tokens | When | Purpose |
|-----------|--------|------|---------|
| `SKILL.md` (pre-flight) | ~961 | Always loaded | Teaches Claude when to suggest skill search |
| `seek.md` command | ~488 | On `/seek` invocation | Instructions for search flow |
| `browse.md` command | ~269 | On `/browse` invocation | Instructions for browsing |
| `install.md` command | ~536 | On `/install` invocation | Instructions for install flow |
| `unload.md` command | ~505 | On `/unload` invocation | Instructions for cleanup |
| **Total persistent overhead** | **~961** | **Always** | **The tax for having skill-seeker** |
| **Total peak overhead** | **~2,759** | **During install flow** | **SKILL.md + seek + browse + install** |

**961 tokens always loaded** is not terrible. It's roughly 3 paragraphs. But the question is: is it earning those tokens?

---

## Hermeneutic Analysis: What The Current Flow Reveals About Itself

### The Pre-flight Skill is Doing Two Jobs Badly Instead of One Job Well

The `SKILL.md` currently contains:
1. **When to suggest searching** (good — this is the trigger logic)
2. **How to present results** (duplicated from `seek.md`)
3. **Security protocol details** (duplicated from `install.md`)
4. **Token budget guidelines** (meta-information about skills in general)
5. **Common mistakes** (operational guidance)

Items 2-5 don't need to be in the always-loaded pre-flight. They're instructions for *executing* a search, not for *deciding whether to search*. Claude already gets those instructions when the user invokes `/seek` or `/install`.

**Hermeneutic insight**: The SKILL.md is trying to be both a *trigger* ("should I search?") and a *manual* ("how do I search?"). It should be a trigger only. The manual lives in the commands.

**Concrete fix**: Slim the SKILL.md to ~200 tokens:
```markdown
# Seeking Community Skills

Before tackling complex or domain-specific tasks, consider whether a community skill
might exist. Use `/skill-seeker:seek <query>` to search.

## When to suggest
- Specialized domains (design, Terraform, Playwright, scientific computing)
- Tasks where "best practices" or "taste" matter  
- User explicitly asks for skills/frameworks

## When NOT to suggest
- Simple, well-understood tasks
- You already have a loaded skill for this domain
- User says not to search
```

That's ~200 tokens instead of ~961. **A 5x reduction in permanent overhead.** The detailed protocol, security rules, and formatting instructions stay in the command files where they belong.

### The Four-Command Structure Has a Missing Step

The current flow is:
```
seek → browse → install → (use) → unload
```

But there's a gap between `seek` and `browse`. When the user says "find me a design skill," Claude must:
1. Run `search-registry.sh` (instant, local)
2. Run `search-github.sh` (API, slower)
3. Merge results from two different JSON formats
4. Present a combined table
5. Wait for user to pick a repo
6. Then invoke `/browse` on that repo

Steps 1-4 happen in Claude's reasoning, not in a script. There's no `search-combined.sh` that merges both sources. Claude is doing JSON munging in its head, which is both unreliable and wastes tokens on reasoning.

**Hermeneutic insight**: The seek command describes a process that *should* be automated but *isn't*. Claude is being asked to act as glue code between two scripts that could easily be composed.

**Concrete fix**: Create `scripts/search-combined.sh` that:
1. Runs registry search
2. Runs GitHub API search (with graceful failure)
3. Deduplicates by `repo` field
4. Outputs a unified JSON result set
5. Includes source attribution per result

This reduces Claude's cognitive load during search from "run two scripts, parse two JSONs, merge them, deduplicate" to "run one script, present the table."

### Browse → Install Transition Is Unnecessarily Manual

After browsing a repo, Claude shows a table of skills and waits for the user to type `/skill-seeker:install owner/repo/path`. But the path is already known from the browse results. The user shouldn't have to construct the install command — they should just say "install #3" and Claude should construct it.

This already sort of works because Claude can reason about the table, but the `install.md` command requires parsing `owner/repo/path` from scratch. If browse passed its results to install, the transition would be smoother.

**Hermeneutic insight**: The separation between browse and install creates a *hermeneutic gap* — the user has to re-state knowledge that the system already has. This is friction that skill-seeker is supposed to eliminate.

**This isn't a code change** — it's a seek/browse/install instruction improvement. The commands should explicitly say: "when the user says 'install #3', look up the path from the browse results and construct the install command automatically."

### The Unload Command Is a Noble Lie

`unload` cleans up files, but it cannot remove text from the active context. The command's documentation says this honestly, but it's still a command that does *less than what its name implies*. Renaming it to `/skill-seeker:cleanup` would be more accurate.

More importantly: **do we even need unload?** Skills in `/tmp/` get cleaned up on reboot. Skills in `skills-cache/` are deliberately persistent. The `.claude-skills-temp/` directory is rarely used. Is maintaining this command worth the ~505 tokens of command definition?

**Hermeneutic insight**: Unload exists to give users a sense of control over context. But the real "unload" is ending the session. The command provides *emotional* value (I can clean up) but limited *functional* value (the text is still in context).

**Recommendation**: Keep it but slim it significantly. Maybe 100 tokens instead of 505.

---

## What's Missing: The Gaps in the Flow

### 1. No "What Skills Am I Running?" Command

Once a skill is loaded, there's no way to ask "what skills are currently active in my context?" You could scroll back through the conversation, but there's no command like `/skill-seeker:status` that summarizes:
- Which skills were loaded this session
- Their origins and trust levels
- How many tokens each consumed
- Total skill context budget used

**Why this matters**: If you've loaded 3 skills that total 8,000 tokens, you might want to know before loading a 4th. There's no visibility into context budget consumption.

### 2. No Direct Install from Registry

If a skill is in the registry, the user shouldn't need to go through seek → browse → install. They should be able to say `/skill-seeker:install skill-builder` and have it resolve through the registry.

The registry already has `repo` and `path` fields. A shorthand install that looks up the registry entry, fetches by repo+path, and skips the browse step would save significant interaction overhead.

### 3. No Skill Recommendations

The pre-flight SKILL.md says "consider whether a community skill might exist" — but it doesn't *recommend specific skills for specific situations*. With 13 entries in the registry, we could hard-code a few trigger patterns:

| If the user is doing... | Suggest... |
|--------------------------|-----------|
| Frontend/design work | `pbakaus/impeccable` |
| Writing/editing | `blader/humanizer` |
| Scientific work | `K-Dense-AI/claude-scientific-skills` |
| Skill creation | `metaskills/skill-builder` |

This turns the pre-flight from passive ("should I search?") to active ("here's a specific skill that might help").

### 4. No Skill Pinning/Favorites

Users who find a good skill want to use it again next session without going through the full seek → browse → install flow. Currently they'd need to manually `cat ~/.claude/skills-cache/owner/repo/SKILL.md`. There's no `/skill-seeker:reload` or `/skill-seeker:favorites` command.

### 5. No Multi-Skill Install

When browsing a repo with 7 skills, users can't say "install 2, 4, and 6." They must install one at a time, each going through fetch → scan → approve → load. A batch install with a combined scan report would be more practical.

---

## What Could Be More Autonomous?

### Currently: Claude Decides Whether to Search (But Doesn't Act)

The SKILL.md says to search but then demands user confirmation at two points:
1. After showing search results ("pick a repo")
2. After security scan ("approve installation")

**Point 1 is debatable.** If the registry has a verified, HIGH trust skill that exactly matches the domain, should Claude really wait for permission to browse it? The security scan + approval at point 2 is the real safety gate.

**Proposal**: Add an "auto-browse" mode for verified registry skills. If a registry skill matches with HIGH trust and the query is specific enough, Claude browses automatically and presents skills directly, collapsing seek+browse into one step.

This would change the flow from:
```
seek → [user picks repo] → browse → [user picks skill] → install → [user approves]
```
To:
```
seek → browse (auto for verified) → [user picks skill] → install → [user approves]
```

One less interaction cycle. The security checkpoint at install remains mandatory.

### Currently: Each Session Starts Cold

Every new Claude Code session starts with zero skills loaded (by design, to prevent context pollution). But for users who work on the same type of project daily, re-loading the same skills each session is friction.

**Proposal**: A `.skill-seeker-profile.json` file in the project root that declares preferred skills:
```json
{
  "auto_suggest": [
    {"skill": "pbakaus-impeccable-v1", "reason": "Frontend project"},
    {"skill": "metaskills-skill-builder-v1", "reason": "Skill development project"}
  ]
}
```

On session start, the pre-flight SKILL.md checks for this file and proactively suggests: "I notice this project has preferred skills. Want me to load the Impeccable Design Audit skill?" Still requires user approval (human-in-the-loop), but eliminates the seek/browse cycle for known-good skills.

---

## Is The Skill Taking Too Much Context?

### The Overhead Math

**Current state**: ~961 tokens permanently loaded via SKILL.md.

For a typical 200k token context window, this is 0.5%. Negligible.

But context window math is misleading because **the first ~4,000 tokens have disproportionate influence** on Claude's behavior (recency bias). If skill-seeker's SKILL.md is loaded early (as skills typically are), it occupies valuable real estate in the "priming zone."

**The real question**: Does the pre-flight SKILL.md cause Claude to over-suggest skill searches? If Claude starts every complex task with "let me search for a skill first," that's the overhead becoming a tax on *every interaction*, not just skill-relevant ones.

### The "When NOT to Use" Section is Load-Bearing

The SKILL.md's "When NOT to Use" section is actually the most important part:
```
- Simple, well-understood tasks
- Tasks where you already have a loaded skill
- When the user explicitly says not to search
```

Without this, Claude would suggest skill search for every non-trivial request. The negative guidance is what keeps the overhead tolerable.

### Recommendation: Slim, Don't Remove

The pre-flight is valuable — it's what makes skill-seeker proactive rather than purely reactive. But it should be:
- **~200 tokens** (not 961)
- **Trigger-focused** (when to suggest, when not to)
- **No duplication** of command instructions
- **No operational details** (security protocol, token budgets, common mistakes)

Those details belong in the command files that are loaded on-demand.

---

## Architectural Re-Think Considerations

### Should We Stay Plugin? Or Go MCP?

The ARCHITECTURE.md explicitly chose Plugin over MCP Server, citing:
- Native integration with `/commands`
- No external process to manage
- Simpler for read-only search

**This was the right call for v0.1.** But MCP would offer:
- **Structured tool calls**: Instead of Claude parsing JSON output from bash scripts, MCP tools return typed data
- **Streaming**: Search results could stream in as they arrive
- **State management**: Track loaded skills, context budget, favorites
- **Better composability**: Tools can call other tools

**My assessment**: Stay with Plugin for now. The MCP migration would be high-effort for marginal UX gain. The current architecture's biggest problems (context overhead, missing combined search) are fixable within the plugin model.

### The Registry-First Future

The research branch's 5-phase roadmap goes:
```
Phase 1: Curated Registry ← DONE
Phase 2: Multi-source search
Phase 3: Local caching
Phase 4: Semantic search
Phase 5: Community growth
```

I'd argue the ordering should shift. Phase 3 (local caching) should come before Phase 2 (multi-source search), because:
1. The registry already solves "skill not found" for known skills
2. GitHub search already finds everything else
3. GitLab search adds marginal value (few claude skills are on GitLab)
4. But loading a previously-installed skill from cache (Phase 3) would **dramatically** reduce friction for returning users

**Revised priority**: Registry (done) → Cache/reload (high impact) → Slim SKILL.md (quick win) → Combined search script (moderate) → Multi-source (low priority).

---

## Proposed Next Phases (Prioritized by User Impact)

### Phase A: Reduce Context Overhead (Quick Win, 1-2 hours)
- Slim `SKILL.md` from ~961 to ~200 tokens (trigger-only)
- Move protocol/security/token-budget details into command files
- Slim `unload.md` from ~505 to ~150 tokens
- **Impact**: 60% reduction in permanent context overhead

### Phase B: Combined Search Script (Medium, 2-4 hours)
- Create `scripts/search-combined.sh` that merges registry + GitHub results
- Single unified JSON output with source attribution
- Update `seek.md` to call one script instead of two
- **Impact**: More reliable search, less Claude reasoning overhead

### Phase C: Registry Quick-Install (Medium, 2-3 hours)
- Allow `/skill-seeker:install <registry-id>` (e.g., `install skill-builder`)
- Resolve repo+path from registry, skip browse step
- **Impact**: 2-step flow for known skills instead of 4-step

### Phase D: Skill Status Command (Small, 1-2 hours)
- New `/skill-seeker:status` command
- Lists skills loaded this session with token counts
- Shows total context budget consumed
- **Impact**: Context visibility, prevents overloading

### Phase E: Project Skill Profiles (Medium, 3-4 hours)
- `.skill-seeker-profile.json` in project root
- Pre-flight suggests preferred skills on session start
- Still requires user approval
- **Impact**: Eliminates repeat seek/browse cycles for daily-use skills

### Phase F: Reload from Cache (Medium, 2-3 hours)  
- New `/skill-seeker:reload` command
- Lists previously installed skills from `~/.claude/skills-cache/`
- Quick re-load without re-fetching or re-scanning (SHA256 integrity check)
- **Impact**: Sub-second skill loading for returning users

### Phase G: Auto-Browse for Verified Skills (Small, 1-2 hours)
- When registry returns a HIGH trust verified match, auto-browse instead of waiting
- Collapse seek+browse into one interaction for verified skills
- **Impact**: One fewer confirmation step for known-good skills

---

## The One-Line Summary

**Skill-seeker's biggest opportunity isn't finding more skills — it's reducing the friction of loading skills it already knows about.** The registry solved discovery. Now solve delivery.

---

## Open Questions

1. **Should the pre-flight SKILL.md include specific skill recommendations?** (e.g., "for design work, try impeccable") — this makes it more useful but increases coupling to the registry.

2. **Should cache reload skip the security scan?** The SHA256 check confirms the file hasn't changed since it was last scanned. Is that sufficient, or should we re-scan every time?

3. **Is there a world where skill-seeker loads itself only when needed?** Instead of being always-active via SKILL.md, could it be a purely on-demand `/skill-seeker:seek` with no pre-flight trigger? This would reduce overhead to zero but lose proactive suggestions.

4. **Should we track which skills users actually install?** Anonymous analytics (opt-in) could inform registry curation and synonym expansion. But adds privacy considerations.

5. **When the ecosystem grows to 100+ skills, does the registry approach still scale?** At what point do we need actual search infrastructure (embeddings, vector DB) instead of tag-matching in a JSON file?
