# Contributing Skills to the Registry

This guide explains how to add skills to the curated skill registry, expanding the collection of discoverable skills for all users.

## Why Contribute?

The curated registry solves the "skill not found" problem by providing:
- **Guaranteed discoverability**: Skills in the registry are always found, even if GitHub search misses them
- **Rich metadata**: Tags, aliases, and synonyms ensure skills match various search terms
- **Quality verification**: Registry entries undergo review and security scanning
- **Fast search**: No API rate limits, instant results

## How to Contribute

### Option 1: Add Your Own Skill (Quick)

If you have a Claude Code skill in a GitHub repository:

1. Fork this repository
2. Edit `registry.json`
3. Add your skill entry (see template below)
4. Submit a pull request
5. Maintainers will review and verify your skill

### Option 2: Nominate an Existing Skill

Found an excellent skill that should be in the registry?

1. Open an issue with the skill's GitHub URL
2. Explain why it's valuable
3. Maintainers will evaluate and add if appropriate

## Skill Entry Template

```json
{
  "id": "owner-repo-skillname-v1",
  "name": "Human-Readable Skill Name",
  "description": "Clear, concise description of what the skill does and when to use it",
  "source": "github",
  "repo": "owner/repo",
  "path": "path/to/SKILL.md",
  "tags": ["primary-tag", "secondary-tag", "domain-tag"],
  "aliases": ["alternative-names", "common-search-terms"],
  "verified": false,
  "trust_score": 0,
  "stars": 0,
  "last_verified": "YYYY-MM-DD",
  "domains": ["relevant-domain"],
  "note": ""
}
```

### Field Descriptions

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `id` | Yes | Unique identifier: `owner-repo-skillname-v1` | `pbakaus-impeccable-v1` |
| `name` | Yes | Clear, descriptive name | `Impeccable Design Audit` |
| `description` | Yes | What it does, when to use it (max 200 chars) | `Strict frontend design framework...` |
| `source` | Yes | Always `"github"` for now | `github` |
| `repo` | Yes | GitHub repository `owner/name` | `pbakaus/impeccable` |
| `path` | Yes | Path to skill file in the repo | `.claude/skills/impeccable/SKILL.md` |
| `tags` | Yes | Search keywords (5-10 recommended) | `["design", "frontend", "ui", "audit"]` |
| `aliases` | Yes | Alternative names/search terms | `["design-review", "ui-audit"]` |
| `verified` | No | Set to `false`, maintainers will verify | `false` |
| `trust_score` | No | Set to `0`, calculated during review | `0` |
| `stars` | No | Set to `0`, updated during review | `0` |
| `last_verified` | Yes | Today's date in YYYY-MM-DD format | `2026-03-10` |
| `domains` | Yes | Primary domain(s) from list below | `["web-development", "design-systems"]` |
| `note` | No | Any special notes or caveats | Leave empty `""` |

### Available Domains

Choose from these standard domains:
- `web-development` - Frontend and full-stack web development
- `testing` - Software testing and quality assurance
- `devops` - DevOps, CI/CD, and infrastructure automation
- `security` - Security and secure coding practices
- `cloud` - Cloud infrastructure and services
- `backend` - Backend development and API design
- `frontend` - Frontend development and UI frameworks
- `general` - General programming and collaboration practices
- `design-systems` - Design systems and UI/UX patterns
- `api-development` - API design and development
- `data-science` - Data analysis and machine learning
- `mobile` - Mobile app development
- `collaboration` - Team collaboration and workflows

### Choosing Good Tags and Aliases

**Tags**: Keywords that describe the skill's domain and purpose
- Use lowercase, hyphen-separated
- Include technology names: `playwright`, `terraform`, `react`
- Include patterns: `testing`, `security`, `design`
- Include use cases: `code-review`, `audit`, `refactoring`

**Aliases**: How users might search for this skill
- Think about synonyms: "ui-audit" = "design-review"
- Include abbreviations: "iac" for "infrastructure-as-code"
- Consider common misspellings or variations
- Add related concepts: "browser-automation" for playwright

