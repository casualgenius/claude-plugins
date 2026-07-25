---
description: Ralph loop variant of develop - iterates on each task until stable. Spawns developer agents repeatedly until no more changes are made, ensuring higher quality through multiple passes.
argument-hint: [iterations] [tracker-path]
allowed-tools: Read, Write, Glob, Grep, Task, Bash
---

# Develop Ralph Command

Execute the development workflow with Ralph loop support. Each task is iterated until no changes are detected (via git commit comparison), ensuring higher quality through multiple refinement passes.

## Arguments

- `[max-iterations]` (optional): Maximum iterations per task, default 3
- `[min-iterations]` (optional): Minimum iterations before allowing early exit, default 2
- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.prd-to-feature/`

**Argument parsing**:
- Numbers are parsed in order: first number → max iterations, second number → min iterations
- Paths are detected by containing `/` or ending in `.json`
- Min iterations cannot exceed max iterations (auto-capped)

## How Ralph Loop Works

For each task, instead of a single agent invocation:

1. Record current git HEAD
2. Spawn task-developer agent with ralph context (iteration number, min/max)
3. After agent completes, compare git HEAD
4. If HEAD changed (commits made) → iterate again with fresh agent
5. If HEAD unchanged but below MIN_ITERATIONS → force another iteration
6. If HEAD unchanged AND min iterations met → task is stable, mark done
7. If max iterations reached → mark done and move on

Key differences from standard develop:
- **Minimum iterations (default 2)**: Ensures at least one review pass even if first looks complete
- **Task completion controlled by loop**: Agent keeps status as "in-progress", loop marks "done" when stable
- **Commits tracked as array**: Each iteration's commit is recorded with iteration number
- **Session recovery**: Current iteration is persisted in tracker, so interrupted sessions resume from where they left off

This "eventual consistency through iteration" approach catches edge cases, improves code quality, and ensures thorough implementation.

## Process

### 1. Parse Arguments

Determine iterations and tracker path from arguments:

```bash
# Default values
MAX_ITERATIONS=3
MIN_ITERATIONS=2
TRACKER_PATH=""
NUM_COUNT=0

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    if [ "$NUM_COUNT" -eq 0 ]; then
      MAX_ITERATIONS="$arg"
    else
      MIN_ITERATIONS="$arg"
    fi
    NUM_COUNT=$((NUM_COUNT + 1))
  else
    TRACKER_PATH="$arg"
  fi
done

# Ensure min doesn't exceed max
if [ "$MIN_ITERATIONS" -gt "$MAX_ITERATIONS" ]; then
  MIN_ITERATIONS="$MAX_ITERATIONS"
