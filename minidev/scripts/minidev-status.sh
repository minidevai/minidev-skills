#!/bin/bash
# Check status of a MiniDev job or project
# Usage: minidev-status.sh <job_id_or_project_id>
#
# Returns JSON with:
#   - job status (pending, processing, completed, failed)
#   - progress percentage
#   - deployed URL (when completed)
#   - error message (if failed)

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
    echo '{"error": "config.json not found"}' >&2
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

# Get ID from argument
ID="${1:-}"

if [ -z "$ID" ]; then
  echo '{"error": "Usage: minidev-status.sh <job_id_or_project_id>"}' >&2
  exit 1
fi

# Get status
curl -sf -X GET "${API_URL}/api/v1/apps/${ID}" \
  -H "Authorization: Bearer ${API_KEY}" \
  || {
    echo '{"error": "Failed to get status"}' >&2
    exit 1
  }
