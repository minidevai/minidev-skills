#!/bin/bash
# Upload a local image to Cloudinary via tokens.fun
# Usage: minidev-upload-image.sh <image_path>
#
# The image is uploaded to the tokens.fun Cloudinary endpoint.
# No authentication required.
#
# Supported formats: JPEG, PNG, GIF, WebP, SVG
# Max size: 10MB
#
# Example:
#   minidev-upload-image.sh /path/to/logo.png
#
# Returns JSON with { success, url, publicId } on success

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Find config file for tokensFunUrl
TOKENS_FUN_URL=""
if [ -f "$SKILL_DIR/config.json" ]; then
  TOKENS_FUN_URL=$(jq -r '.tokensFunUrl // .crystalsUrl // empty' "$SKILL_DIR/config.json")
elif [ -f "$HOME/.clawdbot/skills/minidev/config.json" ]; then
  TOKENS_FUN_URL=$(jq -r '.tokensFunUrl // .crystalsUrl // empty' "$HOME/.clawdbot/skills/minidev/config.json")
fi

# Fall back to env var or default
TOKENS_FUN_URL="${TOKENS_FUN_URL:-${TOKENS_FUN_URL_ENV:-https://tokens.fun}}"

# Parse arguments
IMAGE_PATH="${1:-}"

if [ -z "$IMAGE_PATH" ]; then
  echo '{"error": "Usage: minidev-upload-image.sh <image_path>"}' >&2
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "{\"error\": \"File not found: $IMAGE_PATH\"}" >&2
  exit 1
fi

# Upload image
RESPONSE=$(curl -sf -X POST "${TOKENS_FUN_URL}/api/upload-image" \
  -F "file=@${IMAGE_PATH}" \
  2>&1) || {
    STATUS=$?
    if [ $STATUS -eq 22 ]; then
      echo '{"error": "Upload failed. The server rejected the request."}' >&2
    else
      echo '{"error": "Network error. Please check your connection."}' >&2
    fi
    exit 1
  }

echo "$RESPONSE"
