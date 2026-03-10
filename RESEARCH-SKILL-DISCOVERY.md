# Research: Expanding Skill Discovery Collection

## Problem Statement

How can skill-seeker maintain a wide and rich collection of skills to query, ensuring that users never encounter a situation where a skill they have in mind doesn't even show up in search results?

## Current State Analysis

### Existing Search Implementation

The current search uses three GitHub API strategies:

1. **Topic search (precise)**: `topic:claude-skills+topic:claude-code-skills+{query}`
2. **Topic search (broad)**: `topic:claude-skills+{query}`
3. **Description/name search**: `{query}+claude+skill+in:description,name`

### Current Limitations

#### 1. **GitHub-Only Dependency**
- **Problem**: Skills are only discoverable if they're on GitHub and properly tagged
- **Impact**: Misses skills on GitLab, Bitbucket, personal websites, Gists, or repositories without proper tagging
- **Example**: A developer creates "terraform-best-practices.md" in their repo but doesn't tag it with `claude-skills`

#### 2. **Tag Dependency**
- **Problem**: Strategy 1 and 2 rely on repositories having the right topics
- **Impact**: Many excellent skill files exist in repos that don't know about the `claude-skills` ecosystem
- **Example**: The `pbakaus/impeccable` example in README might not have been tagged when first created

#### 3. **Search Query Precision**
- **Problem**: Users must guess the right keywords to find relevant skills
- **Impact**: Different terminology (e.g., "frontend" vs "UI" vs "web design") may yield different results
- **Example**: User searches "playwright" but skill is tagged with "browser testing" or "e2e testing"

#### 4. **Limited Pattern Matching**
- **Problem**: File detection only looks for `SKILL.md` patterns or generic `.md` files
- **Impact**: Misses skills with different naming conventions or embedded in other file types
- **Example**: `docs/claude-prompts/design-reviewer.md` or `ai-skills/frontend.txt`

#### 5. **Static vs Dynamic Collection**
- **Problem**: No curated index or catalog of known-good skills
- **Impact**: Every search relies on real-time GitHub API results, which may fluctuate
- **Example**: A highly relevant skill in a low-star repo might never surface

#### 6. **Content-Based Discovery**
- **Problem**: Current search relies on metadata (topics, description, repo name)
- **Impact**: Can't find skills based on actual content or semantic similarity
- **Example**: User searches "error handling patterns" but skills describe themselves as "resilient code practices"

## Research: Potential Solutions

### Strategy 1: Multi-Source Federation

Expand beyond GitHub to aggregate skills from multiple sources:

#### Primary Sources
1. **GitHub** (current) - Keep existing implementation
2. **GitLab** - Use GitLab API with similar topic/description search
3. **Sourcegraph/GitHub Code Search** - Search actual file contents across all repos
4. **Curated Registry** - Maintain a JSON index of known-good skills

#### Secondary Sources
5. **Gists** - Search public gists with skill-like patterns
6. **HuggingFace Datasets** - Explore prompt/skill datasets
7. **Reddit/Discord Archives** - Mine community-shared skills (with explicit permission/licensing)

#### Implementation Approach
```bash
# Parallel search across sources
search_github()     # Existing implementation
search_gitlab()     # Similar API pattern
search_registry()   # Local JSON index
search_gists()      # GitHub Gists API
```

**Pros:**
- Dramatically increases skill coverage
- Reduces single-source dependency
- Can find skills in unconventional locations

**Cons:**
- More API rate limits to manage
- Increased complexity in result deduplication
- Different security postures across platforms

### Strategy 2: Semantic Search with Embeddings

Move from keyword matching to semantic similarity:

#### Architecture
1. **Index Building Phase**
   - Crawl known skill repositories
   - Generate embeddings for each skill file (using Claude API or local model)
   - Store in vector database (SQLite with vector extension, or Pinecone/Weaviate)

2. **Search Phase**
   - Generate embedding for user query
   - Find semantically similar skills via vector similarity
   - Rank by combination of semantic score + trust score

#### Example Queries That Would Improve
- "help me write better commit messages" → finds "git workflow discipline" skill
- "make my code more testable" → finds "dependency injection patterns" skill
- "avoid security vulnerabilities" → finds "OWASP checklist" skill

**Pros:**
- Solves terminology mismatch problem
- Can find conceptually related skills
- Better handles natural language queries

**Cons:**
- Requires building and maintaining an index
- Adds latency and complexity
- Embeddings need periodic refresh

### Strategy 3: Curated Registry with Community Submissions

Create an official skill registry that can be queried alongside GitHub:

#### Registry Structure
```json
{
  "skills": [
    {
      "id": "pbakaus-impeccable-design-v1",
      "name": "Impeccable Design Audit",
      "description": "Strict frontend design taste framework",
      "source": "github:pbakaus/impeccable",
      "path": ".claude/skills/impeccable/SKILL.md",
      "tags": ["design", "frontend", "UI", "audit", "code-review"],
      "aliases": ["design-review", "ui-audit", "frontend-taste"],
      "verified": true,
      "trust_score": 85,
      "last_verified": "2026-03-01"
    }
  ]
}
```

