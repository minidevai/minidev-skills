# MiniDev Skills Library

Pre-built capabilities for AI agents to create and deploy web apps. Skills enable autonomous app creation, deployment, and management through natural language interfaces.

Public repository of skills for OpenClaw — enabling AI agents to create web apps via the MiniDev API.

## Quick Start

```bash
# Add this repo URL to OpenClaw to browse and install skills:
https://github.com/minidevai/minidev-skills
```

Skills are drop-in modules. No additional configuration required for basic usage.

## Available Skills

| Provider | Skill | Description |
|----------|-------|-------------|
| [minidev](https://app.minidev.fun) | [minidev](minidev/) | AI-powered web app creation. Create web apps from natural language descriptions. Apps are automatically deployed to minidev.fun. |

## Structure

```
minidev-skills/
├── minidev/
│   ├── SKILL.md              # Main skill definition
│   ├── scripts/
│   │   ├── minidev.sh        # Main wrapper (create + poll)
│   │   ├── minidev-create.sh # Submit app creation
│   │   ├── minidev-status.sh # Check build status
│   │   ├── minidev-credits.sh # Check remaining credits
│   │   └── minidev-projects.sh # List projects
│   └── references/
│       └── api-workflow.md   # Detailed API documentation
└── README.md
```

## Install Instructions

Give OpenClaw the URL to this repo and it will let you choose which skill to install.

```
https://github.com/minidevai/minidev-skills
```

## Use Cases

**Autonomous app creation** — Agents create and deploy web apps from natural language descriptions without human intervention.

**Rapid prototyping** — Quickly generate and deploy app ideas for testing and iteration.

## Example Usage

```bash
# Create a simple app
scripts/minidev.sh "Create a todo list app with local storage"

# Check build status
scripts/minidev-status.sh "JOB_ID"

# Check remaining credits
scripts/minidev-credits.sh

# List your projects
scripts/minidev-projects.sh
```

## Configuration

Create a config file at `~/.clawdbot/skills/minidev/config.json`:

```json
{
  "apiKey": "mk_YOUR_KEY_HERE",
  "apiUrl": "https://app.minidev.fun"
}
```

Get your API key at [app.minidev.fun/api-keys](https://app.minidev.fun/api-keys).

## Contributing

We welcome community contributions! Here's how to add your own skill:

### Adding a New Skill

1. **Fork this repository** and create a new branch for your skill.
2. **Create a provider directory** (if it doesn't exist):
   ```
   mkdir your-provider-name/
   ```
3. **Add the required files**:
   - `SKILL.md` — The main skill definition file (required)
   - `references/` — Supporting documentation (optional)
   - `scripts/` — Any helper scripts (optional)
4. **Follow the structure**:
   ```
   your-provider-name/
   ├── SKILL.md
   ├── references/
   │   └── your-docs.md
   └── scripts/
       └── your-script.sh
   ```
5. **Submit a Pull Request** with a clear description of your skill.

### Guidelines

- Keep skill definitions clear and well-documented
- Include examples of usage in your `SKILL.md`
- Test your skill before submitting
- Use descriptive commit messages

## About

MiniDev Skills Library for AI agents. Create web apps through natural language.

## Resources

- **MiniDev App**: https://app.minidev.fun
- **API Keys**: https://app.minidev.fun/api-keys
- **X**: https://x.com/minidevfun

## License

MIT
