#!/usr/bin/env bash
# search-registry.sh - Search the curated skill registry
# Usage: search-registry.sh <query>
#
# This is Strategy 0 - checks local registry before hitting GitHub API

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="$SCRIPT_DIR/../registry.json"

QUERY="${1:?Usage: search-registry.sh <query>}"

# Check if registry exists
if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo '{"source": "registry", "total_found": 0, "results": [], "error": "Registry file not found"}' | jq .
    exit 0
fi

# Search registry using Python for better JSON handling
export REGISTRY_FILE
python3 - "$QUERY" <<'PYEOF'
import json
import sys
import os

query = sys.argv[1].lower()
query_terms = set(query.split())

# Load registry
registry_path = os.environ.get('REGISTRY_FILE')

try:
    with open(registry_path) as f:
        registry = json.load(f)
except (FileNotFoundError, TypeError):
    print(json.dumps({"source": "registry", "total_found": 0, "results": [], "error": "Registry not found"}))
    sys.exit(0)

# Expand query with synonyms
synonyms = registry.get('query_synonyms', {})
expanded_terms = set(query_terms)
for term in query_terms:
    if term in synonyms:
        # Add first 2 synonyms to avoid over-expansion
        expanded_terms.update(synonyms[term][:2])

# Search skills
results = []
skills = registry.get('skills', [])

for skill in skills:
    score = 0

    # Exact match in name (highest priority)
    if query in skill['name'].lower():
        score += 50

    # Exact match in description
    if query in skill['description'].lower():
        score += 30

    # Tag matches (including expanded terms)
    tags = [t.lower() for t in skill.get('tags', [])]
    aliases = [a.lower() for a in skill.get('aliases', [])]
    all_searchable = tags + aliases

    for term in expanded_terms:
        if term in all_searchable:
            score += 20
        # Partial tag match
        for tag in all_searchable:
            if term in tag or tag in term:
                score += 10

    # Term matches in name or description
    skill_text = (skill['name'] + ' ' + skill['description']).lower()
    for term in query_terms:
        if term in skill_text:
            score += 15

    # Domain matches
    domains = skill.get('domains', [])
    for term in expanded_terms:
        if term in [d.lower() for d in domains]:
            score += 25

    # Boost verified skills
    if skill.get('verified', False):
        score = int(score * 1.2)

    # Add trust score as tiebreaker
    score += skill.get('trust_score', 0) * 0.1

    if score > 10:  # Minimum relevance threshold
        result = {
            'full_name': skill['repo'],
            'skill_id': skill['id'],
            'name': skill['name'],
            'description': skill['description'],
            'path': skill['path'],
            'stars': skill.get('stars', 0),
            'verified': skill.get('verified', False),
            'trust_score': skill.get('trust_score', 0),
            'trust_level': 'HIGH' if skill.get('trust_score', 0) >= 60 else 'MEDIUM' if skill.get('trust_score', 0) >= 40 else 'LOW',
            'tags': skill.get('tags', [])[:5],
            'source': 'registry',
            'relevance_score': int(score),
            'note': skill.get('note', '')
        }
        results.append(result)

# Sort by relevance score
results.sort(key=lambda x: x['relevance_score'], reverse=True)

output = {
    'source': 'registry',
    'query': query,
    'expanded_terms': list(expanded_terms),
    'total_found': len(results),
    'results': results[:10]  # Top 10 results
}

print(json.dumps(output, indent=2))
PYEOF
