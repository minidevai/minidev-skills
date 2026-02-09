#!/bin/bash
# List MiniDev projects with pagination
# Usage: minidev-projects.sh [limit] [offset]
#
# Arguments:
#   limit  - Number of projects to return (default: 10, max: 50)
#   offset - Number of projects to skip (default: 0)
#
# Returns JSON with:
#   - projects: Array of project objects
#   - pagination: { total, limit, offset, hasMore }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Find config file
if [ -f "$SKILL_DIR/config.json" ]; then
  CONFIG_FILE="$SKILL_DIR/config.json"
elif [ -f "$HOME/.clawdbot/skills/minidev/config.json" ]; then
  CONFIG_FILE="$HOME/.clawdbot/skills/minidev/config.json"
else
  # Check environment variables
  if [ -n "${MINIDEV_API_KEY:-}" ]; then
    API_KEY="$MINIDEV_API_KEY"
    API_URL="${MINIDEV_API_URL:-https://app.minidev.fun}"
  else
    echo '{"error": "config.json not found. Create it with your API key from https://app.minidev.fun/api-keys"}' >&2
    exit 1
  fi
fi

# Extract config if using file
if [ -z "${API_KEY:-}" ]; then
  API_KEY=$(jq -r '.apiKey // empty' "$CONFIG_FILE")
  API_URL=$(jq -r '.apiUrl // "https://app.minidev.fun"' "$CONFIG_FILE")
fi

if [ -z "$API_KEY" ]; then
  echo '{"error": "apiKey not set in config.json"}' >&2
  exit 1
fi

# Parse pagination arguments
LIMIT="${1:-10}"
OFFSET="${2:-0}"

# Get projects
curl -sf -X GET "${API_URL}/api/v1/apps/projects?limit=${LIMIT}&offset=${OFFSET}" \
  -H "Authorization: Bearer ${API_KEY}" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key at https://app.minidev.fun/api-keys"}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
