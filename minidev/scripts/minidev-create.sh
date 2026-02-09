#!/bin/bash
# Submit an app creation request to MiniDev API
# Usage: minidev-create.sh "<prompt>" [name]
#
# Arguments:
#   prompt - Description of the app to create (required)
#   name   - Optional name for the project
#
# Returns JSON with jobId and projectId for polling

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
PROMPT="${1:-}"
NAME="${2:-}"

if [ -z "$PROMPT" ]; then
  echo '{"error": "Usage: minidev-create.sh \"<prompt>\" [name]"}' >&2
  exit 1
fi

# Build request body (appType is always "web3" for web apps)
if [ -n "$NAME" ]; then
  REQUEST_BODY=$(jq -nc \
    --arg prompt "$PROMPT" \
    --arg name "$NAME" \
    '{prompt: $prompt, appType: "web3", name: $name}')
else
  REQUEST_BODY=$(jq -nc \
    --arg prompt "$PROMPT" \
    '{prompt: $prompt, appType: "web3"}')
fi

# Submit request
curl -sf -X POST "${API_URL}/api/v1/apps" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key at https://app.minidev.fun/api-keys"}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
