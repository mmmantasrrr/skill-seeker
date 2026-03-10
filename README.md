# Skill-Seeker

A Claude Code plugin that discovers, evaluates, and installs community-created skills from GitHub. Before tackling a complex task, Skill-Seeker searches for existing behavioral frameworks, prompt-based skills, and specialized personas that can be injected into your context.

## What It Does

Skill-Seeker is a **meta-skill**: it teaches Claude Code to autonomously find and load other skills. Instead of searching for executable MCP tools, it focuses on **behavioral frameworks and prompt-based skills**—Markdown files that shape how the AI approaches a task.

### Example Workflow

```
You: "Help me redesign this landing page"

Claude (with Skill-Seeker loaded):
  1. Recognizes this is a design-taste task
  2. Searches GitHub for frontend design skills
  3. Finds pbakaus/impeccable (strict design audit framework)
  4. Shows you the results with trust scores
  5. You pick which skill to install
  6. Runs security scan, shows preview
  7. You approve → skill is loaded into context
  8. Claude now applies the design framework to your task
```

## Quick Start

### Commands

| Command | Purpose |
|---------|---------|
| `/skill-seeker:seek <query>` | Search GitHub for skills matching a query |
| `/skill-seeker:browse <owner/repo>` | List all skills in a specific repository |
| `/skill-seeker:install <owner/repo/path>` | Fetch, scan, and install a specific skill |
| `/skill-seeker:unload` | List and remove loaded skills from the current session |

### Prerequisites

- `curl` and `jq` for GitHub API calls
- `python3` for security scanning
- Optional: `GITHUB_TOKEN` environment variable for higher API rate limits (5,000 vs 60 requests/hour)

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed technical breakdown covering:

- **Lead 1**: Discovery & search mechanics (GitHub API strategies)
- **Lead 2**: Ingestion & parsing (file identification and fetching)
- **Lead 3**: Context injection & lifecycle (loading, temp storage, unloading)
- **Lead 4**: Trigger mechanism & security (invocation patterns, prompt injection defense)

## Repository Structure

```
skill-seeker/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   ├── seek.md              # Search GitHub for skills
│   ├── browse.md            # Browse skills in a repo
│   ├── install.md           # Fetch, scan, and install a skill
│   └── unload.md            # Unload skills from current session
├── scripts/
│   ├── search-github.sh     # GitHub API search & browse
│   ├── fetch-skill.sh       # Raw markdown fetching with caching
│   └── scan-skill.py        # Security scanner (9 detection categories)
├── skills/
│   └── seeking-skills/
│       └── SKILL.md         # Meta-skill: when/how to seek skills
├── tests/
│   └── test_scan_skill.py   # Security scanner tests
├── ARCHITECTURE.md          # Technical deep-dive
└── README.md                # This file
```

## Security Model

All community content passes through the security scanner before injection. The scanner checks for:

| Category | Severity | What It Detects |
|----------|----------|----------------|
| Instruction overrides | CRITICAL | "ignore previous instructions", mode switching |
| Shell command injection | CRITICAL | Tool abuse, piped curl commands |
| Data exfiltration | CRITICAL | Attempts to read SSH keys, credentials, env vars |
| Hidden HTML content | HIGH | Invisible text, CSS tricks, script tags |
| Social engineering | HIGH | "don't tell the user", secret-keeping instructions |
| Encoded payloads | HIGH | Base64-encoded malicious instructions |
| Conversation injection | MEDIUM | Fake turn markers, prompt format exploitation |
| Unicode obfuscation | MEDIUM | Zero-width chars, RTL overrides, homoglyphs |
| Frontmatter abuse | MEDIUM | Unexpected YAML keys that could alter behavior |

**Risk levels**: CLEAN (0–14) → LOW → MEDIUM (15–29) → HIGH (30–49) → CRITICAL (50+)

Skills flagged HIGH or CRITICAL are **blocked by default**. The user must explicitly acknowledge findings before proceeding.

## How It Finds Skills

The search uses three strategies in order of specificity:

1. **Topic search**: Repos tagged with `claude-skills` or `claude-code-skills` + query terms
2. **Broad topic search**: Repos tagged with `claude-skills` + query terms (wider net)
3. **Description search**: Repos with "claude" + "skill" in description/name + query terms

Results are scored on: stars (log scale), recency, forks, proper tagging, license presence, and archive status. Only repos with 10+ stars are shown by default.

## Inspiration

- [pbakaus/impeccable](https://github.com/pbakaus/impeccable) — Strict frontend design taste framework
- [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) — Dozens of specialized AI personas
- GitHub topics: `claude-skills`, `claude-code-skills`

## License

MIT