fi
```

### 2. Find Tracker

If no path provided, search for trackers in the `.prd-to-feature` directory:
```
Glob: .prd-to-feature/**/tracker.json
```

Trackers are stored at `.prd-to-feature/{feature-name}/tracker.json`.

If multiple trackers found, ask the user which one to use.

### 3. Load Context

Read the tracker and implementation document:
```
Read: <tracker-path>
Read: <implementation-doc-path from tracker>
```

Also check for project settings:
```
Read: .claude/prd-to-feature.local.md
```

### 4. Development Loop with Ralph

**IMPORTANT: Sequential Execution Only**

You MUST execute tasks ONE AT A TIME. Never spawn multiple task-developer agents in parallel.

Repeat until no tasks remain or user stops:

#### a. Query Task Status

**Important**: Use `jq` to efficiently query task statuses instead of reading the full tracker:

```bash
# Get minimal task data: id, status, dependsOn
jq '[.tasks[] | {id, status, dependsOn}]' <tracker-path>
```

This reduces token usage from ~2000 tokens (full read) to ~200 tokens (status query).

#### b. Pick Next Task

Use `jq` to find the next task based on priority:

```bash
# Find next task: in-progress > available todo
jq -r '
  .tasks as $all |
  (
    # Priority 1: in-progress
    ($all[] | select(.status == "in-progress") | .id) //
    # Priority 2: first available todo (dependencies met)
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

**Extract the Architecture section** from the Implementation document (provides context for all tasks):

```bash
# Find the Tech Stack and Architecture section
ARCH_START=$(grep -n "^## Tech Stack and Architecture" <implementation-doc-path> | head -1 | cut -d: -f1)
ARCH_END=$(tail -n +$((ARCH_START + 1)) <implementation-doc-path> | grep -n "^## " | head -1 | cut -d: -f1)
if [ -n "$ARCH_END" ]; then
  ARCH_END=$((ARCH_START + ARCH_END - 1))
else
  ARCH_END=$((ARCH_START + 50))
fi
```

Then use the **Read tool with offset and limit** to extract the Architecture section.

**Extract the specific task section** from the Implementation document:

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

#### d. Ralph Loop for Task

**This is the key difference from standard develop command.**

```
# Check if resuming from a previous session (currentIteration persisted in tracker)
SAVED_ITERATION=$(jq -r --arg id "<task-id>" '.tasks[] | select(.id == $id) | .currentIteration // 1' <tracker-path>)
ITERATION=$SAVED_ITERATION
BEFORE_HEAD=$(git rev-parse HEAD)

Report: "Starting task <task-id> at iteration {ITERATION}"

RALPH_LOOP:
  Report: "Task <task-id> - Iteration {ITERATION}/{MAX_ITERATIONS} (min: {MIN_ITERATIONS})"

  # Launch task-developer agent with ralph context
  Task: prd-to-feature:task-developer agent
  Prompt:
    - Task ID and details (from tracker)
    - Architecture section (tech stack, integration points, data flow)
    - Task section (requirements, acceptance criteria, implementation notes)
    - Tracker path (for updates)
    - Project settings
    - **Ralph mode context:**
      - RALPH_MODE: true
      - ITERATION: {current iteration number}
      - MIN_ITERATIONS: {MIN_ITERATIONS value}
      - MAX_ITERATIONS: {MAX_ITERATIONS value}

  # Check if changes were made
  AFTER_HEAD=$(git rev-parse HEAD)

  IF BEFORE_HEAD != AFTER_HEAD:
    # Changes were committed
    Report: "Iteration {ITERATION}: changes committed, continuing refinement..."
    BEFORE_HEAD=$AFTER_HEAD
    ITERATION++

    IF ITERATION > MAX_ITERATIONS:
      Report: "Max iterations ({MAX_ITERATIONS}) reached for task <task-id>"
      # Mark task as done and clear currentIteration
      jq --arg id "<task-id>" '
        .tasks |= map(if .id == $id then .status = "done" | del(.currentIteration) else . end)
      ' <tracker-path> > <tracker-path>.tmp && mv <tracker-path>.tmp <tracker-path>
      BREAK
    ELSE:
      # Persist iteration for session recovery
      jq --arg id "<task-id>" --argjson iter "$ITERATION" '
        .tasks |= map(if .id == $id then .currentIteration = $iter else . end)
      ' <tracker-path> > <tracker-path>.tmp && mv <tracker-path>.tmp <tracker-path>
      CONTINUE RALPH_LOOP
  ELSE:
    # No changes made this iteration
    IF ITERATION < MIN_ITERATIONS:
      # Haven't met minimum iterations yet - force another pass
      Report: "Iteration {ITERATION}: No changes, but minimum iterations ({MIN_ITERATIONS}) not reached. Continuing..."
      ITERATION++
      # Persist iteration for session recovery
      jq --arg id "<task-id>" --argjson iter "$ITERATION" '
        .tasks |= map(if .id == $id then .currentIteration = $iter else . end)
      ' <tracker-path> > <tracker-path>.tmp && mv <tracker-path>.tmp <tracker-path>
      CONTINUE RALPH_LOOP
    ELSE:
      # Met minimum iterations AND no changes = task is stable
      Report: "Task <task-id> stable after {ITERATION} iteration(s)"
      # Mark task as done and clear currentIteration
      jq --arg id "<task-id>" '
        .tasks |= map(if .id == $id then .status = "done" | del(.currentIteration) else . end)
      ' <tracker-path> > <tracker-path>.tmp && mv <tracker-path>.tmp <tracker-path>
      BREAK
```

#### e. Handle Result

After ralph loop completes for a task:
- **Complete**: Continue to next task
- **Blocked**: Note the blocker, continue to next available task
- **Error**: Stop and report to user

#### f. Report Progress

After each task completes its ralph loop, briefly report:
- Task completed/blocked
- Number of iterations taken
- Tasks remaining
- Overall progress percentage

### 5. Completion

When loop ends, report:
- Total tasks completed this session
- Average iterations per task
- Tasks remaining (if any)
- Blocked tasks (if any)
- Git commits created

## Example Usage

```bash
# Default: 3 max, 2 min iterations, auto-discover tracker
/prd-to-feature:develop-ralph

# 5 max iterations (2 min default), auto-discover tracker
/prd-to-feature:develop-ralph 5

# 5 max iterations, 3 min iterations
/prd-to-feature:develop-ralph 5 3

# Default iterations, explicit path
/prd-to-feature:develop-ralph .prd-to-feature/user-auth/tracker.json

# 5 max, 3 min iterations with explicit path
/prd-to-feature:develop-ralph 5 3 .prd-to-feature/user-auth/tracker.json
```

## Stopping Development

Press Ctrl+C to stop the development loop at any time. The current iteration will complete before stopping.

## Task Selection Logic

```
Available tasks = tasks where:
  - status is 'todo' AND
  - all dependsOn tasks have status 'done'

Next task = first of:
  1. Any task with status 'in-progress'
  2. First available 'todo' task
```

## Tips

- Default is 3 max, 2 min iterations - increase max for complex tasks
- The minimum of 2 iterations ensures thorough review even when first pass looks complete
- Each iteration gets fresh agent context (no context compaction issues)
- Task is only marked "done" after meeting min iterations AND no changes detected
- **Session recovery**: If compacted/interrupted, re-running resumes from the saved iteration
- Blocked tasks are skipped and can be retried later
- Use `/prd-to-feature:status` to check progress
- Commits are tracked in an array, allowing review of work across iterations

## Comparison with Standard Develop

| Aspect | `/develop` | `/develop-ralph` |
|--------|-----------|------------------|
| Iterations per task | 1 | Min 2, up to N (default 3) |
| Exit condition | Agent returns | No changes after min iterations |
| Task completion | Agent marks done | Loop marks done after stable |
| Commit tracking | Single hash | Array of {hash, iteration, timestamp} |
| Cost | Lower | Higher (more invocations) |
| Quality | Good | Higher (iterative refinement) |
| Use case | Quick iteration | Thorough implementation |
