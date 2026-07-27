---
description: Work through the tasks in a prd-to-feature tracker one at a time, spawning a developer agent per task and committing each as it completes.
argument-hint: "[tracker-path]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Agent, Bash
---

# Develop Command

Execute the development workflow from a task tracker, implementing tasks one at a time until none remain.

## Arguments

- `[tracker-path]` (optional): Path to `tracker.json`. If omitted, search `.prd-to-feature/**/tracker.json`.

## Setup

Let `TRACKER` be the tracker path and `T` be `${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh`.

1. **Find the tracker.** If no path was given, `Glob: .prd-to-feature/**/tracker.json`. If several match, ask the user which to use. If none, tell the user to run `/prd-to-feature:plan` first.
2. **Read the settings**, if present: `.claude/prd-to-feature.local.md`.
3. **Get the implementation doc path**: it is the `implementationDoc` field, visible in `$T summary "$TRACKER"`.

## Development Loop

**Sequential execution only.** Run one task-developer agent at a time and wait for it to return before selecting the next task. Do not run it in the background, and never spawn several in parallel — concurrent agents create conflicting edits, confuse each other with the other's lint and test failures, contend for dev servers and ports, and miss the notes each writes for the next task.

Repeat until no tasks remain or the user stops:

### a. Pick the next task

```bash
"$T" next "$TRACKER"
```

Returns a task id, or `none`. On `none`:

```bash
"$T" summary "$TRACKER"
```

If `blocked > 0`, run `"$T" blockers "$TRACKER"`, report them, and exit. If everything is `done`, report completion and exit. If tasks remain `todo` but none are available, report the dependency deadlock and exit.

### b. Gather the task's context

```bash
"$T" task    "$TRACKER" <task-id>
"$T" context <implementation-doc> <task-id>
```

`context` prints the Tech Stack and Architecture section followed by that task's section. Pass both through verbatim — do not summarize them for the agent.

### c. Launch the developer agent

Spawn the `prd-to-feature:task-developer` agent with the Agent tool, in the foreground. Its prompt must contain:

- The task JSON from step (b)
- The architecture section and the task section from step (b)
- The tracker path
- The helper script path (`${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh`)
- The project settings, if any

The agent implements the task, runs the project's verification checks, adds notes to related tasks, commits, marks the task `done`, and reports back.

### d. Handle the result

- **Complete** — continue to the next task.
- **Blocked** — the agent has already set the status to `blocked`; note it and continue to the next available task.
- **Error** — stop and report to the user.

### e. Report progress

After each task: which task finished or blocked, how many remain, and overall percentage.

## Completion

Report tasks completed this session, tasks remaining, blocked tasks, and the commits created.

## Unblocking a Task

A task the agent marked `blocked` is skipped by `tracker.sh next` and will not be retried automatically. Once the blocker is resolved, set it back to `todo` and re-run this command:

```bash
"$T" status "$TRACKER" <task-id> todo
```

## Example Usage

```bash
/prd-to-feature:develop
/prd-to-feature:develop .prd-to-feature/user-auth/tracker.json
```

## Tips

- Development continues automatically until all tasks are done; Ctrl+C stops after the current task.
- Each task runs in a fresh agent context, so there are no compaction problems on long features.
- The developer agent runs on Sonnet regardless of your session model. Change `model:` in `agents/task-developer.md` to override.
- `tracker.json` is workflow state and is never committed.
- Use `/prd-to-feature:status` to check progress, `/prd-to-feature:develop-ralph` for iterative refinement.
