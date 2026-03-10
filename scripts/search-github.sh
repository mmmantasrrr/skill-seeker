#!/usr/bin/env bash
# search-github.sh - Search GitHub for Claude Code skill repositories
# Usage:
#   search-github.sh <query>           # Search by query
#   search-github.sh --browse <repo>   # Browse a specific repo's skills
#
# Requires: curl, jq
# Optional: GITHUB_TOKEN env var for higher rate limits (5000 vs 60 req/hr)

set -euo pipefail

gh_api() {
    local url="$1"
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3+json" \
             "$url"
    else
        curl -s -H "Accept: application/vnd.github.v3+json" "$url"
    fi
}

# ─── Browse mode: list skills in a specific repo ───────────────────────────────
if [[ "${1:-}" == "--browse" ]]; then
    REPO="${2:?Usage: search-github.sh --browse owner/repo}"

    # Get default branch
    REPO_INFO=$(call_github_api "https://api.github.com/repos/$REPO")
    DEFAULT_BRANCH=$(echo "$REPO_INFO" | jq -r '.default_branch // "main"')
    STARS=$(echo "$REPO_INFO" | jq -r '.stargazers_count // 0')
    REPO_DESCRIPTION=$(echo "$REPO_INFO" | jq -r '.description // "(no description)"')
    UPDATED=$(echo "$REPO_INFO" | jq -r '.pushed_at // "unknown"' | cut -c1-10)

    echo "{"
    echo "  \"repo\": \"$REPO\","
    echo "  \"description\": $(echo "$REPO_DESCRIPTION" | jq -Rs .),"
    echo "  \"stars\": $STARS,"
    echo "  \"updated\": \"$UPDATED\","
    echo "  \"branch\": \"$DEFAULT_BRANCH\","

    # Fetch file tree
    TREE=$(call_github_api "https://api.github.com/repos/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1")

    # Find skill files: SKILL.md files, or .md files with likely skill content
    echo "  \"skills\": ["

    FIRST=true

    # Pattern 1: .claude/skills/*/SKILL.md (official format)
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        SIZE=$(echo "$TREE" | jq -r ".tree[] | select(.path==\"$path\") | .size")
        SKILL_NAME=$(echo "$path" | sed -E 's|.*/([^/]+)/SKILL\.md$|\1|')
        TOKENS=$((SIZE / 4))

        if [[ "$FIRST" == "true" ]]; then FIRST=false; else echo ","; fi
        printf '    {"name": "%s", "path": "%s", "size": %s, "tokens": %s, "format": "claude-skill"}' \
            "$SKILL_NAME" "$path" "$SIZE" "$TOKENS"
    done < <(echo "$TREE" | jq -r '.tree[]? | select(.path | test("skills/[^/]+/SKILL\\.md$")) | .path' 2>/dev/null)

    # Pattern 2: Any .md files that look like skills (agency-agents style, or non-standard layouts)
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        # Skip if already found as SKILL.md
        echo "$path" | grep -q "SKILL.md" && continue
        # Skip common non-skill files
        SKILL_FILENAME=$(basename "$path")
        [[ "$SKILL_FILENAME" == "README.md" || "$SKILL_FILENAME" == "CHANGELOG.md" || "$SKILL_FILENAME" == "LICENSE.md" || "$SKILL_FILENAME" == "CONTRIBUTING.md" || "$SKILL_FILENAME" == "CODE_OF_CONDUCT.md" ]] && continue

        SIZE=$(echo "$TREE" | jq -r ".tree[] | select(.path==\"$path\") | .size")
        # Only include .md files that are likely skills (> 500 bytes)
        [[ "$SIZE" -lt 500 ]] && continue
        # Skip files in build/config directories
        SKILL_DIRECTORY=$(dirname "$path")
        [[ "$SKILL_DIRECTORY" == "scripts" || "$SKILL_DIRECTORY" == ".github" || "$SKILL_DIRECTORY" =~ ^\.github/ || "$SKILL_DIRECTORY" == "node_modules" || "$SKILL_DIRECTORY" == ".claude-plugin" ]] && continue

        SKILL_NAME=$(basename "$path" .md)
        TOKENS=$((SIZE / 4))

        if [[ "$FIRST" == "true" ]]; then FIRST=false; else echo ","; fi
        printf '    {"name": "%s", "path": "%s", "size": %s, "tokens": %s, "format": "markdown"}' \
            "$SKILL_NAME" "$path" "$SIZE" "$TOKENS"
    done < <(echo "$TREE" | jq -r '.tree[]? | select(.type=="blob") | select(.path | test("\\.md$")) | select(.path | test("^\\.|node_modules|__pycache__") | not) | .path' 2>/dev/null)

    echo ""
    echo "  ]"
    echo "}"
    exit 0
