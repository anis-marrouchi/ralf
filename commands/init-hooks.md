---
description: "Initialize Ralf lifecycle hooks with essential boilerplate"
argument-hint: "[--force]"
---

# Initialize Ralf Hooks

Create the `.ralf/hooks/` directory with boilerplate hook scripts for lifecycle events.

## The Job

1. Create `.ralf/` directory structure if it doesn't exist
2. Generate `.ralf/.gitignore` to exclude runtime artifacts
3. Generate boilerplate for each lifecycle hook
4. Make scripts executable
5. Skip existing files unless `--force` is passed

## Execute

```bash
mkdir -p .ralf/hooks
```

## Create .gitignore

Create `.ralf/.gitignore` to exclude runtime state:

```gitignore
# Ralf runtime artifacts (should not be committed)
state.json
metrics.jsonl

# Keep these tracked:
# prd.json
# progress.txt
# config.json
# hooks/
```

## Hook Files to Create

Create the following three hook files:

### 1. `.ralf/hooks/on-task-start.sh`

```bash
#!/bin/bash
# Ralf Lifecycle Hook: on_task_start
# Triggered: Before story-executor spawns
#
# Context (JSON via stdin):
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "branch": "ralf/user-auth",
#   "iteration": 1,
#   "priority": 1,
#   "acceptanceCriteria": ["...", "..."]
# }
#
# Example: Update GitHub issue
#   ISSUE=$(echo "$CONTEXT" | jq -r '.storyId' | grep -oE '[0-9]+')
#   [ -n "$ISSUE" ] && gh issue edit "$ISSUE" --add-label "in-progress"

set -e

CONTEXT=$(cat)
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
TITLE=$(echo "$CONTEXT" | jq -r '.title')

echo "[on_task_start] $STORY_ID: $TITLE"
```

### 2. `.ralf/hooks/on-task-completed.sh`

```bash
#!/bin/bash
# Ralf Lifecycle Hook: on_task_completed
# Triggered: After story passes all checks
#
# Context (JSON via stdin):
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "commitHash": "abc123",
#   "filesChanged": ["src/auth.ts"],
#   "metrics": {
#     "startedAt": "2024-01-15T10:30:00Z",
#     "completedAt": "2024-01-15T10:45:00Z",
#     "durationMs": 900000,
#     "tokensConsumed": 45000
#   }
# }
#
# Example: Close GitHub issue with summary
#   ISSUE=$(echo "$CONTEXT" | jq -r '.storyId' | grep -oE '[0-9]+')
#   DURATION=$(($(echo "$CONTEXT" | jq -r '.metrics.durationMs') / 1000))
#   [ -n "$ISSUE" ] && gh issue close "$ISSUE" --comment "Done in ${DURATION}s"

set -e

CONTEXT=$(cat)
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
TITLE=$(echo "$CONTEXT" | jq -r '.title')

echo "[on_task_completed] $STORY_ID: $TITLE"
```

### 3. `.ralf/hooks/on-task-blocked.sh`

```bash
#!/bin/bash
# Ralf Lifecycle Hook: on_task_blocked
# Triggered: After max retries exceeded
#
# Context (JSON via stdin):
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "blockedReason": "Typecheck failed",
#   "retryCount": 3,
#   "errors": ["Error 1", "Error 2"]
# }
#
# Example: Add blocked label to GitHub issue
#   ISSUE=$(echo "$CONTEXT" | jq -r '.storyId' | grep -oE '[0-9]+')
#   REASON=$(echo "$CONTEXT" | jq -r '.blockedReason')
#   [ -n "$ISSUE" ] && gh issue edit "$ISSUE" --add-label "blocked"
#   [ -n "$ISSUE" ] && gh issue comment "$ISSUE" --body "Blocked: $REASON"

set -e

CONTEXT=$(cat)
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
REASON=$(echo "$CONTEXT" | jq -r '.blockedReason')

echo "[on_task_blocked] $STORY_ID: $REASON"
```

## After Creating

Make all hooks executable:

```bash
chmod +x .ralf/hooks/*.sh
```

## Verification

Test each hook with sample data:

```bash
echo '{"storyId":"US-001","title":"Test"}' | .ralf/hooks/on-task-start.sh
```

Expected output:
```
[on_task_start] US-001: Test
```

## Output

After creating hooks, inform the user:

```
Created .ralf/ structure:
  .ralf/
  ├── .gitignore           # Excludes state.json, metrics.jsonl
  └── hooks/
      ├── on-task-start.sh
      ├── on-task-completed.sh
      └── on-task-blocked.sh

Hooks log invocations by default. Edit to add integrations (GitHub, GitLab, Slack, etc.)
```

## .ralf/ Directory Structure

After full initialization, the `.ralf/` folder contains:

```
.ralf/
├── .gitignore        # Excludes runtime artifacts
├── prd.json          # PRD with user stories (tracked)
├── progress.txt      # Progress log (tracked)
├── config.json       # Project config (tracked, optional)
├── state.json        # Loop state (gitignored)
├── metrics.jsonl     # Metrics log (gitignored)
└── hooks/
    ├── on-task-start.sh
    ├── on-task-completed.sh
    └── on-task-blocked.sh
```
