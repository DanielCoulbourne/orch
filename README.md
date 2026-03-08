# Orch

An AI orchestration system built on [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Manages multiple concurrent Claude Code sessions across projects from a single hub, with project management via Linear, session monitoring via heartbeats, and full mobile access.

## What It Does

```
┌──────────────────────────────────────────────────────┐
│                    Orchestrator                       │
│                  (~/orch, tmux)                       │
│                                                      │
│  Spawns sessions ──► session start kathunk/tidy       │
│  Checks inbox   ──► session inbox                    │
│  Manages issues ──► linear issues list               │
│  Monitors       ──► session list (heartbeats)        │
└──────┬───────────────┬───────────────┬───────────────┘
       │               │               │
  ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐
  │  tidy   │    │   verbs   │   │  desktop  │
  │ (tmux)  │    │  (tmux)   │   │  (tmux)   │
  │~/src/   │    │~/src/     │   │~/src/     │
  │  tidy   │    │  verbs    │   │ desktop   │
  └─────────┘    └───────────┘   └───────────┘
       │               │               │
       └───────────────┴───────────────┘
                       │
              ~/orch/inbox/
          (reports + heartbeats)
```

- **Orchestrator** — Central Claude Code session in `~/orch` that manages everything
- **Project sessions** — Claude Code instances in `~/src/{repo}`, spawned via tmux
- **Shared tooling** — Linear CLI, GitHub CLI, API keys shared across all sessions
- **Inbox** — Sessions drop reports and heartbeats for the orchestrator to read
- **Watchdog** — launchd agent restarts the orchestrator if it crashes
- **Mobile** — All sessions sync to the Claude mobile app for on-the-go management

## Quick Start

```bash
# Clone
git clone --recursive https://github.com/DanielCoulbourne/orch.git ~/orch
cd ~/orch

# Setup (installs deps, builds tools, configures watchdog)
./setup.sh

# Verify everything works
./test.sh

# Start the orchestrator
session orch
```

## Components

### [linear-cli](https://github.com/DanielCoulbourne/linear-cli)
Go CLI wrapping Linear's GraphQL API. Manages issues, projects, initiatives, and teams.

### [session-cli](https://github.com/DanielCoulbourne/session-cli)
Go CLI for managing Claude Code sessions across projects via tmux. Handles cloning, environment setup, heartbeats, reporting, and the orchestrator watchdog.

### CLAUDE.md
Instructions for the orchestrator — defines the role, agent patterns (PM agent, inbox agent), and documents all tooling.

## Directory Structure

```
~/orch/                  # This repo — orchestration hub
├── CLAUDE.md            # Orchestrator instructions
├── .env                 # Shared API keys (gitignored)
├── inbox/               # Reports + heartbeats from sessions (gitignored)
├── setup.sh             # One-command setup
├── test.sh              # Verification suite
└── tools/
    ├── linear-cli/      # → github.com/DanielCoulbourne/linear-cli (submodule)
    └── session-cli/     # → github.com/DanielCoulbourne/session-cli (submodule)

~/src/                   # Project repos (managed by session-cli)
├── tidy/
├── verbs/
└── ...
```

## Usage

### From the orchestrator

```bash
# Spawn a project session
session start kathunk/tidy -p "fix the login bug" --dangerously-skip-permissions

# Check on sessions
session list

# Read reports
session inbox --read

# Create a Linear issue
linear issues create --title "Fix auth" --team THU --priority 2

# Send a follow-up to a session
session send tidy "now run the tests"
```

### From mobile

All Claude Code sessions sync to the Claude mobile app. Start sessions from the orchestrator, then continue them on your phone.

## Setup on a New Machine

1. Clone this repo to `~/orch`
2. Run `./setup.sh` — it will:
   - Install Go, tmux, gh via Homebrew
   - Check for Claude Code CLI
   - Authenticate GitHub
   - Build and install `linear` and `session` CLIs
   - Prompt for Linear API key
   - Set up the watchdog launchd agent
3. Run `./test.sh` to verify
4. Run `session orch` to start
