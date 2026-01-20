---
name: prd-to-json
description: "Convert PRD markdown files to prd.json format for Ralf execution. Use when preparing PRDs for autonomous implementation."
---

# PRD to JSON Conversion Skill

Expert guidance for converting PRDs to Ralf's executable JSON format.

## When to Use

- User has a PRD and wants to run Ralf
- User mentions "convert to json" or "prd.json"
- After generating a PRD, to prepare for execution

## JSON Schema

```json
{
  "project": "string",
  "branchName": "ralf/feature-name",
  "description": "string",
  "userStories": [
    {
      "id": "US-001",
      "title": "string",
      "description": "As a..., I want..., so that...",
      "acceptanceCriteria": ["string"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Conversion Rules

1. **Branch Naming**: `ralf/` prefix + kebab-case feature name
2. **Story IDs**: Sequential US-001, US-002, etc.
3. **Priority**: Based on dependency order (1 = first to implement)
4. **Initial State**: All `passes: false`, empty `notes`
5. **Acceptance Criteria**: Always end with "Typecheck passes"

## Dependency Ordering

Priority must respect dependencies:

1. Database/schema changes
2. Backend logic/server actions
3. UI components
4. Integration/dashboard views

A story cannot depend on a later (higher priority number) story.

## Story Size Validation

Before conversion, validate each story is small enough:

- Can be described in 2-3 sentences
- Touches limited number of files
- Has clear start and end point
- No "and then also..." scope creep

## Archive Check

Before overwriting existing prd.json:

1. Check if existing prd.json has different branchName
2. If yes, archive to `archive/YYYY-MM-DD-feature-name/`
3. Include both prd.json and progress.txt

## Output

Save to project root: `prd.json`
