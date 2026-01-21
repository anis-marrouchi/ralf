---
description: "Initialize Ralf lifecycle hooks with essential boilerplate"
argument-hint: "[--force]"
---

# Initialize Ralf Hooks

Create the `.ralf/hooks/` directory with JavaScript hook scripts that use the Claude Agent SDK for intelligent lifecycle event handling.

## The Job

1. Create `.ralf/` directory structure if it doesn't exist
2. Generate `.ralf/.gitignore` to exclude runtime artifacts
3. Generate boilerplate for each lifecycle hook (JavaScript using Claude Agent SDK)
4. Create `package.json` with SDK dependency
5. Install dependencies
6. Make scripts executable
7. Skip existing files unless `--force` is passed

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

Create the following files:

### 1. `.ralf/hooks/package.json`

```json
{
  "name": "ralf-hooks",
  "type": "module",
  "private": true,
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "^0.1.0"
  }
}
```

### 2. `.ralf/hooks/on-task-start.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_start
 * Triggered: Before story-executor spawns
 *
 * Context (JSON via stdin):
 * {
 *   "storyId": "US-001",
 *   "title": "Add user authentication",
 *   "branch": "ralf/user-auth",
 *   "iteration": 1,
 *   "priority": 1,
 *   "acceptanceCriteria": ["...", "..."]
 * }
 *
 * Uses Claude Agent SDK (no separate API key required)
 */