fi

# ─── Search mode: find repos matching a query ──────────────────────────────────
QUERY="${1:?Usage: search-github.sh <query>}"
MIN_STARS="${2:-10}"

# Search strategies (run the most targeted first)
# 1. Topic search for claude-skills + query terms
TOPIC_RESULTS=$(call_github_api "https://api.github.com/search/repositories?q=topic:claude-skills+topic:claude-code-skills+${QUERY// /+}&sort=stars&order=desc&per_page=10")

# 2. Topic search without query filtering (broader)
TOPIC_BROAD=$(call_github_api "https://api.github.com/search/repositories?q=topic:claude-skills+${QUERY// /+}&sort=stars&order=desc&per_page=10")

# 3. Description/name search
DESC_RESULTS=$(call_github_api "https://api.github.com/search/repositories?q=${QUERY// /+}+claude+skill+in:description,name&sort=stars&order=desc&per_page=10")

# Merge and deduplicate results, compute trust scores
export TOPIC_RESULTS TOPIC_BROAD DESC_RESULTS QUERY
python3 - "$MIN_STARS" <<'PYEOF'
import json
import os
import sys
from datetime import datetime, timezone

min_stars = int(sys.argv[1])

results = {}

for var_name in ['TOPIC_RESULTS', 'TOPIC_BROAD', 'DESC_RESULTS']:
    api_response_json = os.environ.get(var_name, '{}')
    try:
        api_response = json.loads(api_response_json)
        for item in api_response.get('items', []):
            full_name = item['full_name']
            if full_name not in results:
                results[full_name] = item
    except (json.JSONDecodeError, KeyError):
        pass

# Filter and score
scored_repositories = []
now = datetime.now(timezone.utc)

for name, repo in results.items():
    stars = repo.get('stargazers_count', 0)
    if stars < min_stars:
        continue

    # Trust score calculation
    score = 0

    # Stars (logarithmic scale, max 40 points)
    import math
    score += min(40, int(math.log2(max(1, stars)) * 4))

    # Recency (max 20 points, full points if updated within 30 days)
    updated = repo.get('pushed_at', '')
    if updated:
        try:
            updated_dt = datetime.fromisoformat(updated.replace('Z', '+00:00'))
            days_ago = (now - updated_dt).days
            score += max(0, 20 - (days_ago // 15))
        except ValueError:
            pass

    # Forks as social proof (max 15 points)
    forks = repo.get('forks_count', 0)
    score += min(15, int(math.log2(max(1, forks)) * 2))

    # Has topics (5 points for being properly tagged)
    topics = repo.get('topics', [])
    if any(t in topics for t in ['claude-skills', 'claude-code-skills']):
        score += 5

    # Not archived (5 points)
    if not repo.get('archived', False):
        score += 5

    # Has description (5 points)
    if repo.get('description'):
        score += 5

    # Has license (5 points)
    if repo.get('license'):
        score += 5

    trust = "LOW"
    if score >= 60:
        trust = "HIGH"
    elif score >= 40:
        trust = "MEDIUM"

    scored_repositories.append({
        'full_name': name,
        'description': (repo.get('description') or '(no description)')[:120],
        'stars': stars,
        'forks': forks,
        'updated': (repo.get('pushed_at') or '')[:10],
        'language': repo.get('language') or 'unknown',
        'topics': topics[:5],
        'trust_score': score,
        'trust_level': trust,
        'html_url': repo.get('html_url', ''),
        'default_branch': repo.get('default_branch', 'main')
    })

# Sort by trust score descending
scored_repositories.sort(key=lambda x: x['trust_score'], reverse=True)

output = {
    'query': os.environ.get('QUERY', ''),
    'total_found': len(scored_repositories),
    'results': scored_repositories[:15]
}

print(json.dumps(output, indent=2))
PYEOF
