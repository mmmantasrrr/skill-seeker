#!/usr/bin/env bash
# search-combined.sh - Combined registry + GitHub search with deduplication
# Usage: search-combined.sh <query>
#
# This script combines Strategy 0 (registry) and Strategy 1-3 (GitHub API)
# into a single output, deduplicating by repository name.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUERY="${1:?Usage: search-combined.sh <query>}"

# Run both searches
REGISTRY_RESULTS=$("$SCRIPT_DIR/search-registry.sh" "$QUERY" 2>/dev/null || echo '{"source":"registry","total_found":0,"results":[]}')
GITHUB_RESULTS=$("$SCRIPT_DIR/search-github.sh" "$QUERY" 2>/dev/null || echo '{"source":"github","total_found":0,"results":[]}')

# Combine and deduplicate using Python
export REGISTRY_RESULTS GITHUB_RESULTS
python3 - "$QUERY" <<'PYEOF'
import json
import sys
import os

query = sys.argv[1]

# Read both result sets from environment
registry_results = json.loads(os.environ.get('REGISTRY_RESULTS', '{}'))
github_results = json.loads(os.environ.get('GITHUB_RESULTS', '{}'))

# Deduplicate by repo name (registry takes priority)
seen_repos = {}
combined = []

# Add registry results first (higher priority)
for result in registry_results.get('results', []):
    repo = result.get('full_name', result.get('repo', ''))
    if repo and repo not in seen_repos:
        seen_repos[repo] = True
        result['source'] = 'registry'
        combined.append(result)

# Add GitHub results (skip if already in registry)
for result in github_results.get('results', []):
    repo = result.get('full_name', result.get('repo', ''))
    if repo and repo not in seen_repos:
        seen_repos[repo] = True
        result['source'] = 'github'
        # Normalize GitHub results to match registry format
        if 'trust_level' not in result:
            stars = result.get('stargazers_count', result.get('stars', 0))
            if stars >= 100:
                result['trust_level'] = 'HIGH'
            elif stars >= 30:
                result['trust_level'] = 'MEDIUM'
            else:
                result['trust_level'] = 'LOW'
        combined.append(result)

# Sort by trust/relevance (registry results with relevance_score first, then by stars)
def sort_key(r):
    relevance = r.get('relevance_score', 0)
    stars = r.get('stargazers_count', r.get('stars', 0))
    is_verified = 1 if r.get('verified', False) else 0
    return (is_verified * 1000 + relevance * 10 + stars, stars)

combined.sort(key=sort_key, reverse=True)

output = {
    'source': 'combined',
    'query': query,
    'total_found': len(combined),
    'registry_count': len(registry_results.get('results', [])),
    'github_count': len(github_results.get('results', [])),
    'results': combined[:15],  # Top 15 results
    'github_error': github_results.get('error')
}

print(json.dumps(output, indent=2))
PYEOF
