---
description: "Check Ralf progress and prd.json status"
---

# Ralf Status

Display the current status of Ralf execution.

## Check These Items

1. **Ralf Loop State** - Check if `.ralf/state.json` exists
   - If exists: Show iteration count, max iterations, completion promise
   - If not: "No active Ralf loop"

2. **PRD Status** - Read `.ralf/prd.json` if it exists
   - Show project name and branch
   - List all user stories with their pass/fail status
   - Calculate completion percentage
   - Highlight the next story to work on (first with `passes: false`)

3. **Progress Log** - Check `.ralf/progress.txt` if it exists
   - Show the Codebase Patterns section if present
   - Show the last 2-3 entries

## Output Format

```
## Ralf Status

### Loop State
- Active: Yes/No
- Iteration: X of Y (or X, unlimited)
- Completion Promise: "COMPLETE"

### PRD Progress
Project: [name]
Branch: [branchName]

| ID     | Title                    | Status |
|--------|--------------------------|--------|
| US-001 | Add user authentication  | PASS   |
| US-002 | Create login page        | FAIL   | <-- Next
| US-003 | Add session management   | FAIL   |

Progress: 1/3 stories (33%)

### Recent Activity
[Last 2-3 entries from .ralf/progress.txt]

### Codebase Patterns
[Patterns section from .ralf/progress.txt if present]
```

## Commands Available

After showing status, remind the user:
- `/ralf` - Start or continue execution
- `/cancel-ralf` - Stop the loop
- `/prd` - Create a new PRD
- `/prd-to-json` - Convert PRD to prd.json
