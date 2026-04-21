# Moe State Changelog

History of changes to Moe (Larry's coding partner agent).

## 2026-04-10

### 2026-04-10T18:29:00Z [analysis]: Discovered Moe vs OpenCoder capabilities
- Compared agent personas and formal workflows
- Moe: persona-based, direct execution, 3-7 next steps default
- OpenCoder: formal workflow, subagent delegation, task management
- Delegation test: Moe CAN invoke subagents via task() tool

### 2026-04-10T18:45:00Z [state]: Created STATE files for Moe
- Created /home/lfarrell/.opencode/agent/core/STATE/
- CHANGELOG.md, TODO.md, MAILBOX.md

## 2026-04-17

### 2026-04-17T19:20:00Z [add]: Created project-ideas skill
- New skill to manage project ideas from `.opencode/agent/core/Project ideas/`
- Commands: list, queue, scan, status, priority, category
- Imported 22 project ideas from Decision Fatigue Killers.md

### 2026-04-17T19:25:00Z [add]: Added project name + init command
- Added `project_name` field for friendly names
- Added `init` command to set project name + status in one step
- Fixed partial matching for unicode quote handling
- Documented this session
- TODO: Add git + worktrees for concurrent windows

### 2026-04-10T18:50:00Z [architecture]: State architecture decision
- Decision: Hybrid model (CPU cache hierarchy analogy)
- TaskManager owns task truth (.tmp/tasks/*.json)
- Agents own local context (scratch files)
- Interface-based communication
- No single state agent (too coupled)

### 2026-04-10T18:50:00Z [sync]: This session documented
- Delegation works - Moe can invoke subagents
- Moe cons: no TaskManager, no parallel exec (mitigable)
- OpenCoder: overkill for simple tasks
- State: hybrid model selected

### 2026-04-10T18:55:00Z [setup]: Git initialized in .opencode
- Initial commit b672b99 with all agent files + STATE
- First commit: agent definitions, context, skills, tool
- Ready for worktrees when multiple windows needed

### 2026-04-10T19:30:00Z [launch]: Create moe-launch.sh
- Adapted from zoe-launch.sh for OpenCode
- Uses PROJECTS.md (same as zoe)
- Creates worktrees with STATE/ and OPENCODE.md
- Runs 'opencode .' (Moe is default agent)
- Worktrees use ~/zoe/OPENCODE.md for identity

### 2026-04-10T19:45:00Z [refactor]: Moved OpenCoder and OpenAgent to subagents
- Changed mode: primary → subagent
- Added hidden: true (hidden from @ autocomplete)
  - Now Moe controls delegation to both
  - Location: .opencode/agent/core/*.md (still accessible to Moe via task())

### 2026-04-11T00:30:06Z [state]: Created sync skill
  - Reads and writes Moe state files
  - Enables proactive state tracking

### 2026-04-21T00:00:00Z [fix]: Moe state tracking failure on new project

- Problem: Started life-is-hard-planner but created docs/ instead of STATE/
- Root cause: Didn't recognize as "new project", planning vs tracking confusion
- Fix: Updated sync skill to emphasize proactive use
- Fix: Created STATE files for life-is-hard-planner after the fact
