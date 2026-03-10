#!/usr/bin/env bash
# fetch-skill.sh - Fetch a skill file from GitHub and cache it locally
# Usage: fetch-skill.sh <owner> <repo> <path> [branch]
#
# Fetches raw markdown from raw.githubusercontent.com
# Saves to /tmp/skill-seeker-cache/<owner>/<repo>/<filename>
# Prints the local path on success

set -euo pipefail

OWNER="${1:?Usage: fetch-skill.sh <owner> <repo> <path> [branch]}"
REPO="${2:?Usage: fetch-skill.sh <owner> <repo> <path> [branch]}"
FILEPATH="${3:?Usage: fetch-skill.sh <owner> <repo> <path> [branch]}"
BRANCH="${4:-main}"

# Use the parent directory name as a skill identifier to avoid collisions
SKILL_DIR=$(basename "$(dirname "$FILEPATH")")
[[ "$SKILL_DIR" == "." || "$SKILL_DIR" == "/" ]] && SKILL_DIR=$(basename "$FILEPATH" .md)
CACHE_DIR="/tmp/skill-seeker-cache/$OWNER/$REPO/$SKILL_DIR"
FILENAME=$(basename "$FILEPATH")
LOCAL_PATH="$CACHE_DIR/$FILENAME"

mkdir -p "$CACHE_DIR"

URL="https://raw.githubusercontent.com/$OWNER/$REPO/$BRANCH/$FILEPATH"

HTTP_CODE=$(curl -s -w "%{http_code}" -o "$LOCAL_PATH" "$URL")

if [[ "$HTTP_CODE" != "200" ]]; then
    # Try 'master' branch if 'main' failed
    if [[ "$BRANCH" == "main" ]]; then
        URL="https://raw.githubusercontent.com/$OWNER/$REPO/master/$FILEPATH"
        HTTP_CODE=$(curl -s -w "%{http_code}" -o "$LOCAL_PATH" "$URL")
    fi

    if [[ "$HTTP_CODE" != "200" ]]; then
        echo "ERROR: Failed to fetch $URL (HTTP $HTTP_CODE)" >&2
        rm -f "$LOCAL_PATH"
        exit 1
    fi
fi

# Basic validation
FILE_SIZE=$(wc -c < "$LOCAL_PATH")
if [[ "$FILE_SIZE" -eq 0 ]]; then
    echo "ERROR: Fetched file is empty" >&2
    rm -f "$LOCAL_PATH"
    exit 1
fi

if [[ "$FILE_SIZE" -gt 51200 ]]; then
    echo "WARNING: File is large (${FILE_SIZE} bytes, ~$((FILE_SIZE / 4)) tokens)" >&2
fi

# Store metadata
cat > "$CACHE_DIR/${FILENAME}.meta.json" <<EOF
{
  "owner": "$OWNER",
  "repo": "$REPO",
  "path": "$FILEPATH",
  "branch": "$BRANCH",
  "fetched_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "size_bytes": $FILE_SIZE,
  "estimated_tokens": $((FILE_SIZE / 4)),
  "sha256": "$(sha256sum "$LOCAL_PATH" | cut -d' ' -f1)"
}
EOF

# Output the local path
echo "$LOCAL_PATH"
