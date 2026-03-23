---
name: minidev
description: AI-powered token deployment via MiniDev. Two flows — "Launch a Launchpad" (deploy token + auto-build app when volume threshold hit) and "I Already Have an App" (deploy token for existing project with Dune revenue tracking). Use when the user wants to launch token-powered launchpads or deploy tokens for existing projects.
metadata:
  {
    "clawdbot":
      {
        "emoji": "🚀",
        "homepage": "https://app.minidev.fun",
        "requires": { "bins": ["curl", "jq"] },
      },
  }
---

# MiniDev

Deploy tokens and build apps using natural language through MiniDev.

## What Can I Help You With?

When the user asks what you can do, what MiniDev is, or how you can help, respond with:

> "I can help you with two things:
>
> 1. **Launch a Launchpad** — Describe your idea and I'll deploy a token for it on Base. Once the token starts trading, your launchpad app gets built automatically by AI.
>
> 2. **Deploy a token for your existing app** — If you already have a live app or project, I can deploy a token for it and set up revenue tracking via Dune Analytics.
>
> Which would you like to do?"

## Flow 1: Launch a Launchpad

The main way to use MiniDev — deploy a token + save an app idea that auto-builds when the token hits trading volume.

### What is a Launchpad?

A Launchpad is a platform where users can launch tokens within a specific category or niche. The user's idea defines the *category*:
- "AI agents" -> a launchpad for launching AI agent tokens
- "meme coins for dogs" -> a launchpad for dog-themed meme tokens
- "DeFi protocols" -> a launchpad for DeFi protocol tokens

**Only the Launchpad template is currently supported.** If the user's idea doesn't fit a launchpad (e.g., "build me a blog"), respond:

> "Right now, MiniDev supports launching **Launchpads** — platforms where communities can launch tokens around a specific theme or category. If you already have a built app, I can deploy a token for it instead! More app types are coming soon. Would you like to explore turning your idea into a launchpad, or deploy a token for an existing app?"

### Step-by-Step Agent Instructions

When the user describes an app idea:

**1. Derive all fields from the user's idea:**

| Field | How to derive |
|-------|--------------|
| `tokenName` | Short, catchy project name (2-3 words max). Think brand name. |
| `tokenSymbol` | 3-5 uppercase letters. Abbreviation or memorable ticker. |
| `description` | One-sentence elevator pitch of the launchpad. |
| `appPrompt` | Detailed prompt for Claude to build the app. Include: features, UI style, integrations, target functionality. This is what the AI builder reads — be thorough. |
| `template` | Always `"Launchpad"` (only supported template). |
| `audience` | One of: `"Agents & Humans"`, `"Humans"`, `"Agents"`. Default to `"Agents & Humans"`. |

**2. Present the derived fields to the user for confirmation:**

Show the token name, symbol, description, and app prompt. Ask if they want to change anything.

**3. Ask for required config:**

- **Privy App ID** (required for Launchpad): "I'll need your Privy App ID for wallet authentication. You can create one at https://dashboard.privy.io if you don't have one yet."
- **Token image** (optional): "Would you like to provide a token image/logo, or launch without one?"

**4. Upload image (if provided):**

If the user provides a local image path:
```bash
scripts/minidev-upload-image.sh /path/to/image.png
```
Use the returned `url` as `imageUrl` in the launch request.

**5. Launch:**

```bash
scripts/minidev-launch.sh '<launchDetailsJson>'
```

The backend handles everything in one call: deploys the token on-chain via tokens.fun (platform pays gas, no user signing needed) and saves the idea project.

**6. Report success:**

Share the token page URL, BaseScan URL, and explain that the app will auto-build when the token reaches the $1 trading volume threshold.

### Example Conversation

```
User: "I want to create a launchpad for AI agent tokens"

Agent (derives fields internally):
  tokenName:    "AgentPad"
  tokenSymbol:  "APAD"
  description:  "A launchpad for launching AI agent tokens on Base"
  appPrompt:    "Create a token launchpad focused on AI agents. Users can
                 launch new AI agent tokens, browse existing launches,
                 view token stats (market cap, volume, price charts),
                 and trade. Features: token creation form, live feed of
                 new launches, trending/top tokens leaderboard, token
                 detail pages with charts, wallet connection via Privy,
                 clean card-based UI with dark mode."
  template:     "Launchpad"
  audience:     "Agents & Humans"

Agent: "Here's what I've prepared for your launchpad:

  Token Name:   AgentPad
  Symbol:       $APAD
  Description:  A launchpad for launching AI agent tokens on Base
  Template:     Launchpad
  Audience:     Agents & Humans

  App Prompt (what the AI will build):
  > Create a token launchpad focused on AI agents. Users can launch
  > new AI agent tokens, browse existing launches, view token stats,
  > and trade. Features: token creation form, live feed, leaderboard,
  > token detail pages with charts, wallet connection via Privy, dark mode.

  I'll need your Privy App ID for wallet authentication.
  You can create one at https://dashboard.privy.io

  Would you like to change anything?"

User: "My Privy App ID is clxyz123. Looks good, launch it!"

Agent: "Got it! Would you like to provide a token image/logo?"

User: "Here's the logo: /Users/me/agentpad-logo.png"

Agent: [uploads image]
  scripts/minidev-upload-image.sh /Users/me/agentpad-logo.png

Agent: [launches — single API call]
  scripts/minidev-launch.sh '{"tokenName":"AgentPad","tokenSymbol":"APAD","description":"A launchpad for launching AI agent tokens on Base","appPrompt":"Create a token launchpad focused on AI agents...","template":"Launchpad","audience":"Agents & Humans","privyAppId":"clxyz123","imageUrl":"https://res.cloudinary.com/.../agentpad-logo.png","creatorWallet":"0xabc...def","creatorEmail":"user@example.com"}'

Agent: "Your token AgentPad ($APAD) is live!

  Token page:  https://tokens.fun/coin/0x1234...5678
  BaseScan:    https://basescan.org/address/0x1234...5678

  Your launchpad will automatically start building once your token
  reaches the $1 trading volume threshold. The system checks every
  60 seconds — once it triggers, your AI agent token launchpad will
  be built and deployed automatically."
```

### Launch Script Details

**Script**: `scripts/minidev-launch.sh '<launchDetailsJson>'`

**Required JSON fields**:
- `tokenName` — Token name (max 50 chars)
- `tokenSymbol` — Token symbol (max 10 chars)
- `description` — One-sentence description
- `appPrompt` — Detailed build prompt for the AI
- `template` — `"Launchpad"`
- `audience` — `"Agents & Humans"`, `"Humans"`, or `"Agents"`
- `creatorWallet` — Ethereum address (0x...)

**Optional JSON fields**:
- `creatorEmail` — Email for deployment notifications
- `privyAppId` — Privy App ID (required for Launchpad)
- `rewardRecipientWallet` — Wallet for launchpad admin rewards
- `imageUrl` — Token logo URL (upload first with `minidev-upload-image.sh`)
- `vault` — Object with `{ percentage, lockupDays, vestingDays }` for creator vault
- `website`, `twitter`, `telegram`, `farcaster` — Social links

**Response**:
```json
{
  "success": true,
  "projectId": "uuid",
  "tokenAddress": "0x...",
  "txHash": "0x...",
  "message": "Idea stored successfully"
}
```

### What Happens After Launch

1. The volume monitor polls DexScreener every 60 seconds
2. When the token hits $1 in 24h trading volume, the threshold triggers
3. The system checks if Privy + infrastructure are ready
4. If ready, the launchpad app is auto-built using the stored `appPrompt`
5. If not ready, a setup email is sent to `creatorEmail`
6. The app appears on tokens.fun and gets a `{slug}.minidev.fun` URL

---

## Flow 2: I Already Have an App

For users who already have a live app or project and want to deploy a token for it. This flow **does not** create an idea project in MiniDev — it deploys a standalone token on-chain via the MiniDev API and saves it to tokens.fun with optional Dune Analytics revenue tracking.

### How It Differs from Launchpad Flow

| | Launch a Launchpad | I Already Have an App |
|---|---|---|
| **Purpose** | Build a new app + deploy token | Deploy token for existing app |
| **App building** | Auto-built when token hits volume | No app building — user already has one |
| **API endpoint** | `POST /api/internal/idea` | `POST /api/v1/token/deploy` (no projectId) |
| **Token source** | `minidev` | `external` |
| **Revenue tracking** | Not applicable | Dune Analytics query ID |
| **Key data saved** | App prompt, template, audience | Website URL, Dune query ID |

### Step-by-Step Agent Instructions

When the user says they already have an app, or want to deploy a token for an existing project:

**1. Gather token details:**

| Field | How to gather |
|-------|--------------|
| `name` | Ask for the token name (or derive from their project name). Max 50 chars. |
| `symbol` | Ask for the ticker symbol. 3-5 uppercase letters. |
| `description` | One-sentence description of their project/app. |
| `website` | Ask for their app/project URL. This is important — it's how people find their app from the token page. |

**2. Ask about revenue tracking (Dune Analytics):**

Explain what this is and ask if they have one:

> "Would you like to track your app's revenue on the token page? If you have a Dune Analytics query that returns your app's revenue data, I can link it to your token. This is a single query ID — the query should return revenue in a column named `revenue`, `total_revenue`, `amount`, or `usd_amount`. You can set this up later on tokens.fun if you don't have one yet."

**3. Ask about vault configuration (optional):**

> "Would you like to set up a creator vault? A vault locks a percentage of the token supply for a set period, which signals long-term commitment to your community. You can configure:
> - **Vault percentage** (1-100%) — how much of the supply to lock
> - **Lockup period** (minimum 7 days) — how long tokens are locked
> - **Vesting period** (optional) — gradual release after lockup ends"

**4. Ask for optional details:**

- **Token image** (optional): "Would you like to provide a token image/logo?"
- **Social links** (optional): Twitter, Telegram, Farcaster

**5. Present summary and confirm:**

Show all details and ask if they want to change anything.

**6. Upload image (if provided):**

```bash
scripts/minidev-upload-image.sh /path/to/image.png
```

**7. Deploy:**

```bash
scripts/minidev-deploy-existing.sh '<deployDetailsJson>'
```

**8. Report success:**

Share the token page URL and BaseScan URL. If they provided a Dune query ID, mention that revenue will be tracked and refreshed daily.

### Example Conversation

```
User: "I already have an app, I want to deploy a token for it"

Agent: "Great! I can deploy a token for your existing app on Base.
       I'll need a few details:

       1. What's your token name and symbol?
       2. What's your app's URL?
       3. A one-sentence description of your project"

User: "The app is called SwapFlow, it's a DEX aggregator at swapflow.xyz"

Agent: "Here's what I've prepared:

  Token Name:   SwapFlow
  Symbol:       $SWAP
  Description:  A DEX aggregator that finds the best swap rates across Base
  Website:      https://swapflow.xyz

  Would you like to track your app's revenue on the token page?
  If you have a Dune Analytics query that returns your revenue data,
  I can link it. The query should return revenue in a column named
  'revenue', 'total_revenue', 'amount', or 'usd_amount'. You can
  also set this up later on tokens.fun."

User: "Yes, my Dune query ID is 4182753"

Agent: "Got it! Would you like to provide a token image/logo or any
       social links (Twitter, Telegram, Farcaster)?"

User: "No image, but Twitter is https://x.com/swapflow"

Agent: [deploys token]
  scripts/minidev-deploy-existing.sh '{"name":"SwapFlow","symbol":"SWAP","description":"A DEX aggregator that finds the best swap rates across Base","creatorWallet":"0xabc...def","website":"https://swapflow.xyz","twitter":"https://x.com/swapflow","duneQueryId":"4182753"}'

Agent: "Your token SwapFlow ($SWAP) is live!

  Token page:  https://tokens.fun/coin/0x9876...5432
  BaseScan:    https://basescan.org/address/0x9876...5432

  Your Dune revenue query (ID: 4182753) is linked — revenue data
  will be fetched and displayed on your token page daily."
```

### Deploy Existing App Script Details

**Script**: `scripts/minidev-deploy-existing.sh '<deployDetailsJson>'`

**Required JSON fields**:
- `name` — Token name (max 50 chars)
- `symbol` — Token symbol (max 10 chars)
- `creatorWallet` — Ethereum address (0x...)

**Optional JSON fields**:
- `description` — Project description
- `website` — App/project URL
- `imageUrl` — Token logo URL (upload first with `minidev-upload-image.sh`)
- `duneQueryId` — Dune Analytics revenue query ID (single query that returns app revenue)
- `vault` — Object with `{ percentage, lockupDays, vestingDays }` for creator vault
- `twitter`, `telegram`, `farcaster` — Social links

**Response**:
```json
{
  "success": true,
  "tokenAddress": "0x...",
  "txHash": "0x...",
  "urls": {
    "clankerWorld": "https://clanker.world/token/0x...",
    "basescan": "https://basescan.org/token/0x...",
    "crystals": "https://tokens.fun/token/0x..."
  }
}
```

---

## Upload Image Script

**Script**: `scripts/minidev-upload-image.sh <image_path>`

Uploads a local image to Cloudinary. No auth required. Use the returned URL as `imageUrl` in either flow.

```bash
scripts/minidev-upload-image.sh /path/to/logo.png
# Returns: { "success": true, "url": "https://res.cloudinary.com/...", "publicId": "..." }
```

---

## Setup

### API Key Configuration

```bash
mkdir -p ~/.clawdbot/skills/minidev
cat > ~/.clawdbot/skills/minidev/config.json << 'EOF'
{
  "apiKey": "mk_YOUR_KEY_HERE",
  "apiUrl": "https://app.minidev.fun",
  "tokensFunUrl": "https://tokens.fun",
  "internalApiUrl": "https://api.minidev.fun",
  "internalApiKey": "YOUR_INTERNAL_API_KEY",
  "creatorWallet": "0xYOUR_WALLET",
  "creatorEmail": "you@example.com"
}
EOF
```

- `apiKey` — MiniDev API key for app creation, editing, and token deployment (get at https://app.minidev.fun/api-keys)
- `apiUrl` — MiniDev API base URL (default: https://app.minidev.fun)
- `tokensFunUrl` — tokens.fun URL for image uploads (default: https://tokens.fun)
- `internalApiUrl` — MiniDev backend URL (for "Launch a Launchpad" flow)
- `internalApiKey` — Internal API key (for "Launch a Launchpad" flow)
- `creatorWallet` — Your Ethereum wallet address
- `creatorEmail` — Your email for notifications

## API Keys

| Key | When Required | How to Get |
|-----|---------------|------------|
| `privyAppId` | **Every Launchpad app** | [dashboard.privy.io](https://dashboard.privy.io) |

## Error Handling

- **Token deployment failed** -> Check error message, may be gas/network issue
- **Invalid API key** -> Check config.json keys are correct

## Resources

- **App**: https://app.minidev.fun
- **Token Launchpad**: https://tokens.fun
- **X**: https://x.com/minidevfun
