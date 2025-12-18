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

### notifications
native desktop notifications for swarm events and session idle:
- **ssh sessions**: uses OSC escape sequences (works through ssh without reverse tunnels)
- **local sessions**: native notifications (osascript on macos, notify-send on linux)
- **terminal compatibility**:
  - ✓ iterm2, kitty, ghostty, wezterm, alacritty
  - ✗ vscode terminal (fallback: console messages)
- **events**: swarm complete, swarm abort, session idle

## quick setup

### prerequisites
- [opencode](https://opencode.ai/docs) installed
- [bun](https://bun.sh) installed
- subscriptions: claude max, chatgpt pro, google gemini (optional but recommended)

### interactive installer (recommended)

**macos / linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/AnishDe12020/opencode-config/main/install.sh | bash
```

the installer will:
- ✓ check prerequisites (opencode, bun, git)
- ✓ let you enable/disable components:
  - swarm orchestrator (parallel task execution)
  - custom agents (orchestrator, worker, reviewer)
  - slash commands (/swarm, /graphite, /review, etc)
  - mcp servers (mgrep, playwriter)
- ✓ backup existing config automatically
- ✓ install dependencies
- ✓ show post-install instructions with color output

### manual install

if you prefer to install everything manually:

```bash
[ -d ~/.config/opencode ] && mv ~/.config/opencode ~/.config/opencode.backup.$(date +%s) || true && git clone git@github.com:AnishDe12020/opencode-config.git ~/.config/opencode && cd ~/.config/opencode && bun install
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

### notifications setup (optional)

notifications work automatically, but for best experience:

**macos (local):**
- uses osascript (built-in)
- sounds require system sounds enabled

**linux (local):**
```bash
# install notify-send if not present
sudo apt install libnotify-bin  # debian/ubuntu
sudo dnf install libnotify       # fedora
sudo pacman -S libnotify         # arch
```

**ssh sessions:**
- notifications sent via OSC escape sequences
- **supported terminals**: iterm2, kitty, ghostty, wezterm, alacritty
- **not supported**: vscode terminal (shows console messages instead)
- works without reverse ssh tunnels or port forwarding

**customize notifications:**

create `~/.config/opencode/notifications.local.json`:
```json
{
  "enabled": true,
  "events": {
    "swarmComplete": true,
    "swarmAbort": true,
    "sessionIdle": false
  },
  "sound": true,
  "debug": false
}
```

disable all notifications:
```json
{
  "enabled": false
}
```

enable debug logging:
```json
{
  "debug": true
}
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

## usage examples

### swarm workflow
```bash
# start opencode
opencode

# trigger parallel task execution
/swarm "add user authentication: jwt tokens, login/logout endpoints, password hashing"

# check status
/swarm-status

# abort if needed
/swarm-abort
```

### stacked prs with graphite
```bash
# create feature branch
/graphite "create stack for auth feature"

# opencode makes changes, then:
/graphite "submit stack with dependencies"
```

### code review flow
```bash
# stage your changes
git add .

# get comprehensive review
/review

# address feedback, then commit
git commit -m "fix: address review feedback"
```

### other common patterns
```bash
/test "generate tests for src/auth/jwt.ts"
/refactor "extract validation logic into separate module"
/perf "profile and optimize database queries in getUserPosts"
/explain "why does this regex fail on unicode characters?"
```

## troubleshooting

### authentication issues

**problem**: `opencode auth login` fails or shows "not authenticated"

**solutions**:
```bash
# check which providers are authenticated
opencode auth list

# re-authenticate with specific provider
opencode auth login
# select: Anthropic → Claude Pro/Max (for main agent)
# select: OpenAI → ChatGPT Plus/Pro (for oracle)
# select: Google → OAuth with Google (for gemini agents)

# verify auth files exist
ls ~/.config/opencode/*.auth.json
ls ~/.config/opencode/antigravity-accounts.json
```

### mcp connection problems

**problem**: mcps not showing up or timing out

**solutions**:
```bash
# check mcp status
opencode mcp list

# restart mcp servers
opencode mcp restart

# test mgrep manually
mgrep mcp  # should start server

# test playwriter
bun x playwriter@latest  # should start server

# check logs
tail -f ~/.config/opencode/logs/*.log
```

### notification debugging

**problem**: notifications not appearing

**solutions**:
```bash
# local macos - check osascript works
osascript -e 'display notification "test" with title "test"'

# local linux - check notify-send works
notify-send "test" "test message"

# ssh sessions - check terminal support
echo $TERM_PROGRAM  # should show terminal name
# supported: iterm2, kitty, ghostty, wezterm, alacritty
# not supported: vscode (uses console.log fallback)

# test notifications
/test-notifications
```

### swarm worktree conflicts

**problem**: swarm fails with "worktree already exists" or git errors

**solutions**:
```bash
# check for stale worktrees
git worktree list

# clean up manually
git worktree remove .swarm-*
rm -rf .swarm-*

# or abort and retry
/swarm-abort
/swarm "your task"
```

### agent not using correct model

**problem**: wrong model being used for agents

**verify configuration**:
```bash
# check oh-my-opencode.json
cat ~/.config/opencode/oh-my-opencode.json

# should show agent overrides:
# "oracle": { "model": "openai/gpt-5.2-medium" }
# "frontend-ui-ux-engineer": { "model": "google/gemini-3-pro-high" }
```

### performance issues

**problem**: slow responses or timeouts

**optimize**:
```bash
# reduce mcp timeout in opencode.json
# disable unused mcps
# use faster models for non-critical agents

# check system resources
htop  # or top on macos
# swarm uses multiple worktrees - needs disk space
df -h
```

## credits

- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) by [@code-yeongyu](https://github.com/code-yeongyu)
- [opencode](https://github.com/sst/opencode) by [@sst](https://github.com/sst)