import { query } from "@anthropic-ai/claude-agent-sdk";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: {
      allowedTools: [],
      maxTurns: 1,
    },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  // Read context from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, branch, iteration, priority, acceptanceCriteria } =
    context;

  console.log(`[on_task_start] ${storyId}: ${title}`);
  console.log(`  Branch: ${branch}`);
  console.log(`  Iteration: ${iteration}`);
  console.log(`  Priority: ${priority}`);

  // Use Claude to generate a brief task kickoff summary
  try {
    const prompt = `A development task is starting. Generate a brief, encouraging one-line status message for this task:

Story ID: ${storyId}
Title: ${title}
Branch: ${branch}
Iteration: ${iteration}
Acceptance Criteria: ${JSON.stringify(acceptanceCriteria)}

Respond with just the status message, no quotes or extra formatting.`;

    const summary = await askClaude(prompt);
    console.log(`  Claude: ${summary}`);
  } catch (err) {
    console.log(`  Claude: (unavailable) ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_start] Error:", err.message);
  process.exit(1);
});
```

### 3. `.ralf/hooks/on-task-completed.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_completed
 * Triggered: After story passes all checks
 *
 * Context (JSON via stdin):
 * {
 *   "storyId": "US-001",
 *   "title": "Add user authentication",
 *   "commitHash": "abc123",
 *   "filesChanged": ["src/auth.ts"],
 *   "metrics": {
 *     "startedAt": "2024-01-15T10:30:00Z",
 *     "completedAt": "2024-01-15T10:45:00Z",
 *     "durationMs": 900000,
 *     "tokensConsumed": 45000
 *   }
 * }
 *
 * Uses Claude Agent SDK (no separate API key required)
 */

import { query } from "@anthropic-ai/claude-agent-sdk";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: {
      allowedTools: [],
      maxTurns: 1,
    },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  // Read context from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, commitHash, filesChanged, metrics } = context;

  const durationSeconds = Math.round((metrics?.durationMs || 0) / 1000);
  const durationMinutes = Math.round(durationSeconds / 60);

  console.log(`[on_task_completed] ${storyId}: ${title}`);
  console.log(`  Commit: ${commitHash}`);
  console.log(`  Files changed: ${filesChanged?.length || 0}`);
  console.log(`  Duration: ${durationMinutes}m ${durationSeconds % 60}s`);
  console.log(`  Tokens consumed: ${metrics?.tokensConsumed || "N/A"}`);

  // Use Claude to generate a completion summary
  try {
    const prompt = `A development task has been completed successfully. Generate a brief celebratory one-line summary:

Story ID: ${storyId}
Title: ${title}
Files Changed: ${JSON.stringify(filesChanged)}
Duration: ${durationMinutes} minutes
Tokens Used: ${metrics?.tokensConsumed || "N/A"}

Respond with just the summary message, no quotes or extra formatting.`;

    const summary = await askClaude(prompt);
    console.log(`  Claude: ${summary}`);
  } catch (err) {
    console.log(`  Claude: (unavailable) ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_completed] Error:", err.message);
  process.exit(1);
});
```

### 4. `.ralf/hooks/on-task-blocked.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_blocked
 * Triggered: After max retries exceeded
 *
 * Context (JSON via stdin):
 * {
 *   "storyId": "US-001",
 *   "title": "Add user authentication",
 *   "blockedReason": "Typecheck failed",
 *   "retryCount": 3,
 *   "errors": ["Error 1", "Error 2"]
 * }
 *
 * Uses Claude Agent SDK (no separate API key required)
 */

import { query } from "@anthropic-ai/claude-agent-sdk";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: {
      allowedTools: [],
      maxTurns: 1,
    },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  // Read context from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, blockedReason, retryCount, errors } = context;

  console.log(`[on_task_blocked] ${storyId}: ${title}`);
  console.log(`  Blocked reason: ${blockedReason}`);
  console.log(`  Retry count: ${retryCount}`);
  if (errors?.length) {
    console.log(`  Errors:`);
    errors.forEach((err, i) => console.log(`    ${i + 1}. ${err}`));
  }

  // Use Claude to analyze the blockage and suggest next steps
  try {
    const prompt = `A development task has been blocked after multiple retries. Analyze the situation and provide a brief diagnostic summary with suggested next steps:

Story ID: ${storyId}
Title: ${title}
Blocked Reason: ${blockedReason}
Retry Count: ${retryCount}
Errors: ${JSON.stringify(errors, null, 2)}

Provide:
1. A one-line diagnosis of the likely root cause
2. 2-3 suggested actions to unblock

Keep the response concise and actionable.`;

    const analysis = await askClaude(prompt);
    console.log(
      `\n  Claude Analysis:\n${analysis
        .split("\n")
        .map((l) => "    " + l)
        .join("\n")}`
    );
  } catch (err) {
    console.log(`  Claude: (unavailable) ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_blocked] Error:", err.message);
  process.exit(1);
});
```

## After Creating

Install dependencies and make hooks executable:

```bash
cd .ralf/hooks && npm install && chmod +x *.js
```

## Verification

Test each hook with sample data:

```bash
echo '{"storyId":"US-001","title":"Test","branch":"ralf/test","iteration":1,"priority":1,"acceptanceCriteria":["Test"]}' | node .ralf/hooks/on-task-start.js
```

Expected output:
```
[on_task_start] US-001: Test
  Branch: ralf/test
  Iteration: 1
  Priority: 1
  Claude: <AI-generated kickoff message>
```

## Output

After creating hooks, inform the user:

```
Created .ralf/ structure:
  .ralf/
  ├── .gitignore           # Excludes state.json, metrics.jsonl
  └── hooks/
      ├── package.json     # ES module config + @anthropic-ai/claude-agent-sdk
      ├── node_modules/
      ├── on-task-start.js
      ├── on-task-completed.js
      └── on-task-blocked.js

Hooks use Claude Agent SDK to provide intelligent status messages and diagnostics.
Uses your existing Claude Code authentication - no separate API key required.
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
    ├── package.json
    ├── node_modules/
    ├── on-task-start.js
    ├── on-task-completed.js
    └── on-task-blocked.js
```

## Requirements

- Node.js 18+ (for ES modules and async iteration support)
- Claude Code CLI installed and logged in

## How It Works

The hooks use the `@anthropic-ai/claude-agent-sdk` which:
- Provides programmatic access to Claude Code's capabilities
- Uses your existing Claude Code authentication (no separate API key needed)
- Streams responses via async generators
- Supports the same tools as the terminal version (but hooks use `allowedTools: []` for simple prompts)

The `query()` function returns an async generator that yields messages. The final result is in a message with `type: "result"` and `subtype: "success"`.
