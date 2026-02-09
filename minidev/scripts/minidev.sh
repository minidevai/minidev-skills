#!/bin/bash
# MiniDev Agent API wrapper - handles submit-poll-complete workflow
# Usage: minidev.sh "<prompt>" [name] [apiKeysJson]
# 
# Arguments:
#   prompt      - Description of the app to create (required)
#   name        - Optional name for the project
#   apiKeysJson - Optional JSON object with API keys (e.g., '{"moralisApiKey":"...","privyAppId":"..."}')

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Submit the prompt
SUBMIT_RESULT=$("$SCRIPT_DIR/minidev-create.sh" "$@")

# Check if submission succeeded
if ! echo "$SUBMIT_RESULT" | jq -e '.success == true' >/dev/null 2>&1; then
  ERROR=$(echo "$SUBMIT_RESULT" | jq -r '.error // .message // "Submission failed"')
  echo "Error: $ERROR" >&2
  echo "$SUBMIT_RESULT"
  exit 1
fi

# Extract job ID and status
JOB_ID=$(echo "$SUBMIT_RESULT" | jq -r '.jobId')
PROJECT_ID=$(echo "$SUBMIT_RESULT" | jq -r '.projectId // "pending"')
INITIAL_STATUS=$(echo "$SUBMIT_RESULT" | jq -r '.status')

if [ -z "$JOB_ID" ] || [ "$JOB_ID" = "null" ]; then
  echo "Failed to get job ID" >&2
  exit 1
fi

echo "Job submitted: $JOB_ID" >&2
echo "Project ID: $PROJECT_ID" >&2

# Check if API keys are required
if [ "$INITIAL_STATUS" = "pending_api_keys" ]; then
  echo "" >&2
  echo "⚠️  API keys required before generation can start!" >&2
  echo "" >&2
  echo "Required keys:" >&2
  echo "$SUBMIT_RESULT" | jq -r '.requiredApiKeys[] | "  - \(.type): \(.reason)"' >&2
  echo "" >&2
  echo "To submit missing keys, run:" >&2
  echo "  minidev-submit-keys.sh \"$JOB_ID\" '{\"moralisApiKey\":\"YOUR_KEY\"}'" >&2
  echo "" >&2
  echo "$SUBMIT_RESULT"
  exit 2
fi

echo "Polling for results..." >&2

# Poll for completion (max 10 minutes for app builds)
MAX_ATTEMPTS=120  # 120 * 5s = 10 minutes
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  sleep 5
  
  STATUS_RESULT=$("$SCRIPT_DIR/minidev-status.sh" "$JOB_ID")
  
  # Get status from job or project
  JOB_STATUS=$(echo "$STATUS_RESULT" | jq -r '.job.status // .status // "unknown"')
  PROGRESS=$(echo "$STATUS_RESULT" | jq -r '.job.progress // 0')
  
  case "$JOB_STATUS" in
    "completed")
      DEPLOYED_URL=$(echo "$STATUS_RESULT" | jq -r '.deployedUrl // .project.deployedUrl // "N/A"')
      echo "✓ App created successfully!" >&2
      echo "  Deployed URL: $DEPLOYED_URL" >&2
      echo "$STATUS_RESULT"
      exit 0
      ;;
    "failed")
      ERROR=$(echo "$STATUS_RESULT" | jq -r '.job.error // .error // "Unknown error"')
      echo "✗ Build failed: $ERROR" >&2
      echo "$STATUS_RESULT"
      exit 1
      ;;
    "pending_api_keys")
      echo "" >&2
      echo "⚠️  API keys required!" >&2
      echo "Required keys:" >&2
      echo "$STATUS_RESULT" | jq -r '.requiredApiKeys[] | "  - \(.type): \(.reason)"' 2>/dev/null >&2 || echo "  (check response for details)" >&2
      echo "" >&2
      echo "To submit missing keys, run:" >&2
      echo "  minidev-submit-keys.sh \"$JOB_ID\" '{\"moralisApiKey\":\"YOUR_KEY\"}'" >&2
      echo "$STATUS_RESULT"
      exit 2
      ;;
    "pending"|"processing")
      # Show progress updates
      STATUS_MSG=$(echo "$STATUS_RESULT" | jq -r '.job.statusMessage // empty' 2>/dev/null)
      if [ -n "$STATUS_MSG" ]; then
        echo "  [${PROGRESS}%] $STATUS_MSG" >&2
      else
        echo "  [${PROGRESS}%] Building..." >&2
      fi
      ;;
    *)
      echo "  Status: $JOB_STATUS" >&2
      ;;
  esac
  
  ATTEMPT=$((ATTEMPT + 1))
done

echo "✗ Build timed out after 10 minutes" >&2
echo "Job ID: $JOB_ID (you can check status manually with minidev-status.sh)" >&2
exit 1