#### Registry Features
- **Rich tagging**: Multiple tags and aliases per skill
- **Verified status**: Community-vetted skills marked as trusted
- **Popularity tracking**: Usage statistics from skill-seeker instances
- **Dependency mapping**: Skills that work well together
- **Version tracking**: Changes to skills over time

#### Registry Maintenance
- **Submission PR workflow**: Contributors submit skills via GitHub PR
- **Automated verification**: CI runs security scanner + quality checks
- **Community voting**: GitHub reactions for skill quality
- **Periodic re-scanning**: Refresh trust scores monthly

**Pros:**
- Guarantees comprehensive coverage of known skills
- Enables richer metadata and discoverability
- Can include synonym/alias mapping
- Community-driven quality control

**Cons:**
- Requires ongoing curation effort
- Registry can become stale
- Centralization concerns
- Need clear governance model

### Strategy 4: Smart Query Expansion

Improve search quality by automatically expanding/augmenting queries:

#### Techniques
1. **Synonym Expansion**
   - "frontend" → also search ["ui", "web-design", "client-side", "browser"]
   - "testing" → also search ["qa", "test-automation", "validation"]

2. **Related Domain Mapping**
   - "react" → also search ["javascript", "frontend", "component-library"]
   - "terraform" → also search ["infrastructure", "IaC", "cloud", "devops"]

3. **Common Misspellings**
   - "kubernetes" → also search ["k8s"]
   - "playwright" → also search ["browser-automation"]

4. **Hierarchical Search**
   - Start specific, broaden if few results
   - "playwright visual regression" → "playwright testing" → "browser testing"

#### Implementation
```python
DOMAIN_MAPPING = {
    "frontend": ["ui", "web-design", "client-side", "browser", "html", "css"],
    "testing": ["qa", "test-automation", "validation", "quality", "e2e"],
    "security": ["vulnerability", "owasp", "infosec", "pentest"],
    # ...
}

def expand_query(query):
    """Expand query with synonyms and related terms"""
    base_terms = query.split()
    expanded_terms = set(base_terms)

    for term in base_terms:
        if term in DOMAIN_MAPPING:
            expanded_terms.update(DOMAIN_MAPPING[term][:3])  # Add top 3 related terms

    return list(expanded_terms)
```

**Pros:**
- No infrastructure changes needed
- Immediate improvement in recall
- Can be tuned based on user feedback

**Cons:**
- May return less precise results
- Requires maintaining synonym lists
- Could slow down searches

### Strategy 5: Local Skill Cache + Background Indexing

Build a local searchable index of skills over time:

#### Architecture
1. **Background Indexer**
   - Periodically crawls GitHub for new skills (daily/weekly)
   - Builds local SQLite database with full-text search
   - Stores: repo metadata, file paths, file content, embeddings

2. **Hybrid Search**
   - Check local index first (instant results)
   - Fall back to live GitHub API search
   - Merge and deduplicate results

3. **Index Updates**
   - Auto-refresh on skill installation
   - User can manually trigger index rebuild
   - Track cache freshness and warn if stale

#### Database Schema
```sql
CREATE TABLE skills (
    id TEXT PRIMARY KEY,
    repo TEXT,
    path TEXT,
    name TEXT,
    content TEXT,
    tags TEXT,
    stars INTEGER,
    updated_at TEXT,
    trust_score INTEGER,
    indexed_at TEXT
);

CREATE VIRTUAL TABLE skills_fts USING fts5(
    name, content, tags,
    content='skills',
    content_rowid='rowid'
);
```

**Pros:**
- Fast searches with no API rate limits
- Works offline
- Can do sophisticated ranking

**Cons:**
- Requires storage space
- Index can become stale
- More moving parts to maintain

### Strategy 6: Fuzzy Filename Matching

Expand file detection to catch more skill variations:

#### Current Pattern
```bash
# Only matches:
.claude/skills/*/SKILL.md
**/skills/*/SKILL.md
*.md (with size/location filters)
```

#### Enhanced Patterns
```bash
# Also match:
**/*skill*.md
**/*prompt*.md
**/*claude*.md
**/*agent*.md
**/*persona*.md
.claude/**/*.md
docs/ai/**/*.md
prompts/**/*.md
agents/**/*.md
```

#### Content-Based Detection
Instead of just filename patterns, scan file content for skill-like markers:
- YAML frontmatter with `name:` and `description:`
- Markdown headers like "## Instructions", "## Behavior", "## Persona"
- Phrases like "You are a...", "When the user asks...", "Your role is..."

**Pros:**
- Catches skills with non-standard naming
- No external dependencies
- Easy to implement

**Cons:**
- More false positives
- Slower file tree scanning
- May find non-skill markdown files

## Recommended Architecture: Hybrid Multi-Layer Approach

### Layer 1: Fast Local Cache (Primary)
- **Curated Registry** (JSON file, versioned with plugin)
- **Local Index** (SQLite with FTS, built from known repos)
- **Query Expansion** (synonym mapping)

