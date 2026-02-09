#!/bin/bash
# Submit missing API keys for a job waiting for them
# Usage: minidev-submit-keys.sh "<jobId>" "<apiKeysJson>"
#
# Arguments:
#   jobId       - The job ID returned from minidev-create.sh
#   apiKeysJson - JSON object with API keys (e.g., '{"moralisApiKey":"...","privyAppId":"..."}')
#
# Use this when minidev-create.sh returns status: "pending_api_keys"

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

# Parse arguments
JOB_ID="${1:-}"
API_KEYS_JSON="${2:-}"

if [ -z "$JOB_ID" ] || [ -z "$API_KEYS_JSON" ]; then
  echo '{"error": "Usage: minidev-submit-keys.sh \"<jobId>\" \"{\\\"moralisApiKey\\\":\\\"...\\\"}\""}' >&2
  exit 1
fi

# Build request body
REQUEST_BODY=$(jq -nc --argjson apiKeys "$API_KEYS_JSON" '{apiKeys: $apiKeys}')

# Submit request
curl -sf -X POST "${API_URL}/api/v1/apps/${JOB_ID}/keys" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key and job ID."}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