**Example:**
```json
{
  "name": "Playwright Testing Best Practices",
  "tags": ["playwright", "testing", "e2e", "browser-automation", "qa"],
  "aliases": ["browser-testing", "e2e-testing", "web-testing", "automation"]
}
```

A user searching for any of these terms will find this skill:
- "playwright" (tag)
- "browser automation" (tag)
- "e2e testing" (alias)
- "web testing" (alias)
- "qa" (tag)

## Quality Guidelines

To ensure registry quality, follow these guidelines:

### Skill Quality Requirements

✅ **Must have:**
- Clear, actionable instructions
- Practical examples or patterns
- Appropriate scope (not too broad or narrow)
- Proper markdown formatting
- No security risks (must pass scanner)

❌ **Avoid:**
- Overly long persona descriptions (>3000 tokens)
- Vague or generic advice
- Content that duplicates existing skills
- Skills with high security risk scores
- Abandoned/unmaintained repositories

### Repository Requirements

- **Public GitHub repository**
- **Active maintenance**: Updated within last 12 months
- **Proper licensing**: MIT, Apache, CC-BY recommended
- **Basic documentation**: README explaining the skill
- **Minimum quality bar**: 10+ stars or verified by known creator

## Verification Process

When you submit a skill, maintainers will:

1. **Security scan**: Run the security scanner (9-category check)
2. **Quality review**: Ensure it meets guidelines above
3. **Metadata verification**: Check stars, update date, licensing
4. **Trust score calculation**: Based on stars, recency, forks, etc.
5. **Verification badge**: Mark as `"verified": true` if approved

## Adding Synonyms

Help improve search by adding synonyms to `query_synonyms`:

```json
"query_synonyms": {
  "playwright": ["browser-automation", "web-testing", "e2e"],
  "react": ["reactjs", "react-native"],
  "your-term": ["synonym1", "synonym2", "synonym3"]
}
```

Guidelines:
- Add commonly used alternative terms
- Include abbreviations (k8s → kubernetes)
- Technology-specific nicknames
- Keep it to 3-5 synonyms per term

## Example PR

```
Title: Add Playwright Testing Skill to Registry

Body:
This PR adds the "Playwright Testing Best Practices" skill from example/playwright-skills.

**Skill Details:**
- Repository: example/playwright-skills
- Path: skills/testing/SKILL.md
- Stars: 45
- Last updated: 2026-02-15
- License: MIT

**Why add this skill?**
Comprehensive guide covering common Playwright patterns, page object models, and CI integration. Actively maintained with good examples.

**Security scan results:** CLEAN (score: 0)

**Checklist:**
- [x] Followed skill entry template
- [x] Added appropriate tags and aliases
- [x] Verified repository is public and licensed
- [x] Ran security scanner (clean)
- [x] Checked for duplicates in registry
```

## Questions?

Open an issue with the label `registry-question` if you need help contributing a skill.

## Maintaining the Registry

For maintainers:

### Review Checklist
- [ ] Run security scanner on skill file
- [ ] Verify repository exists and is public
- [ ] Check stars, update date, license
- [ ] Calculate trust score
- [ ] Test search with various queries
- [ ] Ensure no duplicates
- [ ] Mark as verified if quality meets bar

### Trust Score Calculation

```python
score = 0
score += min(40, int(math.log2(max(1, stars)) * 4))  # Stars (log scale)
score += max(0, 20 - (days_since_update // 15))       # Recency
score += min(15, int(math.log2(max(1, forks)) * 2))   # Forks
score += 5 if 'claude-skills' in topics else 0        # Tagged
score += 5 if not archived else 0                      # Active
score += 5 if description else 0                       # Documented
score += 5 if license else 0                           # Licensed
```

### Refresh Workflow
1. Quarterly: Re-scan all verified skills
2. Update stars, update dates, trust scores
3. Remove archived or deleted repositories
4. Add new skills from community submissions

## License

By contributing to the registry, you agree that your metadata contribution (tags, description, etc.) is licensed under MIT. The skill content itself retains its original license from the source repository.
