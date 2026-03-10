# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-10

### Added
- Initial release of Skill-Seeker
- Curated registry system with verified skills
- Four main commands: `/skill-seeker:seek`, `/skill-seeker:browse`, `/skill-seeker:install`, `/skill-seeker:unload`
- Hybrid search strategy combining registry and live GitHub API search
- Security scanner with 9 detection categories
- Trust scoring system for repository quality assessment
- Query synonym expansion for better discoverability
- Caching system for fetched skills
- Comprehensive documentation (ARCHITECTURE.md, CONTRIBUTING-REGISTRY.md, RESEARCH-SKILL-DISCOVERY.md)
- Test suite for security scanner
- Support for GITHUB_TOKEN for higher API rate limits

### Security
- Implemented comprehensive security scanning before skill installation
- Protection against instruction overrides, command injection, and data exfiltration
- Detection of hidden HTML content, social engineering, and encoded payloads
- Risk-based blocking for HIGH and CRITICAL findings

## [Unreleased]

### Planned (v2.1 — Quality of Life)
- Skill update notifications when reloading cached skills with newer upstream versions
- Profile inheritance for `.skill-seeker-profile.json` (extend a base/org-level profile)
- Multi-skill batch install from browse results (e.g., `install 2,4,6`)
- Improved error messages for rate-limited or blocked GitHub API

### Planned (v2.2 — Multi-Source Discovery)
- GitLab skill search integration
- GitHub Code Search API for content-based discovery
- Local skill directory search for private/team skills

### Planned (v2.3 — Ecosystem Health)
- Custom security scan rules via `.skill-seeker-scan-rules.json`
- Skill dependency declarations
- Registry auto-update staleness detection
- Expanded registry target: 30+ verified skills

### Planned (v3.0 — Semantic Discovery)
- Embedding-based semantic search
- Intent classification for proactive skill suggestions
- Opt-in anonymous usage analytics for registry curation

### Planned (v3.1 — Community Platform)
- Browser-based skill marketplace
- Skill ratings and reviews (GitHub Discussions integration)
- Trending skills feed

See [ROADMAP.md](ROADMAP.md) for full details and rationale.
