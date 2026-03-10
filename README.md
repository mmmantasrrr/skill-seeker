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

Think of it as **npm for AI prompts** or a **package manager for Claude Code behavioral frameworks**. Instead of manually searching GitHub for best practices, design patterns, or coding standards, Skill-Seeker automates discovery, validates quality, scans for security issues, and installs skills with a single command.

**Perfect for developers who want Claude to:**
- Apply React hooks best practices
- Follow REST API design patterns
- Conduct security audits with OWASP guidelines
- Write Playwright browser tests correctly
- Use Terraform infrastructure patterns
- Apply clean code principles
- Follow specific framework conventions

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

Skill-Seeker helps developers solve these common challenges:

### Frontend Development
- **React component patterns** - Learn hooks, composition, and state management
- **CSS architecture** - BEM, CSS-in-JS, Tailwind patterns
- **UI/UX design audit** - Apply professional design principles
- **Responsive design** - Mobile-first, breakpoints, fluid layouts
- **Web accessibility** - WCAG compliance, ARIA attributes, screen readers
- **Performance optimization** - Bundle size, lazy loading, code splitting

### Backend Development
- **REST API design** - Endpoint naming, HTTP methods, status codes
- **GraphQL schema patterns** - Type design, resolvers, N+1 prevention
- **Database design** - Schema normalization, indexing, query optimization
- **Microservices architecture** - Service boundaries, communication patterns
- **Error handling** - Centralized handlers, logging, user messages
- **Authentication & authorization** - JWT, OAuth, RBAC, security best practices

### Testing & Quality Assurance
- **Playwright browser testing** - E2E tests, page objects, reliable selectors
- **Unit testing patterns** - Mocking, test isolation, assertion strategies
- **Integration testing** - API testing, database testing, test data management
- **Test-driven development** - Red-green-refactor, test-first approach
- **Code coverage** - Coverage goals, meaningful metrics

### DevOps & Infrastructure
- **Terraform infrastructure** - Module design, state management, best practices
- **Docker optimization** - Multi-stage builds, layer caching, image size reduction
- **Kubernetes deployment** - YAML manifests, helm charts, resource management
- **CI/CD pipelines** - GitHub Actions, build optimization, deployment strategies
- **Monitoring & logging** - Observability, alerting, debugging production issues

### Security
- **OWASP Top 10** - SQL injection, XSS, CSRF, security misconfiguration
- **Secure coding practices** - Input validation, output encoding, parameterized queries
- **Authentication security** - Password hashing, session management, token security
- **API security** - Rate limiting, API keys, OAuth flows
- **Dependency scanning** - Vulnerability detection, update strategies

### Code Quality
- **Clean code principles** - SOLID, DRY, KISS, naming conventions
- **Refactoring patterns** - Extract method, simplify conditionals, remove duplication
- **Code review checklist** - What to look for, constructive feedback
- **Documentation standards** - JSDoc, docstrings, README templates
- **Git workflow** - Commit messages, branching strategies, PR conventions

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed usage tips and common questions.

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

**One-line install (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/mmmantasrrr/skill-seeker/main/install.sh | bash
```

**Via npm:**
```bash
npm install -g skill-seeker
```

**Manual install:**
```bash
git clone https://github.com/mmmantasrrr/skill-seeker.git ~/.claude/plugins/skill-seeker
```

After installing, restart Claude Code to load the plugin.

> **Dependencies:** `curl`, `jq`, `python3`, and `git`. Set `GITHUB_TOKEN` for higher API rate limits (5,000 vs 60 requests/hour).

### Updating

Update from within Claude Code:
```
/skill-seeker:update
```

Or manually:
```bash
cd ~/.claude/plugins/skill-seeker && git pull
```

### New Features (v2.0)

**⚡ Reduced Context Overhead**: Pre-flight skill slimmed from ~961 to ~200 tokens (80% reduction)

**🔍 Combined Search**: Single script merges registry + GitHub results with automatic deduplication

**🚀 Registry Quick-Install**: Install verified skills by ID: `/skill-seeker:install metaskills-skill-builder`

**📊 Status Command**: See loaded skills and context budget at a glance

**💾 Cache Reload**: Instantly reload previously installed skills without re-fetching

**📁 Project Profiles**: Define project-specific skill preferences in `.skill-seeker-profile.json`

**🎯 Auto-Browse**: HIGH trust verified skills auto-browse to collapse seek+browse into one step

See [PROJECT-PROFILES.md](PROJECT-PROFILES.md) for detailed information on project profiles.

### Commands

| Command | Purpose |
|---------|---------|
| `/skill-seeker:seek <query>` | Search GitHub for skills matching a query |
| `/skill-seeker:browse <owner/repo>` | List all skills in a specific repository |
| `/skill-seeker:install <target>` | Fetch, scan, and install a skill (supports registry IDs) |
| `/skill-seeker:status` | Show loaded skills and context budget |
| `/skill-seeker:reload [target]` | Quickly reload a skill from cache |
| `/skill-seeker:update` | Check for and apply plugin updates |
| `/skill-seeker:unload` | Clean up temporary skill files |

### Prerequisites

- `curl`, `jq`, and `git` for GitHub API calls and installation
- `python3` for security scanning
- Optional: `GITHUB_TOKEN` environment variable for higher API rate limits (5,000 vs 60 requests/hour)

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed technical breakdown covering:

- **Lead 1**: Discovery & search mechanics (GitHub API strategies)
- **Lead 2**: Ingestion & parsing (file identification and fetching)
- **Lead 3**: Context injection & lifecycle (loading, temp storage, unloading)
- **Lead 4**: Trigger mechanism & security (invocation patterns, prompt injection defense)

## 🤝 Contributing

```
skill-seeker/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   ├── seek.md              # Search GitHub for skills
│   ├── browse.md            # Browse skills in a repo
│   ├── install.md           # Fetch, scan, and install a skill (supports registry IDs)
│   ├── status.md            # Show loaded skills and context budget
│   ├── reload.md            # Quickly reload skills from cache
│   ├── update.md            # Check for and apply plugin updates
│   └── unload.md            # Clean up temporary files
├── scripts/
│   ├── search-combined.sh   # Combined registry + GitHub search
│   ├── search-registry.sh   # Curated registry search
│   ├── search-github.sh     # GitHub API search & browse
│   ├── resolve-skill-id.sh  # Resolve registry IDs to repo/path
│   ├── fetch-skill.sh       # Raw markdown fetching with caching
│   └── scan-skill.py        # Security scanner (9 detection categories)
├── skills/
│   └── seeking-skills/
│       └── SKILL.md         # Meta-skill: when/how to seek skills
├── tests/
│   └── test_scan_skill.py   # Security scanner tests (34 tests)
├── registry.json            # Curated skill registry
├── .skill-seeker-profile.example.json  # Example project profile
├── ARCHITECTURE.md          # Technical deep-dive
├── PROJECT-PROFILES.md      # Project skill profiles guide
└── README.md                # This file
```

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
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Solutions to common problems and FAQ
- [PROJECT-PROFILES.md](PROJECT-PROFILES.md) - Project skill profiles guide
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
- [x] One-line install and in-plugin updates
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
