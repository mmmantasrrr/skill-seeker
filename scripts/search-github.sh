#!/usr/bin/env bash
# search-github.sh - Search GitHub for Claude Code skill repositories
# Usage:
#   search-github.sh <query>           # Search by query
#   search-github.sh --browse <repo>   # Browse a specific repo's skills
#   search-github.sh --check           # Verify GitHub API connectivity
#
# Requires: curl, jq
# Optional: GITHUB_TOKEN env var for higher rate limits (5000 vs 60 req/hr)

set -euo pipefail

# Track whether any API call failed (used for exit code)
_API_ERRORS=0

gh_api() {
    local url="$1"
    local tmpfile
    tmpfile=$(mktemp)
    local http_code

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        http_code=$(curl -s -w "%{http_code}" -o "$tmpfile" \
             -H "Authorization: token $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3+json" \
             "$url" 2>/dev/null) || http_code="000"
    else
        http_code=$(curl -s -w "%{http_code}" -o "$tmpfile" \
             -H "Accept: application/vnd.github.v3+json" \
             "$url" 2>/dev/null) || http_code="000"
    fi

    # Check for network/connection failure
    if [[ "$http_code" == "000" ]]; then
        echo "ERROR: Cannot connect to GitHub API (network error or DNS block)" >&2
        rm -f "$tmpfile"
        _API_ERRORS=1
        echo '{}'
        return 1
    fi

    # Check for HTTP errors
    if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
        echo "ERROR: GitHub API returned HTTP $http_code for $url" >&2
        if [[ "$http_code" == "403" ]]; then
            echo "HINT: You may be rate-limited. Set GITHUB_TOKEN env var for 5000 req/hr (vs 60 without)." >&2
        elif [[ "$http_code" == "401" ]]; then
            echo "HINT: Your GITHUB_TOKEN may be invalid or expired." >&2
        elif [[ "$http_code" == "404" ]]; then
            echo "HINT: Repository or resource not found." >&2
        fi
        rm -f "$tmpfile"
        _API_ERRORS=1
        echo '{}'
        return 1
    fi

    # Validate JSON response
    if ! jq empty "$tmpfile" 2>/dev/null; then
        echo "ERROR: GitHub API returned non-JSON response (possible network proxy or block)" >&2
        echo "HINT: Check if a corporate proxy or firewall is intercepting api.github.com" >&2
        rm -f "$tmpfile"
        _API_ERRORS=1
        echo '{}'
        return 1
    fi

    cat "$tmpfile"
    rm -f "$tmpfile"
}

# ─── Check mode: verify GitHub API connectivity ───────────────────────────────
if [[ "${1:-}" == "--check" ]]; then
    echo "Checking GitHub API connectivity..."
    echo ""

    # Test api.github.com
    API_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/zen" 2>/dev/null) || API_HTTP="000"
    if [[ "$API_HTTP" == "200" ]]; then
        echo "✅ api.github.com — reachable (HTTP $API_HTTP)"
    else
        echo "❌ api.github.com — UNREACHABLE (HTTP $API_HTTP)"
        echo "   Search and browse will not work."
    fi

    # Test raw.githubusercontent.com
    RAW_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://raw.githubusercontent.com/github/gitignore/main/README.md" 2>/dev/null) || RAW_HTTP="000"
    if [[ "$RAW_HTTP" == "200" ]]; then
        echo "✅ raw.githubusercontent.com — reachable (HTTP $RAW_HTTP)"
    else
        echo "❌ raw.githubusercontent.com — UNREACHABLE (HTTP $RAW_HTTP)"
        echo "   Fetch/install will not work."
    fi

    # Check auth
    echo ""
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        RATE_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/rate_limit" 2>/dev/null) || RATE_RESPONSE="{}"
        REMAINING=$(echo "$RATE_RESPONSE" | jq -r '.resources.search.remaining // "unknown"' 2>/dev/null) || REMAINING="unknown"
        LIMIT=$(echo "$RATE_RESPONSE" | jq -r '.resources.search.limit // "unknown"' 2>/dev/null) || LIMIT="unknown"
        echo "🔑 GITHUB_TOKEN is set"
        echo "   Search rate limit: $REMAINING/$LIMIT remaining"
    else
        echo "⚠️  GITHUB_TOKEN is not set"
        echo "   Using unauthenticated access (60 req/hr, 10 searches/min)"
        echo "   Set GITHUB_TOKEN for 5000 req/hr and 30 searches/min"
    fi

    exit 0
