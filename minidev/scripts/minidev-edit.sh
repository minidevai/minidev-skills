#!/bin/bash
# Edit an existing app via MiniDev API
# Usage: minidev-edit.sh "<projectId>" "<prompt>" [apiKeysJson]
#
# Arguments:
#   projectId   - The project ID to edit (required)
#   prompt      - Description of the changes to make (required)
#   apiKeysJson - Optional JSON object with API keys to override stored keys
#
# Returns JSON with jobId for polling
# API keys from initial creation are reused automatically

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
PROJECT_ID="${1:-}"
PROMPT="${2:-}"
API_KEYS_JSON="${3:-}"

if [ -z "$PROJECT_ID" ] || [ -z "$PROMPT" ]; then
  echo '{"error": "Usage: minidev-edit.sh \"<projectId>\" \"<prompt>\" [apiKeysJson]"}' >&2
  exit 1
fi

# Build request body
if [ -n "$API_KEYS_JSON" ]; then
  REQUEST_BODY=$(jq -nc \
    --arg prompt "$PROMPT" \
    --argjson apiKeys "$API_KEYS_JSON" \
    '{prompt: $prompt, apiKeys: $apiKeys}')
else
  REQUEST_BODY=$(jq -nc \
    --arg prompt "$PROMPT" \
    '{prompt: $prompt}')
fi

# Submit PATCH request
curl -sf -X PATCH "${API_URL}/api/v1/apps/${PROJECT_ID}" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key or project ID."}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
