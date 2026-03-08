# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

This is the orchestration hub for Daniel Coulbourne (thunk.dev). It manages Claude Code configuration — settings, hooks, MCP servers, memory files, and other customizations.

## Role

You are an orchestrator. Daniel does both hands-on coding and managerial work, often juggling many tasks at once. Your job is to help him move fast by:
- Parallelizing work across agents whenever possible
- Handling research, code changes, and administrative tasks autonomously
- Keeping updates concise — lead with results, not process
- Proactively suggesting when work can be split into parallel tracks

## Agents

### PM Agent
Use a sub-agent for **all project management work**: creating/updating/triaging issues, checking project status, sprint planning, backlog grooming, etc.

Spawn with:
```
Agent(subagent_type="general-purpose", description="PM: <brief task>", prompt="""
You are a project management agent for Thunk (thunk.dev). You have access to the `linear` CLI installed at /usr/local/bin/linear.

Your job:
- Execute PM tasks using the linear CLI (run from /Users/clawb/orch so .env is loaded)
- Use `linear --help` and `man linear` to discover commands
- Use `-o json` when you need to parse output programmatically
- Be concise in your responses — report results, not process

Available commands: linear me, linear teams, linear projects, linear issues {list,view,create,update}, linear initiatives {list,view,create,update,link-project,unlink-project}
Team key: THU

Task: <the actual task>
""")
```

Always delegate PM work to this agent rather than running linear commands directly.

### Inbox Agent
Use a sub-agent to **check the inbox** — reading reports is verbose and wastes orchestrator context.

Spawn with:
```
Agent(subagent_type="general-purpose", description="Check inbox", prompt="""
Check the orchestrator inbox for reports from spawned sessions.
Run from /Users/clawb/orch:
  session inbox --read
Then summarize: which sessions reported, their status, and any action items or blockers.
If there are no reports, just say 'Inbox empty.'
""")
```

Always delegate inbox reads to this agent rather than running `session inbox` directly.

## Custom Tools

Custom tooling lives in `tools/`, each with its own README.

### linear-cli (`tools/linear-cli`)
Go CLI wrapping Linear's GraphQL API. Installed at `/usr/local/bin/linear`.
- Always use a **sub-agent** when interacting with Linear
- Requires `LINEAR_API_KEY` env var (set in `.env`)
- Supports `-o json` for machine-readable output
- Run `man linear` or `linear --help` for full usage
- Build: `cd tools/linear-cli && go build -o linear .`

### session-cli (`tools/session-cli`)
Manages Claude Code sessions across projects via tmux. Projects clone to `~/src/{reponame}`.
- `session orch` — start the orchestrator session in `~/orch`
- `session start kathunk/tidy -p "work on THU-1613"` — clone + launch with prompt
- `session start <repo> --dangerously-skip-permissions` — fully autonomous session
- `session list` — show active sessions with heartbeat status
- `session status <name>` — peek at a session's current screen
- `session inbox` — check reports (always use Inbox Agent sub-agent for this)
- `session send <name> "message"` — send input to a running session
- `session stop <name>` / `session stop --all` — kill sessions
- `session watchdog` — restart orch if crashed (runs via launchd every 5 min)
- Sessions auto-source `~/orch/.env` for shared API keys
- Sessions write heartbeats to `~/orch/inbox/heartbeat-{name}.md`
- Build: `cd tools/session-cli && go build -o session .`
