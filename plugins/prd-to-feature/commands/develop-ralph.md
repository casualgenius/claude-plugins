---
description: Ralph loop variant of develop - iterates a developer agent over each task until the work stops being substantive, then moves on. Higher quality than a single pass, at higher cost.
argument-hint: "[max-iterations] [min-iterations] [tracker-path]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Agent, Bash
---

# Develop Ralph Command

Like `/prd-to-feature:develop`, but each task gets repeated passes from fresh developer agents until the changes stop being substantive. This "eventual consistency through iteration" approach catches edge cases a single pass misses.

## Arguments

Numbers are consumed in order; anything containing `/` or ending `.json` is the tracker path.

- `[max-iterations]` (optional): hard ceiling per task. Default **10**.
- `[min-iterations]` (optional): passes required before an early exit is allowed. Default **2**. Auto-capped to max.
- `[tracker-path]` (optional): path to `tracker.json`. If omitted, search `.prd-to-feature/**/tracker.json`.

## How the Loop Decides to Stop

Each iteration, the developer agent reports a **change class**:

- `substantive` — fixed a bug, implemented a missing requirement or acceptance criterion, added error handling, or added tests for one of those
- `polish` — in scope but marginal
- `none` — no commit made

The minimum of 2 guarantees at least one adversarial review pass even when the first pass looks complete. The exit condition then stops the loop as soon as iterations stop earning their cost, rather than grinding to the ceiling.

The agent is also under a **scope fence** from iteration 2 onward: only correctness, requirements, acceptance criteria, error handling, and test coverage justify a change. Anything else it notices gets recorded as a note on a related task instead of being implemented. Without that fence a capable model always finds one more thing to tidy, and the loop never converges.

## Setup

Let `TRACKER` be the tracker path, `T` be `${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh`, and `MAX`/`MIN` be the parsed iteration bounds (cap `MIN` to `MAX` if the user inverted them).

1. **Find the tracker.** If no path was given, `Glob: .prd-to-feature/**/tracker.json`. If several match, ask which. If none, tell the user to run `/prd-to-feature:plan` first.
2. **Read the settings**, if present: `.claude/prd-to-feature.local.md`.
3. **Get the implementation doc path** from `$T summary "$TRACKER"`.

## Development Loop

**Sequential execution only.** One task-developer agent at a time, in the foreground, awaited before the next. Never in parallel and never in the background.

Repeat until no tasks remain or the user stops:

### a. Pick the next task

```bash
"$T" next "$TRACKER"
```

On `none`, run `"$T" summary "$TRACKER"`: report blockers (`"$T" blockers "$TRACKER"`) or completion, and exit.

### b. Gather the task's context

```bash
"$T" task    "$TRACKER" <task-id>
"$T" context <implementation-doc> <task-id>
```

Pass both through verbatim.

### c. Run the ralph loop for this task

Resume from any persisted iteration, then loop. Track two values across iterations: `ITERATION` and `NON_SUBSTANTIVE` (a run-length count of consecutive non-substantive passes, starting at 0).

```bash
ITERATION=$("$T" task "$TRACKER" <task-id> | jq -r '.currentIteration // 1')
BEFORE_HEAD=$(git rev-parse HEAD)
```

Then repeat the following:

1. Report: `Task <task-id> - iteration {ITERATION}/{MAX} (min {MIN})`.

2. Spawn the `prd-to-feature:task-developer` agent in the foreground. Its prompt must contain everything the standard develop command passes — task JSON, architecture section, task section, tracker path, helper script path, settings — plus the ralph context:
   - `RALPH_MODE: true`
   - `ITERATION`, `MIN_ITERATIONS`, `MAX_ITERATIONS`

3. Determine this iteration's change class. Start from what the agent reported, then apply the objective backstop:

   ```bash
   AFTER_HEAD=$(git rev-parse HEAD)
   [ "$BEFORE_HEAD" = "$AFTER_HEAD" ] || git diff --shortstat "$BEFORE_HEAD".."$AFTER_HEAD"
   ```

   - HEAD unchanged → the class is `none`, whatever the agent claimed.
   - HEAD changed but the diff totals under ~10 lines → downgrade to `polish`.
   - Otherwise take the agent's reported class.

   The backstop exists because an agent that wants to keep working can label a two-line comment fix `substantive`.

4. Update the counters. If the class is `substantive`, reset `NON_SUBSTANTIVE` to 0; otherwise increment it. Set `BEFORE_HEAD=$AFTER_HEAD`.

5. Decide whether to stop. **Exit when any of these holds:**

   - `NON_SUBSTANTIVE >= 2` and `ITERATION >= MIN` — diminishing returns; two consecutive passes earned nothing.
   - The class is `none` and `ITERATION >= MIN` — the agent found nothing at all to do.
   - `ITERATION >= MAX` — the ceiling.

   On exit, mark the task done and clear the resume state:

   ```bash
   "$T" done "$TRACKER" <task-id>
   ```

   If the ceiling was what stopped it, say so explicitly in the report: *"task-00N hit the iteration ceiling (MAX) and was marked done without a clean stabilising pass — review manually."* The final iteration's changes were never reviewed by a subsequent pass.

6. Otherwise continue: increment `ITERATION`, persist it so an interrupted session resumes in the right place, and go back to step 1.

   ```bash
   "$T" iter "$TRACKER" <task-id> $ITERATION
   ```

### d. Handle the result

- **Stable or ceiling** — continue to the next task.
- **Blocked** — the agent has already set the status to `blocked` and cleared the iteration; note it and continue.
- **Error** — stop and report.

### e. Report progress

Per task: iterations taken, why the loop stopped, tasks remaining, overall percentage.

## Completion

Report tasks completed, average iterations per task, any that hit the ceiling, tasks remaining, blocked tasks, and commits created.

## Unblocking a Task

A `blocked` task is skipped by `tracker.sh next`. Once resolved:

```bash
"$T" status "$TRACKER" <task-id> todo
```

## Example Usage

```bash
# Defaults: max 10, min 2, auto-discover tracker
/prd-to-feature:develop-ralph

# Cap at 5 iterations
/prd-to-feature:develop-ralph 5

# Max 5, min 3
/prd-to-feature:develop-ralph 5 3

# Defaults with an explicit tracker
/prd-to-feature:develop-ralph .prd-to-feature/user-auth/tracker.json
```

## Tips

- The ceiling of 10 is a safety valve, not a target — most tasks stop after 2-4 iterations on the diminishing-returns rule.
- Lower `max` for simple features where you want a hard cost bound.
- Each iteration gets fresh agent context, so quality does not decay over a long task.
- **Session recovery**: if interrupted, re-running resumes from the saved iteration.
- Commits accumulate in the task's `commits` array, one per iteration, so you can review how the work evolved.
- Out-of-scope improvements land as notes on other tasks — worth reading before the next task starts.
- Use `/prd-to-feature:status` to check progress.

## Comparison with Standard Develop

| Aspect | `/develop` | `/develop-ralph` |
|--------|-----------|------------------|
| Iterations per task | 1 | Min 2, ceiling 10 (default) |
| Exit condition | Agent returns | Two consecutive non-substantive passes, or the ceiling |
| Task completion | Agent marks done | Loop marks done once stable |
| Commit tracking | One entry | One entry per iteration |
| Cost | Lower | Higher |
| Use case | Quick iteration | Thorough implementation |