### Layer 2: Live API Search (Secondary)
- **GitHub API** (existing implementation)
- **GitLab API** (new)
- **GitHub Code Search** (new, for content-based discovery)

### Layer 3: Community Growth (Long-term)
- **Submission Workflow** (PRs to add skills to registry)
- **Usage Analytics** (track which skills are most used)
- **Automated Discovery** (bot that finds and proposes new skills)

### Search Flow
```
User Query: "playwright testing"
    ↓
1. Query Expansion: ["playwright", "browser-testing", "e2e", "automation"]
    ↓
2. Local Registry Search (instant)
    ├─ Check curated registry
    ├─ Check local cache (if exists)
    └─ Return top 5 results
    ↓
3. Live API Search (parallel)
    ├─ GitHub (existing 3 strategies)
    ├─ GitLab (if available)
    └─ GitHub Code Search (content-based)
    ↓
4. Merge & Deduplicate
    ├─ Combine results from all sources
    ├─ Remove duplicates by repo+path
    ├─ Score by: trust + relevance + freshness
    └─ Return top 15 results
    ↓
5. Present to User
```

## Implementation Phases

### Phase 1: Quick Wins (1-2 days)
- [ ] Add query expansion with domain synonyms
- [ ] Enhance file pattern matching
- [ ] Create initial curated registry (10-20 known skills)
- [ ] Implement registry search as Strategy 0

### Phase 2: Multi-Source (1 week)
- [ ] Add GitLab API support
- [ ] Add GitHub Code Search API
- [ ] Implement result deduplication
- [ ] Add source attribution in results

### Phase 3: Local Indexing (2 weeks)
- [ ] Build SQLite-based skill cache
- [ ] Create background indexer
- [ ] Implement hybrid search (cache + API)
- [ ] Add index refresh commands

### Phase 4: Semantic Search (3-4 weeks)
- [ ] Generate embeddings for cached skills
- [ ] Implement vector similarity search
- [ ] A/B test semantic vs keyword results
- [ ] Tune ranking algorithm

### Phase 5: Community Growth (Ongoing)
- [ ] Create skill submission template
- [ ] Build automated verification CI
- [ ] Add usage analytics
- [ ] Create discovery bot

## Metrics for Success

How do we know if these changes work?

### Coverage Metrics
- **Skill Count**: Number of unique skills discoverable
- **Source Diversity**: % of skills from non-GitHub sources
- **Query Hit Rate**: % of searches that return >5 results

### Quality Metrics
- **Search Precision**: % of results actually relevant to query
- **Search Recall**: % of known relevant skills that appear in results
- **Zero-Results Rate**: % of queries that return no results (target: <5%)

### User Satisfaction Metrics
- **Installation Rate**: % of searches that lead to skill installation
- **Return Rate**: % of installed skills that get re-used
- **Query Refinement**: Avg. number of searches before finding desired skill

## Security Implications

### New Attack Surfaces
1. **Registry Poisoning**: Malicious PRs to curated registry
   - **Mitigation**: Manual review + automated scanning + require 2 approvals

2. **Index Injection**: Poisoned local cache
   - **Mitigation**: Sign registry with GPG, verify on download

3. **API Credential Leakage**: Additional API tokens (GitLab, etc.)
   - **Mitigation**: Same pattern as GITHUB_TOKEN, environment variables only

4. **Content-Based Discovery**: Searching file content may expose private code
   - **Mitigation**: Only search public repositories, respect .gitignore patterns

### Updated Security Scanner Requirements
- [ ] Scan registry submissions with same 9-category rules
- [ ] Verify skill content hasn't changed since verification
- [ ] Check for repository takeovers (original author still owns repo)
- [ ] Rate-limit registry updates to prevent flooding

## Open Questions

1. **Registry Governance**: Who maintains the curated registry? Single maintainer vs committee?

2. **Skill Versioning**: How do we handle skills that change over time? Pin to specific commits?

3. **Offline Mode**: Should skill-seeker work without internet access using only local cache?

4. **Commercial Skills**: Do we allow paid/premium skills in the registry? How to handle?

5. **Skill Dependencies**: Can skills reference other skills? How to resolve dependencies?

6. **Privacy**: Do we collect anonymous usage statistics to improve recommendations?

## Conclusion

To ensure users never encounter "skill not found" situations, we should:

1. **Short-term**: Implement query expansion + curated registry (Phase 1)
2. **Medium-term**: Add multi-source search + local caching (Phases 2-3)
3. **Long-term**: Build semantic search + community growth tools (Phases 4-5)

The curated registry is the highest-value, lowest-effort improvement. Starting with 20-30 known excellent skills and growing through community submissions will immediately solve the "can't find obvious skills" problem.

**Next Steps**:
1. Create initial `registry.json` with 20 well-known skills
2. Update `search-github.sh` to check registry first
3. Add synonym expansion to search queries
4. Document contribution workflow for adding skills to registry
