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

### Planned
- Multi-source search (GitLab, GitHub Code Search)
- Local caching and offline mode
- Semantic search with embeddings
- Community growth tools and analytics
- Skill usage tracking and recommendations
- Integration with popular Claude Code workflows
