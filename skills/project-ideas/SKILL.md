---
name: project-ideas
description: Manage and prioritize project ideas from the Project ideas folder
version: 1.0.0
author: moe
type: skill
category: ideas
tags:
  - projects
  - ideas
  - prioritization
  - roadmap
---

# Project Ideas Skill

> **Purpose**: Track, categorize, and prioritize project ideas from `.opencode/agent/core/Project ideas/`.

---

## What I Do

- **Scan** `.md` files in Project ideas folder and import ideas
- **List** all ideas with status, category, priority
- **Prioritize** reorder by priority to pick next project
- **Track** project status (idea → in-progress → done)

---

## How to Use Me

### Quick Start

```bash
# List all project ideas
bash .opencode/skills/project-ideas/runner.sh list

# Show priority queue (for picking next project)
bash .opencode/skills/project-ideas/runner.sh queue

# Scan for new ideas from .md files
bash .opencode/skills/project-ideas/runner.sh scan

# Update project status
bash .opencode/skills/project-ideas/runner.sh status "Project Name" in-progress
bash .opencode/skills/project-ideas/runner.sh status "Project Name" done

# Set priority (1 = highest)
bash .opencode/skills/project-ideas/runner.sh priority "Project Name" 3

# Set category
bash .opencode/skills/project-ideas/runner.sh category "Project Name" "life-organizaton"
```

### Command Reference

| Command | Description |
|---------|-----------|
| `list` | Show all ideas with status/priority |
| `queue` | Show priority queue (ready to work on) |
| `scan` | Import new ideas from .md files |
| `show <name>` | Show details for a project |
| `init <idea> <project-name>` | Create project from idea, set name + in-progress |
| `status <name> <status>` | Set status: idea, in-progress, done |
| `priority <name> <1-10>` | Set priority |
| `category <name> <cat>` | Set category |
| `projectname <name> <name>` | Set friendly project name |

### Status Values

- `idea` - Not started, just an idea
- `in-progress` - Currently being worked on
- `done` - Completed

---

## Data Location

```
.opencode/skills/project-ideas/
  projects.json  - All projects and their state
```