fi

# ─── Browse mode: list skills in a specific repo ───────────────────────────────
if [[ "${1:-}" == "--browse" ]]; then
    REPO="${2:?Usage: search-github.sh --browse owner/repo}"

    # Get default branch (allow failure)
    REPO_INFO=$(gh_api "https://api.github.com/repos/$REPO" || echo '{}')

    # Check if we got a valid response
    if [[ "$(echo "$REPO_INFO" | jq -r '.full_name // empty' 2>/dev/null)" == "" ]]; then
        echo "ERROR: Could not fetch repository info for '$REPO'" >&2
        echo "Run: search-github.sh --check  to diagnose connectivity issues." >&2
        echo '{"repo": "'"$REPO"'", "error": "Could not fetch repository info. GitHub API may be unreachable.", "skills": []}'
        exit 1
    fi

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
    TREE=$(gh_api "https://api.github.com/repos/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1" || echo '{}')

    # Check if tree was fetched successfully
    if [[ "$(echo "$TREE" | jq -r '.tree // empty' 2>/dev/null)" == "" ]]; then
        echo "ERROR: Could not fetch file tree for '$REPO'" >&2
        echo '{"repo": "'"$REPO"'", "description": '"$(echo "$REPO_DESCRIPTION" | jq -Rs .)"', "stars": '"$STARS"', "error": "Could not fetch file tree", "skills": []}'
        exit 1
    fi

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
MIN_STARS="${2:-3}"

# Search strategies (run the most targeted first)
# Allow individual API calls to fail without aborting (set +e locally)
# 1. Topic search for claude-skills + query terms
TOPIC_RESULTS=$(gh_api "https://api.github.com/search/repositories?q=topic:claude-skills+topic:claude-code-skills+${QUERY// /+}&sort=stars&order=desc&per_page=10" || echo '{}')

# 2. Topic search without query filtering (broader)
TOPIC_BROAD=$(gh_api "https://api.github.com/search/repositories?q=topic:claude-skills+${QUERY// /+}&sort=stars&order=desc&per_page=10" || echo '{}')

# 3. Description/name search
DESC_RESULTS=$(gh_api "https://api.github.com/search/repositories?q=${QUERY// /+}+claude+skill+in:description,name&sort=stars&order=desc&per_page=10" || echo '{}')

# Merge and deduplicate results, compute trust scores
export TOPIC_RESULTS TOPIC_BROAD DESC_RESULTS QUERY
python3 - "$MIN_STARS" "$_API_ERRORS" <<'PYEOF'
import json
import os
import sys
from datetime import datetime, timezone

min_stars = int(sys.argv[1])
api_had_errors = sys.argv[2] == "1"

results = {}
api_errors = 0

for var_name in ['TOPIC_RESULTS', 'TOPIC_BROAD', 'DESC_RESULTS']:
    api_response_json = os.environ.get(var_name, '{}')
    try:
        api_response = json.loads(api_response_json)
        if 'items' not in api_response:
            api_errors += 1
        else:
            for item in api_response.get('items', []):
                full_name = item['full_name']
                if full_name not in results:
                    results[full_name] = item
    except (json.JSONDecodeError, KeyError):
        api_errors += 1

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

# Add warning if all API calls failed
if api_errors == 3 or api_had_errors:
    output['api_status'] = 'error'
    if len(scored_repositories) == 0:
        output['warning'] = 'All GitHub API searches failed. Check connectivity with: search-github.sh --check'
        # Signal error to the shell script via stderr
        print("WARNING: All GitHub API searches failed. Results may be incomplete.", file=sys.stderr)
        print("Run: search-github.sh --check  to diagnose connectivity issues.", file=sys.stderr)
elif api_errors > 0:
    output['api_status'] = 'partial'
    output['warning'] = f'{api_errors} of 3 API searches failed. Results may be incomplete.'
else:
    output['api_status'] = 'ok'

print(json.dumps(output, indent=2))

# Exit with error if all searches failed and no results
if api_errors == 3 and len(scored_repositories) == 0:
    sys.exit(1)
PYEOF

PYTHON_EXIT=$?
if [[ "$PYTHON_EXIT" -ne 0 || "$_API_ERRORS" -ne 0 ]]; then
    exit 1
fi
