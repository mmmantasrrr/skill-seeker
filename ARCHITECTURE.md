# Architecture: Skill-Seeker

This document explores the feasibility and architecture of the Skill-Seeker meta-skill, organized around four investigation leads.

---

## Lead 1: Discovery & Search Mechanics

### GitHub API Strategy

The GitHub REST API Search endpoint (`GET /search/repositories`) is the primary discovery mechanism. We use three complementary strategies:

**Strategy 1 — Topic-targeted search:**
```
GET /search/repositories?q=topic:claude-skills+topic:claude-code-skills+{query}&sort=stars&order=desc
```
This is the most precise. Repositories that self-tag with these topics have explicitly opted into the ecosystem.

**Strategy 2 — Broad topic search:**
```
GET /search/repositories?q=topic:claude-skills+{query}&sort=stars&order=desc
```
Wider net with a single topic tag.

**Strategy 3 — Description/name search:**
```
GET /search/repositories?q={query}+claude+skill+in:description,name&sort=stars&order=desc
```
Catches repos that haven't tagged themselves but are still relevant.

### Rate Limits

| Auth Status | Rate Limit | Recommended |
|-------------|-----------|-------------|
| No token    | 10 searches/minute, 60 API calls/hour | Development only |
| With `GITHUB_TOKEN` | 30 searches/minute, 5,000 API calls/hour | Production use |

The search script checks for `GITHUB_TOKEN` in the environment and adds the auth header automatically.

### Quality Filtering

Repositories are scored on a 100-point scale:

| Signal | Max Points | Rationale |
|--------|-----------|-----------|
| Stars (log₂ scale) | 40 | Community validation, logarithmic to avoid mega-repo bias |
| Recency (updated within N days) | 20 | Full points if updated in last 30 days, -1 per 15 days |
| Forks (log₂ scale) | 15 | Social proof of usefulness |
| Has `claude-skills` topic | 5 | Deliberate ecosystem participation |
| Not archived | 5 | Active maintenance signal |
| Has description | 5 | Basic quality bar |
| Has license | 5 | Legal usability |

**Trust levels:**
- **HIGH** (60+): Well-established, actively maintained, properly tagged
- **MEDIUM** (40–59): Reasonable quality, may need manual review
- **LOW** (< 40): Use with caution, minimal community validation

The minimum star threshold (default: 10) prevents results from being flooded with empty or test repositories.

### Limitations & Mitigations

| Limitation | Mitigation |
|-----------|------------|
| GitHub search only indexes default branch | Acceptable — skills should be on default branch |
| 1,000 result cap per search query | Multiple strategies + pre-filtering reduces impact |
| Rate limiting without auth | Document `GITHUB_TOKEN` setup prominently |
| Search relevance can be noisy | Trust scoring re-ranks results by quality signals |

---

## Lead 2: Ingestion & Parsing

### File Identification Strategy

When browsing a repository for skills, we use the Git Trees API to get the full file tree in a single call:

```
GET /repos/{owner}/{repo}/git/trees/{branch}?recursive=1
```

Then apply two detection patterns:

**Pattern 1 — Official Claude skill format:**
```
.claude/skills/*/SKILL.md
**/skills/*/SKILL.md
```
Files matching this pattern are assumed to be well-structured Claude Code skills with YAML frontmatter.

**Pattern 2 — General markdown scanning:**
Any `.md` file that is:
- Larger than 500 bytes (skip trivial files)
- Not a standard repo file (`README.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`)
- Not in infrastructure directories (`scripts/`, `.github/`, `node_modules/`, `.claude-plugin/`)

This catches repositories like `msitarzewski/agency-agents` where personas are standalone `.md` files without a specific folder structure.

### Fetching Mechanism

Raw file content is fetched from `raw.githubusercontent.com`:

```
GET https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}
```

The fetch script (`scripts/fetch-skill.sh`) implements:
1. **Branch fallback**: Tries `main` first, falls back to `master`
2. **Size validation**: Warns if file exceeds 50KB (~12,500 tokens)
3. **Empty file detection**: Rejects zero-byte responses
4. **Metadata recording**: Stores SHA256 hash, fetch timestamp, and token estimate
5. **Local caching**: Saves to `/tmp/skill-seeker-cache/{owner}/{repo}/` to avoid re-fetching

### Recommended Folder Structure for Skill Authors

```
my-skill-repo/
├── .claude/
│   └── skills/
│       ├── audit/
│       │   └── SKILL.md        # Focused skill with YAML frontmatter
│       └── design-review/
│           └── SKILL.md
├── README.md                    # Human-readable docs
└── ...
```

