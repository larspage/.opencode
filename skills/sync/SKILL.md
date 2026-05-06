---
name: sync
description: Session sync for reading and updating Moe state files (CHANGELOG, MAILBOX, TODO) and MeAndMoeBrain shared brain
version: 2.0.0
author: moe
type: skill
category: state
tags:
  - sync
  - session
  - state
  - mailbox
  - todo
  - changelog
  - brain
---

# Sync Skill

> **Purpose**: Read and update Moe state files for session management and MeAndMoeBrain shared brain.

---

## CRITICAL: When to Use

**ALWAYS use this skill when:**
- Larry says "brain sync" (startup ritual for MeAndMoeBrain)
- Larry says "brain close" (shutdown ritual for MeAndMoeBrain)
- Larry says "brain push" (manual push to GitHub)
- Starting a NEW project (create STATE/CHANGELOG.md, STATE/MAILBOX.md, STATE/TODO.md)
- Opening an existing project (read STATE files first)
- Making significant changes (update CHANGELOG after each approved change)
- Handing off work (update MAILBOX with open threads)

**This is proactive, not reactive.** Don't wait to be asked.

---

## MeAndMoeBrain Commands

### brain sync (Startup)

When Larry says "brain sync":
1. Read `/mnt/data/projects/MeAndMoeBrain/SOUL.md`
2. Read `/mnt/data/projects/MeAndMoeBrain/USER.md`
3. Read `/mnt/data/projects/MeAndMoeBrain/AGENTS.md`
4. Read today's daily note from `/mnt/data/projects/MeAndMoeBrain/memory/YYYY-MM-DD.md` (create if missing, check date first)
5. Read yesterday's daily note (if exists)
6. Read `/mnt/data/projects/MeAndMoeBrain/MEMORY.md`
7. Scan ALL project STATE/TODO.md files for `[~]` tasks (interrupted tasks from crash/power loss)
8. Process all daily notes with `Memory Promotion Status: Pending` — promote to MEMORY.md
9. **Push to GitHub** (push any unpushed changes from previous sessions)

Don't ask permission. Just do it.

### brain close (Shutdown)

When Larry says "brain close":
1. Check current date for daily note (see Date Check rule below)
2. Log session summary, interruptions, blocked tasks to today's daily note
3. Bridge to project STATE files (scan for `[important]`/`[cross-project]` tags)
4. Set daily note `Memory Promotion Status: Pending`
5. **Push to GitHub** (save all session changes remotely)

### brain push (Manual)

When Larry says "brain push":
- Push all MeAndMoeBrain changes to GitHub immediately

### Date Check Rule (Every Daily Note Write)

Before writing to a daily note, check current system date:
- If `memory/YYYY-MM-DD.md` for today DOES NOT exist → close yesterday's note (add "Session End"), create today's note, write to it
- If it DOES exist → just write to it

---

## Initial Project Setup

**When creating NEW project files, ALWAYS create:**

```
PROJECT/
├── .scripts/
│   ├── port-manager.sh    # Port generator (from project name)
│   └── generate-ports.sh
├── rundev.sh             # Start all services
├── .gitignore           # Include .project-ports
└── STATE/
    ├── CHANGELOG.md
    ├── MAILBOX.md
    └── TODO.md
```

**Steps:**
1. Create `.scripts/port-manager.sh` and `.scripts/generate-ports.sh`
2. Run `source .scripts/port-manager.sh` to generate unique ports
3. Create `rundev.sh` that uses ports from `.project-ports`
4. Add `.project-ports` to `.gitignore`
5. Source ports in any service startup scripts

**Key insight:** Each project needs unique ports to avoid conflicts. The port manager generates unique API/Web ports while sharing DB/Loki/Grafana.

---

## What ">Docs" Means

**When creating docs for a NEW project, ALWAYS create:**

```
PROJECT/
├── docs/           # Planning documentation (SPEC.md, TODO.md, etc.)
└── STATE/          # Moe state tracking
    ├── CHANGELOG.md
    ├── MAILBOX.md
    └── TODO.md
```

**Key insight:** Planning docs (`docs/`) and state tracking (`STATE/`) are DIFFERENT:
- `docs/` = planning, specifications, roadmaps
- `STATE/` = active tracking, changelog, open threads

When asked to "create docs for a new project", I should create BOTH.

---

## What I Do

- **Read state**: Load MAILBOX.md, TODO.md, CHANGELOG.md (project and MeAndMoeBrain)
- **Write state**: Append entries to CHANGELOG and MAILBOX
- **Session management**: Track session start/end (brain sync/brain close)
- **Memory management**: Handle daily notes, promote to MEMORY.md

---

## How to Use Me

### Quick Start

```bash
# Read all MeAndMoeBrain files
bash .opencode/skills/sync/runner.sh brain-read

# Brain sync (startup)
bash .opencode/skills/sync/runner.sh brain-sync

# Brain close (shutdown)
bash .opencode/skills/sync/runner.sh brain-close

# Brain push (manual)
bash .opencode/skills/sync/runner.sh brain-push

# Read project state files
bash .opencode/skills/sync/runner.sh read

# Session start (read + mark active)
bash .opencode/skills/sync/runner.sh start

# Session end (read + resolve open threads)
bash .opencode/skills/sync/runner.sh end

# Add changelog entry
bash .opencode/skills/sync/runner.sh add "category: description"

# Add mailbox entry
bash .opencode/skills/sync/runner.sh mail "category: description"
```

### Command Reference

| Command | Description |
|---------|-------------|
| `brain-read` | Read all MeAndMoeBrain files |
| `brain-sync` | Startup: read brain files, process pending notes, push |
| `brain-close` | Shutdown: log session, set pending, push |
| `brain-push` | Manual push to GitHub |
| `read` | Read all project STATE files |
| `start` | Session start: read state, show active threads |
| `end` | Session end: read state, resolve open threads |
| `add <msg>` | Add CHANGELOG entry |
| `mail <msg>` | Add MAILBOX entry |
| `todo` | Show TODO items |

---

## State File Locations

### MeAndMoeBrain (Shared Brain)
```
/mnt/data/projects/MeAndMoeBrain/
├── SOUL.md          - Agent identity
├── USER.md          - User identity
├── AGENTS.md        - Operating manual
├── MEMORY.md        - Long-term memory
├── memory/          - Daily notes (YYYY-MM-DD.md)
└── STATE/           - Moe state (CHANGELOG, MAILBOX, TODO)
```

### Project STATE
```
PROJECT/STATE/
  CHANGELOG.md  - History of changes
  MAILBOX.md    - Open/resolved threads
  TODO.md      - Active tasks (use [~] for in-progress)
```

---

## Expected Output Format

### CHANGELOG Entry
```
- YYYY-MM-DDTHH:MM:SSZ [category]: what changed
```

### MAILBOX Entry (Open Thread)
```
- YYYY-MM-DDTHH:MM:SSZ [category]: description
```

### MAILBOX Entry (Resolved)
```
- YYYY-MM-DDTHH:MM:SSZ [category]: description - DONE
```

### Daily Note Entry
```
## Session Start
- Time: YYYY-MM-DDTHH:MM:SSZ
- Working on: project-name

## Log
- HH:MM: What happened

## Session End
- Time: YYYY-MM-DDTHH:MM:SSZ

## Memory Promotion
- Status: Pending|Complete
- Last Processed: YYYY-MM-DDTHH:MM:SSZ
```

Categories: deploy, cleanup, fix, add, docs, state, config