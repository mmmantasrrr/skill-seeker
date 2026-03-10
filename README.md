<div align="center">

# 🔍 Skill-Seeker

**Discover and Install Community AI Skills for Claude Code**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/mmmantasrrr/skill-seeker?style=social)](https://github.com/mmmantasrrr/skill-seeker/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/mmmantasrrr/skill-seeker)](https://github.com/mmmantasrrr/skill-seeker/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING-REGISTRY.md)

*Transform Claude Code with behavioral frameworks, prompt-based skills, and specialized AI personas*

[Quick Start](#quick-start) • [Features](#features) • [Documentation](#architecture) • [Contributing](#contributing) • [Security](#security-model)

</div>

---

A Claude Code plugin that discovers, evaluates, and installs community-created skills from GitHub. Before tackling a complex task, Skill-Seeker searches for existing behavioral frameworks, prompt-based skills, and specialized personas that can be injected into your context.

> ⭐ **Like this project?** Give us a star on GitHub to help others discover Skill-Seeker!

## 🎯 What It Does

Skill-Seeker is a **meta-skill**: it teaches Claude Code to autonomously find and load other skills. Instead of searching for executable MCP tools, it focuses on **behavioral frameworks and prompt-based skills**—Markdown files that shape how the AI approaches a task.

## ✨ Features

- 🔍 **Smart Discovery**: Hybrid search combining curated registry + live GitHub API search
- 🛡️ **Security First**: Comprehensive security scanner with 9 detection categories
- ⚡ **Instant Results**: Curated registry provides zero-latency search for popular skills
- 🎯 **Quality Scoring**: Trust scores based on stars, activity, and community validation
- 📦 **Easy Installation**: One-command skill installation with automatic caching
- 🔄 **Session Management**: Load and unload skills dynamically
- 🌐 **Community-Driven**: Submit your own skills to the curated registry
- 🏷️ **Smart Tagging**: Query expansion with synonyms for better discoverability

## 💡 Use Cases

- **Frontend Development**: Load design audit frameworks for UI/UX improvements
- **Security Audits**: Apply OWASP security checklists to code reviews
- **Testing**: Integrate Playwright best practices for browser automation
- **DevOps**: Apply Terraform patterns and Docker optimization guides
- **Code Quality**: Load language-specific idioms and best practices
- **API Design**: Apply REST API design patterns and conventions

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

## 📚 Quick Start

### Installation

1. Clone or download this repository to your Claude Code plugins directory
2. Ensure you have the required dependencies: `curl`, `jq`, and `python3`
3. (Optional) Set `GITHUB_TOKEN` environment variable for higher API rate limits

### Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/skill-seeker:seek <query>` | Search GitHub for skills matching a query | `/skill-seeker:seek frontend design` |
| `/skill-seeker:browse <owner/repo>` | List all skills in a specific repository | `/skill-seeker:browse pbakaus/impeccable` |
| `/skill-seeker:install <owner/repo/path>` | Fetch, scan, and install a specific skill | `/skill-seeker:install pbakaus/impeccable/.claude/skills/impeccable/SKILL.md` |
| `/skill-seeker:unload` | List and remove loaded skills from the current session | `/skill-seeker:unload` |

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

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- **Add Skills to Registry**: Submit high-quality skills via PR (see [CONTRIBUTING-REGISTRY.md](CONTRIBUTING-REGISTRY.md))
- **Report Bugs**: Open an issue using our bug report template
- **Suggest Features**: Share your ideas through feature request issues
- **Improve Documentation**: Help make our docs better
- **Share Your Experience**: Star the repo and tell others about Skill-Seeker

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## 🔐 Security Model

All community content passes through the security scanner before injection. See [SECURITY.md](SECURITY.md) for details.

The scanner checks for:

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

**Risk levels**: CLEAN (0) → LOW (1–14) → MEDIUM (15–29) → HIGH (30–49) → CRITICAL (50+)

Skills flagged HIGH or CRITICAL are **blocked by default**. The user must explicitly acknowledge findings before proceeding.

## How It Finds Skills

The search uses a hybrid approach combining curated registry + live GitHub search:

### Strategy 0: Curated Registry (NEW)
- **Instant search** of verified, high-quality skills
- **Rich metadata** with tags, aliases, and synonyms
- **Query expansion**: "frontend" automatically searches "ui", "web-design", etc.
- **No rate limits**: Always available, no API calls needed
- **Community-curated**: Submit your skills via PR (see [CONTRIBUTING-REGISTRY.md](CONTRIBUTING-REGISTRY.md))

### Strategies 1-3: Live GitHub API Search
1. **Topic search**: Repos tagged with `claude-skills` or `claude-code-skills` + query terms
2. **Broad topic search**: Repos tagged with `claude-skills` + query terms (wider net)
3. **Description search**: Repos with "claude" + "skill" in description/name + query terms

Results are scored on: stars (log scale), recency, forks, proper tagging, license presence, and archive status. Only repos with 10+ stars are shown by default.

**Why the registry?** Ensures you never encounter "skill not found" for popular use cases. The registry guarantees that well-known skills (Playwright testing, Terraform patterns, security checklists, etc.) are always discoverable, even if they're not properly tagged on GitHub.

## 📖 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical deep-dive into system design
- [CONTRIBUTING-REGISTRY.md](CONTRIBUTING-REGISTRY.md) - How to add skills to the registry
- [RESEARCH-SKILL-DISCOVERY.md](RESEARCH-SKILL-DISCOVERY.md) - Research and expansion roadmap
- [SECURITY.md](SECURITY.md) - Security policy and vulnerability reporting
- [CHANGELOG.md](CHANGELOG.md) - Version history and updates
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - Community guidelines

## 🌟 Showcase

Want to see your skill featured here? Submit it to our registry!

**Featured Skills:**
- [Impeccable Design Audit](https://github.com/pbakaus/impeccable) - Strict frontend design framework
- [Agency Agents](https://github.com/msitarzewski/agency-agents) - Specialized AI personas

## 🎯 Roadmap

- [x] Curated registry with verified skills
- [x] Hybrid search (registry + GitHub API)
- [x] Security scanning with 9 detection categories
- [ ] Multi-source search (GitLab, Bitbucket)
- [ ] Local caching and offline mode
- [ ] Semantic search with embeddings
- [ ] Usage analytics and recommendations
- [ ] Browser-based skill marketplace

## 💬 Community & Support

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/mmmantasrrr/skill-seeker/issues)
- **Discussions**: Join conversations about skills and best practices
- **Pull Requests**: Contribute code or skills following our guidelines

## 📊 Comparison

| Feature | Skill-Seeker | Manual Search | MCP Tools |
|---------|--------------|---------------|-----------|
| Discovery | Automated with trust scores | Manual GitHub browsing | Requires knowledge of tool names |
| Security | Built-in scanner | User responsibility | Varies by tool |
| Type | Behavioral frameworks | N/A | Executable tools |
| Installation | One command | Manual copy-paste | Installation required |
| Session Management | Dynamic load/unload | N/A | Always available |

## 🙏 Inspiration

- [pbakaus/impeccable](https://github.com/pbakaus/impeccable) — Strict frontend design taste framework
- [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) — Dozens of specialized AI personas
- GitHub topics: `claude-skills`, `claude-code-skills`

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ for the Claude Code community**

[![Star History](https://img.shields.io/github/stars/mmmantasrrr/skill-seeker?style=social)](https://github.com/mmmantasrrr/skill-seeker/stargazers)

*If you find Skill-Seeker useful, please consider starring the repository to help others discover it!*

</div>
