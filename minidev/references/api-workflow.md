# MiniDev API Workflow

This document describes the MiniDev API workflow, endpoints, and error handling.

## API Base URL

```
https://app.minidev.fun/api/v1
```

## Authentication

All API requests require authentication via API key in the Authorization header:

```
Authorization: Bearer mk_YOUR_API_KEY
```

API keys are linked to your wallet address and can be created at [app.minidev.fun/api-keys](https://app.minidev.fun/api-keys).

## Async Job Workflow

MiniDev uses an asynchronous job-based API for app creation:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Submit    │────▶│    Poll     │────▶│  Complete   │
│  (POST)     │     │   (GET)     │     │  (Result)   │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      ▼                   ▼                   ▼
   jobId             status check        deployedUrl
   projectId         progress %          project data
```

### 1. Submit App Creation

**Endpoint**: `POST /api/v1/apps`

**Request Body**:
```json
{
  "prompt": "Create a simple counter app",
  "appType": "web3",
  "name": "My Counter App",
  "apiKeys": {
    "privyAppId": "YOUR_PRIVY_APP_ID"
  }
}
```

**Request Body (app that reads blockchain data)**:
```json
{
  "prompt": "Create a portfolio tracker that shows my token balances",
  "appType": "web3",
  "name": "My Portfolio",
  "apiKeys": {
    "privyAppId": "YOUR_PRIVY_APP_ID",
    "moralisApiKey": "YOUR_MORALIS_KEY"
  }
}
```

**Parameters**:
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | - | Description of the app (10-10000 chars) |
| appType | string | No | "web3" | App type (use "web3" for web apps) |
| name | string | No | - | Optional project name |
| apiKeys | object | No | - | API keys for app features (see below) |

**API Keys Object**:
| Field | When Required | Description |
|-------|---------------|-------------|
| privyAppId | **Every app** | Privy App ID for user authentication |
| moralisApiKey | Apps reading blockchain data | Moralis API key (portfolios, NFTs, transactions) |
| neynarApiKey | Farcaster social features | Neynar API key (notifications, casts) |
| neynarClientId | With neynarApiKey | Neynar Client ID for frontend features |

> **Important**: `privyAppId` is required for every app. Add `moralisApiKey` only if your app reads blockchain data.

**Response (Success - All Keys Provided)**:
```json
{
  "success": true,
  "jobId": "d85f1aa7-f813-489c-b68a-7fd448fa035d",
  "projectId": "f6124d8c-1a53-4e58-af6c-6187b34e35c6",
  "status": "pending",
  "message": "App generation started",
  "statusUrl": "/api/v1/apps/d85f1aa7-f813-489c-b68a-7fd448fa035d"
}
```

**Response (Missing API Keys)**:
```json
{
  "success": true,
  "jobId": "d85f1aa7-f813-489c-b68a-7fd448fa035d",
  "projectId": null,
  "status": "pending_api_keys",
  "message": "API keys required before generation can start",
  "requiredApiKeys": [
    {
      "type": "privy",
      "reason": "Wallet authentication required for web3 apps",
      "instructions": {
        "title": "Privy App ID Required",
        "description": "Your app needs wallet authentication...",
        "steps": ["Go to dashboard.privy.io...", "..."]
      }
    }
  ],
  "submitKeysUrl": "/api/v1/apps/d85f1aa7-f813-489c-b68a-7fd448fa035d/keys"
}
```

### 1b. Submit Missing API Keys

If the initial request returns `status: "pending_api_keys"`, submit the missing keys:

**Endpoint**: `POST /api/v1/apps/:jobId/keys`

**Request Body**:
```json
{
  "apiKeys": {
    "privyAppId": "YOUR_PRIVY_APP_ID"
  }
}
```

**Response**:
```json
{
  "success": true,
  "jobId": "d85f1aa7-f813-489c-b68a-7fd448fa035d",
  "status": "pending",
  "message": "API keys received, generation started",
  "statusUrl": "/api/v1/apps/d85f1aa7-f813-489c-b68a-7fd448fa035d"
}
```

### 1c. Edit an Existing App

To update or modify an existing app, use the PATCH endpoint:

**Endpoint**: `PATCH /api/v1/apps/:projectId`

**Request Body**:
```json
{
  "prompt": "Add a dark mode toggle to the settings page"
}
```

**Request Body (with API key override)**:
```json
{
  "prompt": "Add NFT gallery feature",
  "apiKeys": {
    "moralisApiKey": "NEW_MORALIS_KEY"
  }
}
```

**Parameters**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| prompt | string | Yes | Description of the changes (10-10000 chars) |
| apiKeys | object | No | Optional API keys to override stored keys |

> **Note**: API keys from initial app creation are stored and reused automatically. Only pass `apiKeys` if you need to override or add new keys.

**Response (Success)**:
```json
{
  "success": true,
  "jobId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "projectId": "f6124d8c-1a53-4e58-af6c-6187b34e35c6",
  "status": "pending",
  "message": "Edit job started",
  "estimatedTime": "2-5 minutes",
  "statusUrl": "/api/v1/apps/a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Error Responses**:
- `404` - Project not found
- `403` - Project does not belong to your wallet
- `402` - Insufficient credits (edits cost 10 credits)

### 2. Poll for Status

**Endpoint**: `GET /api/v1/apps/:id`

The `:id` can be either a job ID or project ID.

**Response (Processing)**:
```json
{
  "projectId": "f6124d8c-1a53-4e58-af6c-6187b34e35c6",
  "name": "My Counter App",
  "status": "processing",
  "job": {
    "id": "d85f1aa7-f813-489c-b68a-7fd448fa035d",
    "status": "processing",
    "progress": 45,
    "statusMessage": "Generating app code..."
  }
}
```

**Response (Completed)**:
```json
{
  "projectId": "f6124d8c-1a53-4e58-af6c-6187b34e35c6",
  "name": "My Counter App",
  "status": "completed",
  "deployedUrl": "https://f6124d8c-1a53-4e58-af6c-6187b34e35c6.minidev.fun",
  "job": {
    "id": "d85f1aa7-f813-489c-b68a-7fd448fa035d",
    "status": "completed",
    "progress": 100
  }
}
```

### Job States

| Status | Description |
|--------|-------------|
| `pending` | Job queued, waiting to start |
| `pending_api_keys` | Waiting for required API keys to be submitted |
| `processing` | App is being generated and deployed |
| `completed` | App successfully deployed |
| `failed` | Build failed (check error message) |

### Polling Strategy

Recommended polling interval: **5 seconds**

```bash
# Poll every 5 seconds for up to 10 minutes
MAX_ATTEMPTS=120
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  sleep 5
  RESULT=$(curl -s -H "Authorization: Bearer $API_KEY" \
    "$API_URL/api/v1/apps/$JOB_ID")
  STATUS=$(echo "$RESULT" | jq -r '.job.status // .status')
  
  case "$STATUS" in
    "completed") echo "Done!"; break ;;
    "failed") echo "Failed"; exit 1 ;;
    "pending_api_keys")
      echo "API keys required!"
      echo "$RESULT" | jq '.requiredApiKeys'
      exit 2 ;;
    *) echo "Building... ($STATUS)" ;;
  esac
  
  ATTEMPT=$((ATTEMPT + 1))
done
```

## Other Endpoints

### Check Credits

**Endpoint**: `GET /api/v1/apps/credits`

**Response**:
```json
{
  "success": true,
  "walletAddress": "0x1B85596a595d330ae7b0D837E77Bc5101Ca8A32a",
  "credits": 40,
  "unlimited": false
}
```

### List Projects

**Endpoint**: `GET /api/v1/apps/projects`

**Query Parameters**:
| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| limit | number | 10 | 50 | Projects per page |
| offset | number | 0 | - | Skip N projects |

**Response**:
```json
{
  "success": true,
  "projects": [
    {
      "id": "f6124d8c-1a53-4e58-af6c-6187b34e35c6",
      "name": "My Counter App",
      "description": "Create a simple counter app...",
      "status": "active",
      "deployedUrl": "https://f6124d8c-1a53-4e58-af6c-6187b34e35c6.minidev.fun",
      "createdAt": "2026-02-08T20:43:48.000Z",
      "updatedAt": "2026-02-08T20:46:21.000Z"
    }
  ],
  "pagination": {
    "total": 140,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

## Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (invalid/missing API key) |
| 402 | Payment required (insufficient credits) |
| 404 | Not found (invalid job/project ID) |
| 500 | Server error |

### Error Response Format

```json
{
  "error": "Error type",
  "message": "Detailed error message"
}
```

### Common Errors

#### Insufficient Credits
```json
{
  "error": "Insufficient credits",
  "message": "You need at least 10 credits to create an app. Current balance: 0"
}
```
**Solution**: Purchase credits at [app.minidev.fun](https://app.minidev.fun)

#### Invalid API Key
```json
{
  "error": "Invalid API key",
  "message": "The provided API key is invalid or has been revoked"
}
```
**Solution**: Generate a new API key at [app.minidev.fun/api-keys](https://app.minidev.fun/api-keys)

#### Prompt Too Short
```json
{
  "error": "Validation error",
  "message": "Prompt must be at least 10 characters"
}
```
**Solution**: Provide a more detailed app description

#### Build Failed
```json
{
  "job": {
    "status": "failed",
    "error": "Build error: syntax error in generated code"
  }
}
```
**Solution**: Try simplifying your prompt or being more specific

## Rate Limits

- App creation: No strict limit, but each creation costs 10 credits
- App edits: No strict limit, but each edit costs 10 credits
- Status checks: No limit
- Credits check: No limit
- Projects list: No limit

## Typical Build Times

| App Complexity | Typical Time |
|----------------|--------------|
| Simple (counter, timer) | 2-3 minutes |
| Medium (todo, notes) | 3-4 minutes |
| Complex (dashboard, multi-page) | 4-6 minutes |

## Example: Full Workflow

```bash
#!/bin/bash
API_KEY="mk_YOUR_KEY_HERE"
API_URL="https://app.minidev.fun"
PRIVY_APP_ID="YOUR_PRIVY_APP_ID"  # Required for all web3 apps

# 1. Check credits first
echo "Checking credits..."
curl -s -H "Authorization: Bearer $API_KEY" \
  "$API_URL/api/v1/apps/credits" | jq .

# 2. Submit app creation (always include privyAppId)
echo "Creating app..."
RESULT=$(curl -s -X POST "$API_URL/api/v1/apps" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"Create a simple counter app\", \"appType\": \"web3\", \"apiKeys\": {\"privyAppId\": \"$PRIVY_APP_ID\"}}")

JOB_ID=$(echo "$RESULT" | jq -r '.jobId')
STATUS=$(echo "$RESULT" | jq -r '.status')
echo "Job ID: $JOB_ID"
echo "Status: $STATUS"

# Check if API keys are missing
if [ "$STATUS" = "pending_api_keys" ]; then
  echo "Error: Missing required API keys!"
  echo "$RESULT" | jq '.requiredApiKeys'
  exit 1
fi

# 3. Poll for completion
echo "Waiting for build..."
while true; do
  sleep 5
  STATUS_RESULT=$(curl -s -H "Authorization: Bearer $API_KEY" \
    "$API_URL/api/v1/apps/$JOB_ID")
  
  STATUS=$(echo "$STATUS_RESULT" | jq -r '.job.status')
  PROGRESS=$(echo "$STATUS_RESULT" | jq -r '.job.progress')
  
  echo "Status: $STATUS ($PROGRESS%)"
  
  if [ "$STATUS" = "completed" ]; then
    DEPLOYED_URL=$(echo "$STATUS_RESULT" | jq -r '.deployedUrl')
    echo "Success! App deployed at: $DEPLOYED_URL"
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "Build failed!"
    echo "$STATUS_RESULT" | jq .
    exit 1
  fi
done
```

## Example: Edit an Existing App

```bash
#!/bin/bash
API_KEY="mk_YOUR_KEY_HERE"
API_URL="https://app.minidev.fun"
PROJECT_ID="f6124d8c-1a53-4e58-af6c-6187b34e35c6"

# 1. Submit edit request (API keys are reused automatically)
echo "Editing app..."
RESULT=$(curl -s -X PATCH "$API_URL/api/v1/apps/$PROJECT_ID" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Add a dark mode toggle to the settings page"}')

JOB_ID=$(echo "$RESULT" | jq -r '.jobId')
echo "Edit job ID: $JOB_ID"

# 2. Poll for completion (same as app creation)
echo "Waiting for build..."
while true; do
  sleep 5
  STATUS_RESULT=$(curl -s -H "Authorization: Bearer $API_KEY" \
    "$API_URL/api/v1/apps/$JOB_ID")
  
  STATUS=$(echo "$STATUS_RESULT" | jq -r '.job.status')
  PROGRESS=$(echo "$STATUS_RESULT" | jq -r '.job.progress')
  
  echo "Status: $STATUS ($PROGRESS%)"
  
  if [ "$STATUS" = "completed" ]; then
    DEPLOYED_URL=$(echo "$STATUS_RESULT" | jq -r '.deployedUrl')
    echo "Success! Updated app at: $DEPLOYED_URL"
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "Build failed!"
    echo "$STATUS_RESULT" | jq .
    exit 1
  fi
done
```

## Resources

- **API Documentation**: https://app.minidev.fun/api/v1/docs
- **API Keys**: https://app.minidev.fun/api-keys
- **Support**: https://x.com/minidevfun
