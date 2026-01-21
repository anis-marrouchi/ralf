# Ralf

**R**ecursive **A**gent **L**oop **F**ramework - A Claude Code plugin for PRD-driven autonomous development inspired by [Recursive Language Models](https://arxiv.org/pdf/2512.24601).

Ralf executes user stories iteratively, managing the full development lifecycle from requirements to implementation using recursive self-invocation for complex task decomposition.

## Features

- **PRD Generation**: Create structured Product Requirements Documents
- **PRD-to-JSON Conversion**: Convert PRDs to executable prd.json format
- **Autonomous Execution**: Iteratively implement user stories
- **Progress Tracking**: Maintain progress logs with learnings
- **Auto-completion**: Automatically detect when all stories pass

## Installation

### Local Installation

Copy to your Claude plugins directory:

```bash
cp -r ralf ~/.claude/plugins/local/
```

### From npm (when published)

```bash
npm install -g ralf
```

## Commands

| Command | Description |
|---------|-------------|
| `/prd` | Generate a Product Requirements Document |
| `/prd-to-json` | Convert PRD markdown to prd.json |
| `/ralf` | Start autonomous execution |
| `/ralf-status` | Check current progress |
| `/cancel-ralf` | Stop the active loop |

## Workflow

### 1. Create a PRD

```
/prd Add user authentication to the app
```

Ralf will ask clarifying questions and generate a structured PRD in `tasks/prd-feature-name.md`.

### 2. Convert to prd.json

```
/prd-to-json tasks/prd-user-auth.md
```

This creates `prd.json` with properly ordered user stories.

### 3. Start Execution

```
/ralf
```

Ralf will:
1. Read prd.json
2. Pick the highest priority incomplete story
3. Implement and verify
4. Commit changes
5. Update prd.json
6. Log progress
7. Repeat until all stories pass

### 4. Monitor Progress

```
/ralf-status
```

Shows current iteration, story completion status, and recent activity.

### 5. Stop if Needed

```
/cancel-ralf
```

Stops the loop while preserving progress.

## prd.json Format

```json
{
  "project": "MyApp",
  "branchName": "ralf/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Story Sizing Guidelines

Each story should be completable in ONE iteration:

**Good (right-sized):**
- Add a database column
- Create a single component
- Implement one API endpoint

**Bad (too big):**
- "Build the dashboard" - split into schema, queries, UI, filters
- "Add authentication" - split into schema, middleware, login, sessions

## Completion Detection

The loop ends when:

1. **Auto-complete**: All stories have `passes: true`
2. **Explicit**: Claude outputs `<promise>COMPLETE</promise>`
3. **Max iterations**: If `--max-iterations` is set

## State Files

| File | Purpose |
|------|---------|
| `.claude/ralf-state.json` | Loop state (iteration, config) |
| `prd.json` | User stories and status |
| `progress.txt` | Progress log and learnings |

## Options

```
/ralf [prd.json] [--max-iterations N] [--completion-promise TEXT]
```

- `--max-iterations`: Limit iterations (default: unlimited)
- `--completion-promise`: Custom completion phrase (default: COMPLETE)

## Architecture

```
ralf/
├── .claude-plugin/
│   └── plugin.json         # Plugin manifest
├── commands/
│   ├── ralf.md             # Main execution command
│   ├── prd.md              # PRD generation
│   ├── prd-to-json.md      # Conversion command
│   ├── ralf-status.md      # Status check
│   └── cancel-ralf.md      # Cancel loop
├── skills/
│   ├── prd-generation/     # PRD creation guidance
│   ├── prd-to-json/        # Conversion guidance
│   ├── story-execution/    # Implementation guidance
│   └── rlm-processing/     # Large context processing guidance
├── agents/
│   ├── story-executor.md   # Focused story implementation
│   ├── code-reviewer.md    # Quality review
│   └── rlm-processor.md    # Large codebase analysis
├── hooks/
│   ├── hooks.json          # Hook configuration
│   └── stop-hook.sh        # Loop continuation logic
├── scripts/
│   ├── setup-ralf.sh       # Initialize state
│   ├── update-prd-status.sh # Update story status
│   ├── check-completion.sh # Check all stories done
│   └── rlm-repl.sh         # RLM Python REPL environment
└── templates/
    ├── prd.json.template   # PRD JSON template
    ├── progress-entry.md   # Progress log template
    └── rlm-system-prompt.md # RLM processor prompt template
```

## RLM Processor

For large codebases (>50K tokens), the story-executor can delegate to the **rlm-processor** agent. Based on the [Recursive Language Models paper](https://arxiv.org/pdf/2512.24601), it treats context as an external environment rather than loading it directly.

### How It Works

1. Files are loaded as a `context` variable in a Python REPL
2. Code filters and chunks the context (regex, string ops)
3. `llm_query()` handles semantic analysis on filtered chunks
4. Results are aggregated and returned as condensed findings

### When It Activates

- Context exceeds 50K tokens
- Story touches >5 interconnected files
- Pattern discovery across unfamiliar codebase
- Cross-cutting concerns (auth, logging, error handling)

### Manual Usage

```bash
./scripts/rlm-repl.sh "src/**/*.ts" "Find all API endpoints"
```

## Inspiration

Ralf is inspired by:
- [Recursive Language Models (RLMs)](https://arxiv.org/pdf/2512.24601) - Framework for recursive task decomposition
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
