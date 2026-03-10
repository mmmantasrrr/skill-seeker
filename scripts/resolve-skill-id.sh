#!/usr/bin/env bash
# resolve-skill-id.sh - Resolve a skill ID to repo and path
# Usage: resolve-skill-id.sh <skill_id>
#
# Returns JSON: {"repo": "owner/repo", "path": "path/to/SKILL.md"}
# Exit code 0 if found, 1 if not found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="$SCRIPT_DIR/../registry.json"
SKILL_ID="${1:?Usage: resolve-skill-id.sh <skill_id>}"

if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo '{"error": "Registry file not found"}' >&2
    exit 1
fi

# Use Python to parse the registry and find the skill
export REGISTRY_FILE
python3 - "$SKILL_ID" <<'PYEOF'
import json
import sys
import os

skill_id = sys.argv[1]
registry_file = os.environ['REGISTRY_FILE']

# Support both with -v1 suffix and without
skill_id_alt = skill_id if skill_id.endswith('-v1') else f"{skill_id}-v1"
skill_id_base = skill_id.replace('-v1', '') if skill_id.endswith('-v1') else skill_id

try:
    with open(registry_file) as f:
        registry = json.load(f)

    for skill in registry.get('skills', []):
        if skill['id'] in (skill_id, skill_id_alt, skill_id_base):
            result = {
                'found': True,
                'repo': skill['repo'],
                'path': skill['path'],
                'name': skill['name'],
                'description': skill['description']
            }
            print(json.dumps(result))
            sys.exit(0)

    # Not found
    print(json.dumps({'found': False, 'error': f'Skill ID "{skill_id}" not found in registry'}))
    sys.exit(1)

except Exception as e:
    print(json.dumps({'found': False, 'error': str(e)}), file=sys.stderr)
    sys.exit(1)
PYEOF
