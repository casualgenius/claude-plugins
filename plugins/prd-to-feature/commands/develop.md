---
description: Start or continue feature development from a task tracker. Automatically picks tasks, spawns developer agents, and commits completed work until all tasks are done.
argument-hint: [tracker-path]
allowed-tools: Read, Write, Glob, Grep, Task, Bash
---

# Develop Command

Execute the development workflow from a task tracker, implementing tasks one by one until complete.

## Arguments

- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.prd-to-feature/`

## Process

### 1. Find Tracker

If no path provided, search for trackers in the `.prd-to-feature` directory:
```
Glob: .prd-to-feature/**/tracker.json
```

Trackers are stored at `.prd-to-feature/{feature-name}/tracker.json`.

If multiple trackers found, ask the user which one to use.

### 2. Load Context

Read the tracker and implementation document:
```
Read: <tracker-path>
Read: <implementation-doc-path from tracker>
```

Also check for project settings:
```
Read: .claude/prd-to-feature.local.md
```

### 3. Development Loop

**IMPORTANT: Sequential Execution Only**

You MUST execute tasks ONE AT A TIME. Never spawn multiple task-developer agents in parallel, even if tasks appear independent:
- Multiple agents may create conflicting changes
- Lint/test errors from one agent may confuse another
- Resource conflicts (dev servers, ports, processes) cause failures
- Task notes from one agent may be relevant to the next

Wait for each task-developer agent to complete before selecting the next task.

Repeat until no tasks remain or user stops:

#### a. Query Task Status

**Important**: Use `jq` to efficiently query task statuses instead of reading the full tracker:

```bash
# Get minimal task data: id, status, dependsOn
jq '[.tasks[] | {id, status, dependsOn}]' <tracker-path>
```

This reduces token usage from ~2000 tokens (full read) to ~200 tokens (status query).

The task-developer agent updates the tracker after completing each task. Re-querying ensures you see the latest task statuses and can correctly identify which dependencies are now satisfied.

#### b. Pick Next Task

Use `jq` to find the next task based on priority:

```bash
# Find next task: in-progress > testing > available todo
jq -r '
  .tasks as $all |
  (
    # Priority 1: in-progress
    ($all[] | select(.status == "in-progress") | .id) //
    # Priority 2: testing
    ($all[] | select(.status == "testing") | .id) //
    # Priority 3: first available todo (dependencies met)
    ($all[] |
      select(.status == "todo") |
      select(.dependsOn | length == 0 or all(. as $dep | $all[] | select(.id == $dep) | .status == "done")) |
      .id
    ) //
    "none"
  ) | if type == "array" then first else . end
' <tracker-path>
```

If result is "none":
```bash
# Check for blocked tasks
jq '[.tasks[] | select(.status == "blocked")] | length' <tracker-path>
# Check for done count
jq '[.tasks[] | select(.status == "done")] | length' <tracker-path>
```
- If blocked tasks exist: Report blockers and exit
- If all done: Report completion and exit

#### c. Extract Task Context

Once you have the task ID, extract only that task's details:

```bash
# Get full details for specific task
jq --arg id "<task-id>" '.tasks[] | select(.id == $id)' <tracker-path>
```

**Extract only the relevant task section** from the Implementation document (do NOT read the full file):

```bash
# Find the line number where this task's section starts using the task ID (e.g., task-001)
# The implementation doc uses format: #### task-001: {Title}
START_LINE=$(grep -n "^#### <task-id>:" <implementation-doc-path> | head -1 | cut -d: -f1)

# Find the next section boundary (next #### or ### heading)
END_LINE=$(tail -n +$((START_LINE + 1)) <implementation-doc-path> | grep -n "^###" | head -1 | cut -d: -f1)
if [ -n "$END_LINE" ]; then
  END_LINE=$((START_LINE + END_LINE - 1))
else
  # If no next section found, read ~50 lines
  END_LINE=$((START_LINE + 50))
fi
```

Then use the **Read tool with offset and limit** parameters:
- `offset`: START_LINE
- `limit`: END_LINE - START_LINE

This reads only the ~20-50 lines relevant to this task instead of the entire implementation document.

Also extract project settings (if available)

#### d. Launch Task Developer Agent

Use the Task tool with subagent_type to spawn prd-to-feature:task-developer:

```
Task: prd-to-feature:task-developer agent
Prompt:
  - Task ID and details
  - Implementation context
  - Tracker path (for updates)
  - Project settings
```

The agent will:
1. Implement the task
2. Run all verification checks
3. Add notes to related tasks
4. Commit the changes
5. Return status (complete, blocked, or error)

#### e. Handle Result

- **Complete**: Continue to next task
- **Blocked**: Note the blocker, continue to next available task
- **Error**: Stop and report to user

#### f. Report Progress

After each task, briefly report:
- Task completed/blocked
- Tasks remaining
- Overall progress percentage

### 4. Completion

When loop ends, report:
- Total tasks completed this session
- Tasks remaining (if any)
- Blocked tasks (if any)
- Git commits created

## Example Usage

```bash
# With explicit path
/prd-to-feature:develop .prd-to-feature/user-auth/tracker.json

# Auto-discover tracker
/prd-to-feature:develop
```

## Stopping Development

Press Ctrl+C to stop the development loop at any time. The current task will complete before stopping.

## Task Selection Logic

```
Available tasks = tasks where:
  - status is 'todo' AND
  - all dependsOn tasks have status 'done'

Next task = first of:
  1. Any task with status 'in-progress'
  2. Any task with status 'testing'
  3. First available 'todo' task
```

## Tips

- Development continues automatically until all tasks are done
- Each task runs in a fresh agent context (no context compaction issues)
- Blocked tasks are skipped and can be retried later
- Use `/prd-to-feature:status` to check progress
- All commits include the updated tracker file
