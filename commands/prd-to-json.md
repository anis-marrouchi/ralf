---
description: "Convert a PRD markdown file to prd.json for Ralf execution"
argument-hint: "[prd file path]"
allowed-tools: ["Skill(ralf:prd-to-json)"]
---

# PRD to JSON Converter

## Pre-execution

Before starting, invoke the skill for expert guidance:

Use the Skill tool:
- skill: "ralf:prd-to-json"

This provides the JSON schema, dependency ordering rules, and validation checklist.

---

Converts existing PRDs to the prd.json format that Ralf uses for autonomous execution.

## The Job

Take a PRD (markdown file path from arguments, or find recent PRD in `tasks/`) and convert it to `prd.json`.

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralf/[feature-name-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "settings": {
    "tddRequired": true,
    "autoPush": true,
    "executionMode": "sequential",
    "evaluatorEnabled": true,
    "allowReorder": true,
    "evaluateEveryNIterations": 3,
    "maxRetries": 3
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "",
      "targetFiles": ["src/path/to/file.ts"],
      "specReference": "FR-1, FR-2",
      "metrics": {
        "startedAt": null,
        "completedAt": null,
        "durationMs": null,
        "tokensConsumed": null,
        "attempts": []
      }
    }
  ]
}
```

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralf iteration (one context window).**

Ralf spawns fresh for each iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic

### Too big (split these):
- "Build the entire dashboard" - Split into: schema, queries, UI components, filters
- "Add authentication" - Split into: schema, middleware, login UI, session handling

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

## Acceptance Criteria: Must Be Verifiable

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"

### Always include as final criterion:
```
"Typecheck passes"
```

## Conversion Rules

1. **Each user story becomes one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `ralf/`
6. **Always add**: "Typecheck passes" to every story's acceptance criteria
7. **targetFiles**: Identify likely files to be created/modified (scan codebase)
8. **specReference**: Link to functional requirements (e.g., "FR-1, FR-2")
9. **metrics**: Initialize with null values and empty attempts array
10. **settings**: Include project-level settings for execution behavior

## Archiving Previous Runs

**Before writing a new prd.json, check if there is an existing one from a different feature:**

1. Read the current `prd.json` if it exists
2. Check if `branchName` differs from the new feature's branch name
3. If different AND `progress.txt` has content beyond the header:
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.txt` to archive
   - Reset `progress.txt` with fresh header

## Output Location

Save to: `prd.json` (root of project)

## After Conversion

After saving prd.json, inform the user:
"prd.json created with [N] user stories. Run `/ralf` to start autonomous execution."

## Checklist Before Saving

- [ ] **Previous run archived** (if prd.json exists with different branchName)
- [ ] Each story is completable in one iteration (small enough)
- [ ] Stories are ordered by dependency (schema to backend to UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] **targetFiles** populated for each story (scan codebase)
- [ ] **specReference** links stories to functional requirements
- [ ] **metrics** object initialized with null values
- [ ] **settings** section includes project preferences
