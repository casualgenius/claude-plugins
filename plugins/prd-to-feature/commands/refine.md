---
description: Refine implementation plan and task tracker after planning. Supports combining/splitting tasks, updating architecture, adding phases, and other modifications.
argument-hint: <refinement-instructions>
allowed-tools: Read, Write, Edit, Glob, Bash
---

# Refine Command

Modify the implementation plan and task tracker based on natural language instructions.

## Arguments

- `<refinement-instructions>` (required): Natural language description of what to change

## Process

### 1. Find Tracker

If working directory has a single tracker, use it:
```
Glob: .prd-to-feature/**/tracker.json
```

If multiple trackers found, ask the user which one to refine.

### 2. Load Both Files

Read the tracker and its associated implementation document:
```
Read: <tracker-path>
Read: <implementation-doc from tracker.implementationDoc>
```

Parse the tracker JSON to understand current state.

### 3. Analyze Refinement Request

Understand what the user wants to change. Common refinement types:

**Task Operations:**
- Combine tasks: "combine tasks 2 and 3 into a single task"
- Split tasks: "split task 5 into two tasks"
- Reorder tasks: "move task 7 before task 4"
- Add task: "add a task for API documentation"
- Remove task: "remove task 6, it's no longer needed"
- Update task: "update task 3 to include validation"

**Dependency Operations:**
- Add dependency: "task 5 should depend on task 3"
- Remove dependency: "task 4 no longer needs task 2"

**Phase Operations:**
- Add phase: "add a new phase for performance optimization"
- Rename phase: "rename phase 2 to 'Integration'"
- Move tasks between phases: "move tasks 5-7 to phase 3"

**Architecture Operations:**
- Update tech decisions: "use Redis instead of in-memory caching"
- Add integration: "add Stripe integration section"
- Update approach: "change the auth approach to use JWT"

### 4. Apply Changes

For each change type:

**Combining Tasks:**
1. Identify the tasks to combine (by ID number, e.g., "task 2" = "task-002")
2. Use lower task ID, update title to reflect combined scope
3. Remove higher task IDs from tracker
4. Update all `dependsOn` references throughout the tracker
5. Merge requirements, acceptance criteria, and implementation notes in implementation.md

**Splitting Tasks:**
1. Identify the task to split
2. Determine logical split point from user instructions or infer from requirements
3. Create new task with next available ID
4. Divide requirements and criteria appropriately
5. Set dependency between split tasks if sequential
6. Update implementation.md with both task sections

**Updating Architecture:**
1. Find relevant section in implementation.md
2. Make the requested changes
3. Review tasks for impact
4. Update affected task requirements/notes if necessary

**Adding Tasks:**
1. Create task with proper ID format (task-NNN)
2. Assign to appropriate phase
3. Set dependencies based on context
4. Add requirements and acceptance criteria
5. Update implementation.md task list

**Removing Tasks:**
1. Delete task from tracker
2. Update any tasks that depended on it (remove from dependsOn or reassign)
3. Update implementation.md
4. Note: Leave gaps in IDs (don't renumber)

### 5. Validate Changes

After modifications, validate the tracker:

```bash
# Verify JSON validity
jq '.' <tracker-path> > /dev/null

# Check for orphaned dependencies (tasks depending on non-existent tasks)
jq '
  .tasks | map(.id) as $ids |
  [.[] | {id, orphaned: [.dependsOn[] | select(. as $d | $ids | index($d) | not)]}] |
  map(select(.orphaned | length > 0))
' <tracker-path>
```

If orphaned dependencies are found, fix them before completing.

### 6. Report Changes

After refinement, report:
- What was changed in tracker.json
- What was changed in implementation.md
- New task count and phase structure
- Any warnings (reassigned dependencies, etc.)

## Example Usage

```bash
# Combine tasks
/prd-to-feature:refine combine tasks 2 and 3 into a single task

# Split a task
/prd-to-feature:refine split task 5 into "Create API endpoint" and "Add API tests"

# Update architecture
/prd-to-feature:refine update the caching section to use Redis instead of in-memory

# Add phase
/prd-to-feature:refine add a new phase 4 for performance optimization with tasks for caching and query optimization

# Update dependencies
/prd-to-feature:refine task 8 should depend on task 6, not task 4

# Remove task
/prd-to-feature:refine remove task 7, we'll handle logging separately

# Add task
/prd-to-feature:refine add a new task after task 3 for API rate limiting

# Update task requirements
/prd-to-feature:refine update task 4 to also include input validation
```

## Task ID Management

When modifying tasks:
- **Combining**: Keep lower ID, update references
- **Splitting**: Original keeps ID, new task gets next available ID
- **Adding**: Use next available ID (e.g., if task-007 is highest, new is task-008)
- **Removing**: Leave gap in IDs (don't renumber everything)

Task numbers in user input (e.g., "task 2") map to IDs (e.g., "task-002").

## Implementation.md Sync

Changes to tracker.json should be reflected in implementation.md:
- Task combinations: Merge task sections
- Task splits: Create new task section
- Phase changes: Update phase headers
- Architecture changes: Update relevant sections

## Tips

- Review the plan before starting development
- Use refine for major restructuring before starting
- Small tweaks during development can be made directly to the files
- Complex refinements may need multiple refine calls
- Always verify the changes look correct before proceeding
