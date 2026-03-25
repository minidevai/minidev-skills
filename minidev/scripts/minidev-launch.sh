#!/bin/bash
# Launch a new token + save idea via MiniDev backend
# Usage: minidev-launch.sh '<launchDetailsJson>'
#
# The backend handles everything: deploys the token on-chain via tokens.fun
# (platform gas wallet, no user signing needed) and saves the idea project.
#
# Required fields in JSON:
#   tokenName      - Token name, max 50 chars
#   tokenSymbol    - Token symbol, max 10 chars
#   description    - One-sentence description of the launchpad
#   appPrompt      - Detailed prompt for AI to build the app
#   template       - App template (currently only "Launchpad")
#   audience       - Target audience ("Agents & Humans", "Humans", "Agents")
#   creatorWallet  - Ethereum address for creator rewards (0x...)
#
# Optional fields in JSON:
#   creatorEmail          - Email for deployment notifications
#   privyAppId            - Privy App ID (required for Launchpad template)
#   rewardRecipientWallet - Wallet for launchpad admin rewards
#   imageUrl              - Token logo URL (use minidev-upload-image.sh first)
#   website               - Project website URL
#   twitter               - Twitter/X URL
#   telegram              - Telegram URL
#   farcaster             - Farcaster URL
#   vault                 - Object with { percentage, lockupDays, vestingDays }
#                           percentage: creator vault percentage (1-100)
#                           lockupDays: vault lockup period in days (min 7)
#                           vestingDays: optional vesting period in days
#
# Example:
#   minidev-launch.sh '{"tokenName":"AgentPad","tokenSymbol":"APAD","description":"A launchpad for AI agent tokens","appPrompt":"Create a token launchpad...","template":"Launchpad","audience":"Agents & Humans","creatorWallet":"0x...","privyAppId":"clxyz123"}'
#
# Returns JSON with { success, projectId, tokenAddress, txHash } on success

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
LAUNCH_JSON="${1:-}"

if [ -z "$LAUNCH_JSON" ]; then
  echo '{"error": "Usage: minidev-launch.sh '\''<launchDetailsJson>'\''"}' >&2
  exit 1
fi

# Validate JSON format
if ! echo "$LAUNCH_JSON" | jq . > /dev/null 2>&1; then
  echo '{"error": "Invalid JSON format."}' >&2
  exit 1
fi

# Validate required fields
TOKEN_NAME=$(echo "$LAUNCH_JSON" | jq -r '.tokenName // empty')
TOKEN_SYMBOL=$(echo "$LAUNCH_JSON" | jq -r '.tokenSymbol // empty')
DESCRIPTION=$(echo "$LAUNCH_JSON" | jq -r '.description // empty')
APP_PROMPT=$(echo "$LAUNCH_JSON" | jq -r '.appPrompt // empty')
CREATOR_WALLET=$(echo "$LAUNCH_JSON" | jq -r '.creatorWallet // empty')

if [ -z "$TOKEN_NAME" ]; then
  echo '{"error": "tokenName is required"}' >&2
  exit 1
fi

if [ -z "$TOKEN_SYMBOL" ]; then
  echo '{"error": "tokenSymbol is required"}' >&2
  exit 1
fi

if [ -z "$DESCRIPTION" ]; then
  echo '{"error": "description is required"}' >&2
  exit 1
fi

if [ -z "$APP_PROMPT" ]; then
  echo '{"error": "appPrompt is required"}' >&2
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

# Submit to backend (deploys token + saves idea in one call)
curl -sf -X POST "${API_URL}/api/v1/launch" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$LAUNCH_JSON" \
  || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "API request failed. Check your API key at https://app.minidev.fun/api-keys"}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }
