---
name: minidev
description: AI-powered web app creation agent via natural language. Use when the user wants to create web apps or web3 applications. Supports creating apps from text descriptions, checking build status, viewing deployed URLs, managing credits, and listing projects. Apps are automatically deployed to minidev.fun with custom subdomains.
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

Create and deploy web apps using natural language through MiniDev's AI agent API.

## Quick Start

### First-Time Setup

There are two ways to get started:

#### Option A: User provides an existing API key

If the user already has a MiniDev API key, they can provide it directly:

```bash
mkdir -p ~/.clawdbot/skills/minidev
cat > ~/.clawdbot/skills/minidev/config.json << 'EOF'
{
  "apiKey": "mk_YOUR_KEY_HERE",
  "apiUrl": "https://app.minidev.fun"
}
EOF
```

API keys can be created and managed at [app.minidev.fun/api-keys](https://app.minidev.fun/api-keys). The key is linked to your wallet address.

#### Option B: Create a new API key (guided by Clawd)

Clawd can walk the user through the API key creation flow:

1. **Connect Wallet** — User visits [app.minidev.fun](https://app.minidev.fun) and connects their wallet
2. **Navigate to API Keys** — Click on profile icon and select "Get API Key"
3. **Sign Message** — Sign a message to prove wallet ownership
4. **Copy API Key** — Copy the generated key (starts with `mk_`)
5. **Configure** — Save the key to config:

```bash
mkdir -p ~/.clawdbot/skills/minidev
cat > ~/.clawdbot/skills/minidev/config.json << 'EOF'
{
  "apiKey": "mk_YOUR_KEY_HERE",
  "apiUrl": "https://app.minidev.fun"
}
EOF
```

#### Verify Setup

```bash
scripts/minidev-credits.sh
```

## Core Usage

### Create an App

For creating apps from natural language descriptions:

```bash
scripts/minidev.sh "Create a simple counter app with increment and decrement buttons"
```

The main script handles the full submit-poll-complete workflow automatically and returns the deployed URL when ready.

### Check Status

For checking the status of an ongoing build:

```bash
scripts/minidev-status.sh "JOB_ID_OR_PROJECT_ID"
```

### Check Credits

```bash
scripts/minidev-credits.sh
```

### List Projects

```bash
scripts/minidev-projects.sh
scripts/minidev-projects.sh 10 0  # limit=10, offset=0
```

## Capabilities Overview

### App Creation

- **Web Apps**: Create full-stack web applications from descriptions
- **Automatic Deployment**: Apps are deployed to `{projectId}.minidev.fun`
- **Modern Stack**: Next.js, React, TypeScript, Tailwind CSS

### Project Management

- Check build status and progress
- View deployed URLs
- List all your projects with pagination
- Track credits usage

### Credit System

- Each app creation costs 1 credit
- Credits are linked to your wallet address
- Purchase credits at [app.minidev.fun](https://app.minidev.fun)

## API Workflow

MiniDev uses an asynchronous job-based API:

1. **Submit** - Send prompt, get job ID and project ID
2. **Poll** - Check status every 5 seconds
3. **Complete** - Get deployed URL when done

The `minidev.sh` wrapper handles this automatically. For details on the API structure, job states, polling strategy, and error handling, see:

**Reference**: [references/api-workflow.md](references/api-workflow.md)

## Common Patterns

### Create and Deploy

```bash
# Create a simple app
scripts/minidev.sh "Create a todo list app with local storage"

# Create with a custom name
scripts/minidev.sh "Create a weather dashboard" "WeatherApp"

# Create a dashboard
scripts/minidev.sh "Create a crypto portfolio tracker dashboard"
```

### Check Build Progress

```bash
# Get job/project status
scripts/minidev-status.sh "d85f1aa7-f813-489c-b68a-7fd448fa035d"
```

### Manage Credits

```bash
# Check remaining credits
scripts/minidev-credits.sh

# Response shows:
# - credits: Number remaining (-1 if unlimited)
# - walletAddress: Your linked wallet
```

### Browse Projects

```bash
# List recent projects
scripts/minidev-projects.sh

# With pagination
scripts/minidev-projects.sh 5 0   # First 5 projects
scripts/minidev-projects.sh 5 5   # Next 5 projects
```

## Prompt Examples

### Simple Apps

- "Create a simple counter app with increment and decrement buttons"
- "Build a todo list app with add, complete, and delete functionality"
- "Make a note-taking app with markdown support"
- "Create a timer app with start, stop, and reset buttons"

### Utility Apps

- "Create a QR code generator"
- "Build a color palette generator"
- "Make a markdown preview tool"
- "Create a JSON formatter and validator"
- "Build a calculator app"

### Dashboard Apps

- "Create a weather dashboard with location search"
- "Build a stock market tracker"
- "Make a social media analytics dashboard"
- "Create a project management board"
- "Build a habit tracker with charts"

### Interactive Apps

- "Create a quiz app with multiple choice questions"
- "Build a flashcard study app"
- "Make a recipe book with search functionality"
- "Create a budget tracker with expense categories"

## Error Handling

Common issues and fixes:

- **Insufficient credits** → Purchase more at app.minidev.fun
- **Invalid API key** → Regenerate at app.minidev.fun/api-keys
- **Build failed** → Check error message, simplify prompt
- **Timeout** → Complex apps may take longer, check status manually

## Best Practices

### Prompts

1. Be specific about what you want
2. Mention key features explicitly
3. Specify the app type if not Farcaster
4. Keep prompts focused on one app concept

### Credits

1. Check credits before creating apps
2. Test with simple apps first
3. Complex apps cost the same (1 credit)

### Monitoring

1. Use status endpoint for long builds
2. Apps typically complete in 2-5 minutes
3. Check projects list for all your deployments

## Configuration

### Config File Location

```
~/.clawdbot/skills/minidev/config.json
```

### Config Structure

```json
{
  "apiKey": "mk_YOUR_KEY_HERE",
  "apiUrl": "https://app.minidev.fun"
}
```

### Environment Variables (Alternative)

```bash
export MINIDEV_API_KEY="mk_YOUR_KEY_HERE"
export MINIDEV_API_URL="https://app.minidev.fun"
```

## Resources

- **App**: https://app.minidev.fun
- **API Keys**: https://app.minidev.fun/api-keys
- **Credits**: Purchase at https://app.minidev.fun
- **Twitter**: @miniaboratory

## Troubleshooting

### Scripts Not Working

```bash
# Ensure scripts are executable
chmod +x ~/.clawdbot/skills/minidev/scripts/*.sh

# Test connectivity
curl -I https://app.minidev.fun
```

### API Errors

See [references/api-workflow.md](references/api-workflow.md) for comprehensive troubleshooting.

### Getting Help

1. Check error message in response JSON
2. Verify API key is valid
3. Ensure sufficient credits
4. Test with simple prompts first

---

**Pro Tip**: Start with simple app descriptions and iterate. The AI works best with clear, focused prompts.

**Security**: Keep your API key private. Never commit config.json to version control.

**Quick Win**: Try creating a simple counter app first to verify everything works, then move on to more complex apps.
