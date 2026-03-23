#!/bin/bash
# Deploy a token for an existing/pre-built app via MiniDev API
# Usage: minidev-deploy-existing.sh '<deployDetailsJson>'
#
# Deploys a token on-chain (platform gas wallet, no user signing needed)
# and saves it with tokenSource="external" + optional Dune revenue tracking.
# No idea/project is saved to minidev — just the token.
#
# Required fields in JSON:
#   name           - Token name, max 50 chars
#   symbol         - Token symbol, max 10 chars
#   creatorWallet  - Ethereum address for creator rewards (0x...)
#
# Optional fields in JSON:
#   description    - Token description
#   imageUrl       - Token logo URL (use minidev-upload-image.sh first)
#   website        - Project/app website URL
#   twitter        - Twitter/X URL
#   telegram       - Telegram URL
#   farcaster      - Farcaster URL
#   appUrl         - URL of your existing app (shown as preview on the token page)
#   duneQueryId    - Dune Analytics revenue query ID for tracking app revenue
#   vault          - Object with { percentage, lockupDays, vestingDays }
#                    percentage: creator vault percentage (1-100)
#                    lockupDays: vault lockup period in days (min 7)
#                    vestingDays: optional vesting period in days
#
# Example:
#   minidev-deploy-existing.sh '{"name":"MyApp Token","symbol":"MAPP","creatorWallet":"0x...","website":"https://myapp.com","duneQueryId":"12345"}'
#
# Returns JSON with { success, tokenAddress, txHash, urls } on success

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
DEPLOY_JSON="${1:-}"

if [ -z "$DEPLOY_JSON" ]; then
  echo '{"error": "Usage: minidev-deploy-existing.sh '\''<deployDetailsJson>'\''"}' >&2
  exit 1
fi

# Validate JSON format
if ! echo "$DEPLOY_JSON" | jq . > /dev/null 2>&1; then
  echo '{"error": "Invalid JSON format."}' >&2
  exit 1
fi

# Validate required fields
NAME=$(echo "$DEPLOY_JSON" | jq -r '.name // empty')
SYMBOL=$(echo "$DEPLOY_JSON" | jq -r '.symbol // empty')
CREATOR_WALLET=$(echo "$DEPLOY_JSON" | jq -r '.creatorWallet // empty')

if [ -z "$NAME" ]; then
  echo '{"error": "name is required"}' >&2
  exit 1
fi

if [ -z "$SYMBOL" ]; then
  echo '{"error": "symbol is required"}' >&2
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

# Deploy via MiniDev API (no projectId = standalone/external token)
curl -sf -X POST "${API_URL}/api/v1/token/deploy" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$DEPLOY_JSON" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key at https://app.minidev.fun/api-keys"}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
