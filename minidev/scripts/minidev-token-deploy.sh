#!/bin/bash
# Deploy an app coin for a MiniDev project
# Usage: minidev-token-deploy.sh '<tokenDetailsJson>'
#
# The JSON argument must include:
#   projectId     - UUID of the project to deploy the app coin for (required)
#   name          - Token name, max 50 chars (required)
#   symbol        - Token symbol, max 10 chars (required)
#   creatorWallet - Ethereum address for creator rewards (required)
#
# Optional fields in JSON:
#   description   - Token description
#   imageUrl      - Token logo URL
#   website       - Project website URL
#   twitter       - Twitter/X profile URL
#   telegram      - Telegram group/channel URL
#   farcaster     - Farcaster profile URL
#   vault         - Object with { percentage, lockupDays, vestingDays }
#
# NOTE: devBuyEth is NOT supported via API - requires user's wallet to sign transaction
#
# Example:
#   minidev-token-deploy.sh '{"projectId":"uuid","name":"My Token","symbol":"MTK","creatorWallet":"0x..."}'
#
# Returns JSON with tokenAddress, txHash, and URLs on success

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
TOKEN_DETAILS_JSON="${1:-}"

if [ -z "$TOKEN_DETAILS_JSON" ]; then
  echo '{"error": "Usage: minidev-token-deploy.sh '\''<tokenDetailsJson>'\''"}' >&2
  echo '{"error": "Example: minidev-token-deploy.sh '\''{\"projectId\":\"uuid\",\"name\":\"My Token\",\"symbol\":\"MTK\",\"creatorWallet\":\"0x...\"}'\''"}' >&2
  exit 1
fi

# Validate JSON format
if ! echo "$TOKEN_DETAILS_JSON" | jq . > /dev/null 2>&1; then
  echo '{"error": "Invalid JSON format. Ensure the token details are valid JSON."}' >&2
  exit 1
fi

# Validate required fields
PROJECT_ID=$(echo "$TOKEN_DETAILS_JSON" | jq -r '.projectId // empty')
NAME=$(echo "$TOKEN_DETAILS_JSON" | jq -r '.name // empty')
SYMBOL=$(echo "$TOKEN_DETAILS_JSON" | jq -r '.symbol // empty')
CREATOR_WALLET=$(echo "$TOKEN_DETAILS_JSON" | jq -r '.creatorWallet // empty')

if [ -z "$PROJECT_ID" ]; then
  echo '{"error": "projectId is required. Use minidev-projects.sh to list your projects."}' >&2
  exit 1
fi

if [ -z "$NAME" ]; then
  echo '{"error": "name is required (token name, max 50 chars)"}' >&2
  exit 1
fi

if [ -z "$SYMBOL" ]; then
  echo '{"error": "symbol is required (token symbol, max 10 chars)"}' >&2
  exit 1
fi

if [ -z "$CREATOR_WALLET" ]; then
  echo '{"error": "creatorWallet is required (Ethereum address starting with 0x)"}' >&2
  exit 1
fi

# Validate wallet address format
if ! echo "$CREATOR_WALLET" | grep -qE '^0x[a-fA-F0-9]{40}$'; then
  echo '{"error": "creatorWallet must be a valid Ethereum address (0x followed by 40 hex characters)"}' >&2
  exit 1
fi

# Submit request
curl -sf -X POST "${API_URL}/api/v1/token/deploy" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$TOKEN_DETAILS_JSON" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key at https://app.minidev.fun/api-keys"}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
