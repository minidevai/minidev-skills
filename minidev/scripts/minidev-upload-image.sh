#!/bin/bash
# Upload a local image to IPFS via tokens.fun
# Usage: minidev-upload-image.sh <image_path> [token_name] [token_symbol]
#
# Uploads to IPFS via Pinata and returns:
#   - url:         Display URL (Pinata gateway)
#   - tokenURI:    IPFS metadata URI for on-chain use (ipfs://...)
#   - imageCID:    IPFS CID for the image
#   - metadataCID: IPFS CID for the metadata JSON
#
# Authentication required (API key).
#
# Supported formats: JPEG, PNG, GIF, WebP
# Max size: 5MB
#
# Example:
#   minidev-upload-image.sh /path/to/logo.png "AgentPad" "APAD"
#
# Returns JSON with { success, url, tokenURI, imageCID, metadataCID } on success

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Find config file
if [ -f "$SKILL_DIR/config.json" ]; then
  CONFIG_FILE="$SKILL_DIR/config.json"
elif [ -f "$HOME/.clawdbot/skills/minidev/config.json" ]; then
  CONFIG_FILE="$HOME/.clawdbot/skills/minidev/config.json"
else
  if [ -n "${MINIDEV_API_KEY:-}" ]; then
    API_KEY="$MINIDEV_API_KEY"
    TOKENS_FUN_URL="${TOKENS_FUN_URL:-https://tokens.fun}"
  else
    echo '{"error": "config.json not found. Create it with your API key from https://app.minidev.fun/api-keys"}' >&2
    exit 1
  fi
fi

# Extract config if using file
if [ -z "${API_KEY:-}" ]; then
  API_KEY=$(jq -r '.apiKey // empty' "$CONFIG_FILE")
  TOKENS_FUN_URL=$(jq -r '.tokensFunUrl // .crystalsUrl // "https://tokens.fun"' "$CONFIG_FILE")
fi

if [ -z "$API_KEY" ]; then
  echo '{"error": "apiKey not set in config.json"}' >&2
  exit 1
fi

# Parse arguments
IMAGE_PATH="${1:-}"
TOKEN_NAME="${2:-}"
TOKEN_SYMBOL="${3:-}"

if [ -z "$IMAGE_PATH" ]; then
  echo '{"error": "Usage: minidev-upload-image.sh <image_path> [token_name] [token_symbol]"}' >&2
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "{\"error\": \"File not found: $IMAGE_PATH\"}" >&2
  exit 1
fi

# Validate path characters (prevent argument injection)
if [[ ! "$IMAGE_PATH" =~ ^[a-zA-Z0-9/_.\-\ ]+$ ]]; then
  echo '{"error": "Invalid image path. Only alphanumeric characters, spaces, slashes, dots, hyphens, and underscores are allowed."}' >&2
  exit 1
fi

# Validate file size (max 5MB)
FILE_SIZE=$(stat -f%z "$IMAGE_PATH" 2>/dev/null || stat -c%s "$IMAGE_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -gt 5242880 ]; then
  echo '{"error": "File exceeds 5MB limit"}' >&2
  exit 1
fi

# Validate file extension
EXT="${IMAGE_PATH##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
case "$EXT_LOWER" in
  jpg|jpeg|png|gif|webp) ;;
  *)
    echo '{"error": "Unsupported file type. Use JPEG, PNG, GIF, or WebP."}' >&2
    exit 1
    ;;
esac

# Build curl command with optional name/symbol for metadata
CURL_ARGS=(-sf -X POST "${TOKENS_FUN_URL}/api/upload-image"
  -H "Authorization: Bearer ${API_KEY}"
  -F "file=@${IMAGE_PATH}")

if [ -n "$TOKEN_NAME" ]; then
  CURL_ARGS+=(-F "name=${TOKEN_NAME}")
fi

if [ -n "$TOKEN_SYMBOL" ]; then
  CURL_ARGS+=(-F "symbol=${TOKEN_SYMBOL}")
fi

RESPONSE=$(curl "${CURL_ARGS[@]}" 2>&1) || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "Upload failed. The server rejected the request."}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }

echo "$RESPONSE"