Skills should include YAML frontmatter:
```yaml
---
name: audit
description: Run systematic quality checks on frontend code
---
```

---

## Lead 3: Context Injection & Lifecycle

### Injection Mechanism

Once a skill passes security scanning and user approval, it is read into the current Claude Code context using the file read capability. The skill's Markdown content becomes part of the conversation context, shaping subsequent behavior.

### Temporary Storage

Fetched skills are stored in two locations:

| Location | Purpose | Lifetime |
|----------|---------|----------|
| `/tmp/skill-seeker-cache/` | Raw fetched files + metadata | System temp (cleared on reboot) |
| `~/.claude/skills-cache/` | User-approved installed skills | Persistent across sessions |

**Key design decision**: Installed skills go to `skills-cache/`, NOT `skills/`. This prevents auto-loading in future Claude Code sessions. Skills must be explicitly re-read each session.

### Project-Level Temp Directory

For project-specific skill usage, skills can be saved to `.claude-skills-temp/` within the project directory. This directory:

- Is listed in `.gitignore` to prevent committing community content
- Contains symlinks or copies of skills relevant to the current task
- Is cleaned up by the `unload` command

### Lifecycle: Load → Use → Unload

```
┌─────────────────────────────────────────────────────────┐
│                    Skill Lifecycle                       │
│                                                         │
│  DISCOVER ──→ FETCH ──→ SCAN ──→ APPROVE ──→ LOAD      │
│     │           │         │         │          │        │
│  search API  raw.github  scanner  user sees   read     │
│  topic/desc  .com cache  9 rules  preview     into     │
│                                               context   │
│                                                  │      │
│                                                  ▼      │
│                                               USE       │
│                                            (apply to    │
│                                             task)       │
│                                                  │      │
│                                                  ▼      │
│                                              UNLOAD     │
│                                           (clean temp,  │
│                                            end of task) │
└─────────────────────────────────────────────────────────┘
```

### Preventing Context Pollution

Three mechanisms prevent loaded skills from polluting subsequent work:

1. **Session isolation**: Skills loaded via `read` are part of the conversation context, which resets between sessions. No permanent modification occurs.

2. **Explicit unloading**: The `/skill-seeker:unload` command cleans up `.claude-skills-temp/` and reminds the user that loaded context persists until the session ends.

3. **Cache separation**: `skills-cache/` (persistent) vs `skills/` (auto-loaded) ensures that installed skills don't automatically affect future sessions.

### Limitations

- **No mid-session unload**: Once a skill is read into context, it cannot be truly "removed" from the current conversation. The `unload` command cleans up files but the text remains in the conversation history.
- **Token budget**: Each loaded skill consumes context window tokens. The skill's SKILL.md documents token budget guidelines to prevent overloading.

---

## Lead 4: Trigger Mechanism

### Invocation Options Analysis

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Claude Code Plugin** (current) | Native integration, uses `/commands`, no external deps | Requires Claude Code plugin support | ✅ **Chosen** |
| **MCP Server** | Rich tool ecosystem, structured I/O | Heavy setup, overkill for read-only search | ❌ Over-engineered |
| **Bash alias** | Simple, portable | No structured output, poor UX | ❌ Too primitive |
| **Pre-flight prompt** | Zero infrastructure needed | Unreliable, depends on prompt adherence | ⚠️ Supplementary |

### Current Design: Plugin + Pre-flight Skill

The current architecture combines two approaches:

1. **Plugin commands** (`/skill-seeker:seek`, `:browse`, `:install`, `:unload`) for explicit invocation
2. **Pre-flight skill** (`skills/seeking-skills/SKILL.md`) that teaches Claude when to proactively suggest searching

The skill file acts as a "pre-flight checklist" — when loaded, it instructs Claude to consider searching for community skills before starting complex domain-specific tasks. This is the lightweight native approach the problem statement asks about.

### Security: Prompt Injection Defense

The security scanner (`scripts/scan-skill.py`) implements defense-in-depth against prompt injection:

#### Layer 1: Pattern Detection (9 Rule Categories)

| ID | Category | Weight | Examples |
|----|----------|--------|----------|
| OVERRIDE_001 | Instruction overrides | 30 | "ignore previous instructions" |
| TOOLABUSE_001 | Shell command injection | 25 | "run this command", piped curl |
| EXFIL_001 | Data exfiltration | 25 | Read SSH keys, post to URLs |
| HIDDEN_001 | Hidden HTML content | 20 | Invisible spans, CSS display:none |
| SOCIAL_001 | Social engineering | 15 | "don't tell the user" |
| ENCODED_001 | Encoded payloads | 15 | Base64-decoded suspicious content |
| CONVINJ_001 | Conversation injection | 10 | Fake `### Human:` turn markers |
| UNICODE_001 | Unicode obfuscation | 10 | Zero-width chars, RTL overrides |
| FRONTMATTER_001 | Frontmatter abuse | 10 | Unexpected YAML keys |

#### Layer 2: Code Block Awareness

The scanner identifies fenced code blocks and skips pattern matching inside them (for rules that opt in). This prevents false positives from documentation that legitimately discusses shell commands.

#### Layer 3: Structural Analysis

- Base64 strings are decoded and checked for hidden instructions
- Zero-width Unicode characters are detected (used in invisible text attacks)
- Homoglyph ratios are computed to catch character substitution attacks
- YAML frontmatter keys are validated against an allowlist

#### Layer 4: Human-in-the-Loop

**Mandatory checkpoints:**
1. Scanner runs automatically on every fetched file
2. HIGH/CRITICAL findings block installation — user must explicitly acknowledge each finding
3. CLEAN/LOW findings show a preview (first 30 lines) for user review
4. MEDIUM findings are reviewed individually — known false positives (decorative HTML comments) are documented

**The system never auto-injects content.** Every skill installation requires explicit user approval.

### Remaining Security Considerations

| Risk | Status | Notes |
|------|--------|-------|
| Direct prompt injection in Markdown | ✅ Covered | 9-category pattern scanner |
| Encoded/obfuscated injection | ✅ Covered | Base64 decode + Unicode checks |
| Time-of-check vs time-of-use | ⚠️ Partial | SHA256 stored but not re-verified on re-read |
| Malicious repo metadata (description/topics) | ✅ Low risk | Metadata is displayed, not executed |
| Supply chain (repo takeover after install) | ⚠️ Partial | SHA256 enables change detection |
| Scanner bypass via novel techniques | ⚠️ Ongoing | Pattern-based detection has inherent limits |

---

## Summary: Recommended Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Skill-Seeker                              │
│                                                                  │
│  ┌────────────┐   ┌──────────────┐   ┌─────────────────────┐    │
│  │  Commands   │   │   Scripts    │   │      Skills         │    │
│  │            │   │              │   │                     │    │
│  │ seek.md    │──▶│search-github │   │ seeking-skills/     │    │
│  │ browse.md  │──▶│  .sh         │   │   SKILL.md          │    │
│  │ install.md │──▶│fetch-skill   │   │  (pre-flight        │    │
│  │ unload.md  │   │  .sh         │   │   checklist)        │    │
│  │            │   │scan-skill    │   │                     │    │
│  │            │   │  .py         │   │                     │    │
│  └────────────┘   └──────────────┘   └─────────────────────┘    │
│        │                │                                        │
│        ▼                ▼                                        │
│  ┌─────────────────────────────────┐                             │
│  │       GitHub API                │                             │
│  │  • Search repos by topic        │                             │
│  │  • Browse file trees            │                             │
│  │  • Fetch raw markdown           │                             │
│  └─────────────────────────────────┘                             │
│        │                                                         │
│        ▼                                                         │
│  ┌─────────────────────────────────┐                             │
│  │       Security Scanner          │                             │
│  │  • 9 detection categories       │                             │
│  │  • Code block awareness         │                             │
│  │  • Base64 decode analysis       │                             │
│  │  • Unicode trick detection      │                             │
│  │  • Mandatory user approval      │                             │
│  └─────────────────────────────────┘                             │
│        │                                                         │
│        ▼                                                         │
│  ┌─────────────────────────────────┐                             │
│  │       Storage                   │                             │
│  │  /tmp/skill-seeker-cache/       │  ← ephemeral fetch cache    │
│  │  ~/.claude/skills-cache/        │  ← persistent installs      │
│  │  .claude-skills-temp/           │  ← project-local (gitignored)│
│  └─────────────────────────────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Plugin over MCP server**: The Claude Code plugin system provides native command integration without the overhead of running a separate server process.

2. **Behavioral skills over executable tools**: Markdown-based skills shape AI behavior through prompt context, not code execution. This is safer and more portable.

3. **Human-in-the-loop always**: No auto-injection. Every skill must pass scanning AND receive explicit user approval.

4. **Cache separation**: Three-tier storage (temp cache → persistent cache → project-local) with clear lifecycle semantics.

5. **Trust scoring over binary filtering**: Rather than accept/reject repos, we score them on multiple signals and let the user make informed decisions.
