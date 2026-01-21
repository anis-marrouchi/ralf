# Ralf

**R**ecursive **A**gent **L**oop **F**ramework - A Claude Code plugin for PRD-driven autonomous development inspired by [Recursive Language Models](https://arxiv.org/pdf/2512.24601).

Ralf executes user stories iteratively, managing the full development lifecycle from requirements to implementation using recursive self-invocation for complex task decomposition.

## Features

- **PRD Generation**: Create structured Product Requirements Documents
- **PRD-to-JSON Conversion**: Convert PRDs to executable format
- **Autonomous Execution**: Spawn specialized agents to implement stories
- **Lifecycle Hooks**: Integrate with GitHub/GitLab issue trackers
- **Metrics Tracking**: Track time and token usage per story
- **Self-Evaluation**: Adaptive loop optimization with story reordering
- **Progress Tracking**: Maintain progress logs with learnings

## Installation

Clone and copy to your Claude Code plugins directory:

```bash
git clone https://github.com/anis-marrouchi/ralf.git
mkdir -p ~/.claude/plugins/marketplaces/local
cp -r ralf ~/.claude/plugins/marketplaces/local/
```

### Verify Installation

Restart Claude Code and check that Ralf commands are available:

```bash
claude
# Then type /prd to see if the command is recognized
```

## Quick Start

```bash
# 1. Create a PRD
/prd Add user authentication to the app

# 2. Convert to executable format
/prd-to-json tasks/prd-user-auth.md

# 3. Initialize hooks (optional)
/init-hooks

# 4. Start autonomous execution
/ralf

# 5. Monitor progress
/ralf-status
```

## Commands

| Command | Description |
|---------|-------------|
| `/prd` | Generate a Product Requirements Document |
| `/prd-to-json` | Convert PRD markdown to `.ralf/prd.json` |
| `/ralf` | Start autonomous execution |
| `/ralf-status` | Check current progress |
| `/cancel-ralf` | Stop the active loop |
| `/init-hooks` | Initialize lifecycle hooks with boilerplate |
| `/generate-pin` | Generate codebase index for context |

## Workflow

### 1. Create a PRD

```
/prd Add user authentication to the app
```

Ralf asks clarifying questions and generates a structured PRD in `tasks/prd-feature-name.md`.

### 2. Convert to prd.json

```
/prd-to-json tasks/prd-user-auth.md
```

Creates `.ralf/prd.json` with properly ordered user stories.

### 3. Initialize Hooks (Optional)

```
/init-hooks
```

Creates `.ralf/hooks/` with lifecycle hook boilerplate for GitHub/GitLab integration.

### 4. Start Execution

```
/ralf
```

The orchestrator will:
1. Read `.ralf/prd.json`
2. Fire `on_task_start` hook
3. Spawn `story-executor` agent
4. Track metrics (time, tokens)
5. Fire `on_task_completed` or `on_task_blocked` hook
6. Spawn `evaluator` agent (every N iterations)
7. Update `.ralf/prd.json` and `.ralf/progress.txt`
8. Repeat until all stories pass

### 5. Monitor Progress

```
/ralf-status
```

### 6. Stop if Needed

```
/cancel-ralf
```

## .ralf/ Directory Structure

All Ralf artifacts are stored in the `.ralf/` folder:

```
.ralf/
├── .gitignore        # Excludes runtime artifacts
├── prd.json          # PRD with user stories (tracked)
├── progress.txt      # Progress log (tracked)
├── config.json       # Project config (tracked, optional)
├── state.json        # Loop state (gitignored)
├── metrics.jsonl     # Metrics log (gitignored)
├── archive/          # Archived previous runs
└── hooks/
    ├── on-task-start.sh
    ├── on-task-completed.sh
    └── on-task-blocked.sh
```

## prd.json Format

```json
{
  "project": "MyApp",
  "branchName": "ralf/feature-name",
  "description": "Feature description",
  "settings": {
    "tddRequired": true,
    "executionMode": "sequential",
    "evaluatorEnabled": true,
    "maxRetries": 3
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "acceptanceCriteria": ["Criterion 1", "Typecheck passes"],
      "priority": 1,
      "passes": false,
      "targetFiles": ["src/auth.ts"],
      "specReference": "FR-1",
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

## Lifecycle Hooks

Hooks integrate with external issue trackers. Each receives JSON context via stdin.

| Hook | Trigger | Use Case |
|------|---------|----------|
| `on_task_start` | Before story execution | Add "in-progress" label |
| `on_task_completed` | After story passes | Close issue, add summary |
| `on_task_blocked` | After max retries | Add "blocked" label |

Example hook:
```bash
#!/bin/bash
CONTEXT=$(cat)
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
echo "[on_task_start] $STORY_ID"

# GitHub integration
# gh issue edit "$STORY_ID" --add-label "in-progress"
```

## Agents

| Agent | Color | Purpose |
|-------|-------|---------|
| `story-executor` | 🟢 Green | Implements a single user story |
| `rlm-processor` | 🟣 Purple | Analyzes large codebases (>50K tokens) |
| `evaluator` | 🩷 Pink | Evaluates loop performance, reorders stories |

## Story Sizing Guidelines

Each story should be completable in ONE iteration:

**Good (right-sized):**
- Add a database column
- Create a single component
- Implement one API endpoint

**Bad (too big):**
- "Build the dashboard" → split into schema, queries, UI, filters
- "Add authentication" → split into schema, middleware, login, sessions

## Options

```
/ralf [prd.json] [--max-iterations N] [--mode sequential|parallel]
```

- `--max-iterations`: Limit iterations (default: unlimited)
- `--mode`: Execution mode (default: sequential)

## Project Configuration

Create `.ralf/config.json` for project-specific settings:

```json
{
  "settings": {
    "tddRequired": true,
    "executionMode": "sequential",
    "evaluatorEnabled": true,
    "evaluateEveryNIterations": 3,
    "maxRetries": 3,
    "issueTracker": {
      "platform": "github",
      "autoUpdate": true
    }
  }
}
```

## Architecture

```
ralf/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/
│   ├── ralf.md               # Orchestrator
│   ├── prd.md                # PRD generation
│   ├── prd-to-json.md        # Conversion
│   ├── ralf-status.md        # Status check
│   ├── cancel-ralf.md        # Cancel loop
│   ├── init-hooks.md         # Initialize hooks
│   └── generate-pin.md       # Codebase index
├── skills/
│   ├── prd-generation/       # PRD quality guidance
│   ├── prd-to-json/          # Conversion rules
│   ├── story-execution/      # Implementation flow
│   ├── rlm-processing/       # Large context patterns
│   └── update-issue/         # Issue tracker integration
├── agents/
│   ├── story-executor.md     # Story implementation
│   ├── rlm-processor.md      # Codebase analysis
│   └── evaluator.md          # Loop optimization
├── hooks/
│   └── lifecycle-hooks.json  # Hook configuration
├── scripts/
│   ├── setup-ralf.sh         # Initialize state
│   └── ...
└── templates/
    ├── hook-on-task-start.sh
    ├── hook-on-task-completed.sh
    ├── hook-on-task-blocked.sh
    └── ralf-config.json
```

## RLM Processor

For large codebases (>50K tokens), the story-executor delegates to the **rlm-processor** agent. Based on [Recursive Language Models](https://arxiv.org/pdf/2512.24601), it treats context as an external environment.

### How It Works

1. Files loaded as `context` variable in Python REPL
2. Code filters and chunks context (regex, string ops)
3. `llm_query()` handles semantic analysis on filtered chunks
4. Results aggregated and returned as condensed findings

### Trigger Conditions

- Context exceeds 50K tokens
- Story touches >5 interconnected files
- Pattern discovery in unfamiliar codebase
- Cross-cutting concerns (auth, logging, errors)

## Inspiration

- [Recursive Language Models (RLMs)](https://arxiv.org/pdf/2512.24601)
- Geoffrey Huntley's autonomous agent loop patterns

## Contributing

Contributions welcome! Please ensure:
- Scripts are POSIX-compliant where possible
- Commands have clear help text
- Tests pass before submitting PRs

## Repository

[https://github.com/anis-marrouchi/ralf](https://github.com/anis-marrouchi/ralf)

## License

MIT
