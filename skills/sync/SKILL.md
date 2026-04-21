---
name: sync
description: Session sync for reading and updating Moe state files (CHANGELOG, MAILBOX, TODO)
version: 1.0.0
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
---

# Sync Skill

> **Purpose**: Read and update Moe state files for session management.

---

## CRITICAL: When to Use

**ALWAYS use this skill when:**
- Starting a NEW project (create STATE/CHANGELOG.md, STATE/MAILBOX.md, STATE/TODO.md)
- Opening an existing project (read STATE files first)
- Making significant changes (update CHANGELOG after each approved change)
- Handing off work (update MAILBOX with open threads)

**This is proactive, not reactive.** Don't wait to be asked.

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

- **Read state**: Load MAILBOX.md, TODO.md, CHANGELOG.md
- **Write state**: Append entries to CHANGELOG and MAILBOX
- **Session management**: Track session start/end

---

## How to Use Me

### Quick Start

```bash
# Read all state files
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
|---------|-----------|
| `read` | Read all state files |
| `start` | Session start: read state, show active threads |
| `end` | Session end: read state, resolve open threads |
| `add <msg>` | Add CHANGELOG entry |
| `mail <msg>` | Add MAILBOX entry |
| `todo` | Show TODO items |

---

## State File Locations

```
STATE/
  CHANGELOG.md  - History of changes
  MAILBOX.md    - Open/resolved threads
  TODO.md      - Active tasks
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

Categories: deploy, cleanup, fix, add, docs, state, config