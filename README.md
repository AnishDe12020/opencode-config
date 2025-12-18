# opencode-config

my personal [opencode](https://opencode.ai) configuration with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) and custom swarm orchestrator.

## what's included

### agents
- **OmO** - main orchestrator (claude opus 4.5)
- **oracle** - architecture & debugging (gpt 5.2)
- **librarian** - docs & codebase explorer (claude sonnet 4.5)
- **explore** - fast codebase search (grok)
- **frontend-ui-ux-engineer** - ui/ux specialist (gemini 3 pro)
- **document-writer** - technical writing (gemini 3 pro)
- **multimodal-looker** - visual analysis (gemini 2.5 flash)

### swarm orchestrator
parallel task execution with git worktree isolation:
- `orchestrator` - spawns parallel workers, manages merges
- `worker` - executes tasks in isolated worktrees
- `reviewer` - reviews worker code before completion

### slash commands
| command | description |
|---------|-------------|
| `/swarm` | start multi-agent parallel workflow |
| `/graphite` | stacked pr workflow with graphite cli |
| `/review` | code review of staged/unstaged changes |
| `/test` | generate comprehensive tests |
| `/refactor` | safe refactoring with behavior preservation |
| `/perf` | performance profiling and optimization |
| `/explain` | explain code, concepts, or errors |

### mcps
- `mgrep` - semantic code search
- `playwriter` - browser automation
- context7, exa, grep.app (via oh-my-opencode)

## quick setup

### prerequisites
- [opencode](https://opencode.ai/docs) installed
- [bun](https://bun.sh) installed
- subscriptions: claude max, chatgpt pro, google gemini (optional but recommended)

### one-liner install

**macos / linux:**
```bash
git clone https://github.com/AnishDe12020/opencode-config.git ~/.config/opencode && cd ~/.config/opencode && bun install
```

### authentication

after cloning, authenticate with each provider:

```bash
# claude (required)
opencode auth login
# select: Anthropic → Claude Pro/Max

# chatgpt (for oracle agent)
opencode auth login
# select: OpenAI → ChatGPT Plus/Pro (Codex Subscription)

# google gemini (for frontend/multimodal agents)
opencode auth login
# select: Google → OAuth with Google (Antigravity)
```

### verify setup

```bash
opencode mcp list  # should show mgrep, playwriter connected
opencode           # start opencode, should see OmO agent
```

## customization

### AGENTS.md
edit `AGENTS.md` to personalize the agent context for your workflow.

### oh-my-opencode.json
override agent models or disable features:
```json
{
  "agents": {
    "oracle": { "model": "openai/gpt-5.2-high" }
  },
  "disabled_hooks": ["comment-checker"]
}
```

### add custom commands
create markdown files in `command/`:
```markdown
---
description: my custom command
---

instructions for the agent...
```

## structure

```
~/.config/opencode/
├── opencode.json         # main config (mcps, plugins, providers)
├── oh-my-opencode.json   # oh-my-opencode overrides
├── AGENTS.md             # agent context
├── agent/                # swarm agent definitions
├── command/              # slash commands
├── tool/                 # custom tools (swarm, repo-explorer, etc)
├── plugin/               # custom plugins
└── lib/                  # shared utilities
```

## credits

- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) by [@code-yeongyu](https://github.com/code-yeongyu)
- [opencode](https://github.com/sst/opencode) by [@sst](https://github.com/sst)
