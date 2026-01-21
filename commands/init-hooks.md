---
description: "Initialize Ralf lifecycle hooks with compounding knowledge system"
argument-hint: "[--force]"
---

# Initialize Ralf Hooks

Create the `.ralf/hooks/` directory with JavaScript hook scripts that use the Claude Agent SDK for intelligent lifecycle event handling and **compounding knowledge** - capturing learnings from each task to make future runs smarter.

## The Job

1. Create `.ralf/` directory structure if it doesn't exist
2. Create `.ralf/knowledge/` for compounding knowledge storage
3. Generate `.ralf/.gitignore` to exclude runtime artifacts
4. Generate boilerplate for each lifecycle hook (JavaScript using Claude Agent SDK)
5. Create shared `knowledge.js` utility module
6. Create `package.json` with SDK dependency
7. Install dependencies
8. Make scripts executable
9. Skip existing files unless `--force` is passed

## Compounding Knowledge System

The hooks implement a knowledge capture system that compounds learnings across task executions:

| Hook | Captures | Future Benefit |
|------|----------|----------------|
| `on-task-completed` | Patterns used, decisions made, files touched | Similar tasks get context from past solutions |
| `on-task-blocked` | Error types, root causes, resolutions | Proactive warnings when similar patterns detected |
| `on-task-start` | Queries knowledge base | Injects relevant learnings into executor context |

## Execute

```bash
mkdir -p .ralf/hooks .ralf/knowledge
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
# knowledge/
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

### 2. `.ralf/hooks/knowledge.js`

Shared utility module for knowledge operations:

```javascript
#!/usr/bin/env node
/**
 * Ralf Knowledge System
 * Captures and retrieves learnings across task executions
 */

import { readFile, appendFile, mkdir } from "fs/promises";
import { existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const KNOWLEDGE_DIR = join(__dirname, "..", "knowledge");

// Ensure knowledge directory exists
async function ensureKnowledgeDir() {
  if (!existsSync(KNOWLEDGE_DIR)) {
    await mkdir(KNOWLEDGE_DIR, { recursive: true });
  }
}

/**
 * Append an entry to a JSONL knowledge file
 */
export async function appendKnowledge(filename, entry) {
  await ensureKnowledgeDir();
  const filepath = join(KNOWLEDGE_DIR, filename);
  const line = JSON.stringify({
    ...entry,
    timestamp: new Date().toISOString(),
  }) + "\n";
  await appendFile(filepath, line);
}

/**
 * Read all entries from a JSONL knowledge file
 */
export async function readKnowledge(filename) {
  const filepath = join(KNOWLEDGE_DIR, filename);
  if (!existsSync(filepath)) {
    return [];
  }
  const content = await readFile(filepath, "utf-8");
  return content
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => JSON.parse(line));
}

/**
 * Find relevant knowledge entries based on keywords
 */
export async function findRelevantKnowledge(keywords, options = {}) {
  const { maxResults = 5, files = ["patterns.jsonl", "blockers.jsonl", "decisions.jsonl"] } = options;

  const allEntries = [];

  for (const file of files) {
    const entries = await readKnowledge(file);
    allEntries.push(...entries.map((e) => ({ ...e, source: file })));
  }

  // Score entries by keyword relevance
  const scored = allEntries.map((entry) => {
    const text = JSON.stringify(entry).toLowerCase();
    const score = keywords.reduce((acc, kw) => {
      return acc + (text.includes(kw.toLowerCase()) ? 1 : 0);
    }, 0);
    return { entry, score };
  });

  return scored
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, maxResults)
    .map((s) => s.entry);
}

/**
 * Extract keywords from task context for knowledge matching
 */
export function extractKeywords(context) {
  const keywords = [];

  // From title
  if (context.title) {
    keywords.push(...context.title.toLowerCase().split(/\s+/).filter((w) => w.length > 3));
  }

  // From files changed
  if (context.filesChanged) {
    context.filesChanged.forEach((file) => {
      // Extract directory names and file stems
      const parts = file.split("/");
      parts.forEach((part) => {
        const stem = part.replace(/\.[^.]+$/, "");
        if (stem.length > 2) keywords.push(stem.toLowerCase());
      });
    });
  }

  // From acceptance criteria
  if (context.acceptanceCriteria) {
    context.acceptanceCriteria.forEach((ac) => {
      keywords.push(...ac.toLowerCase().split(/\s+/).filter((w) => w.length > 3));
    });
  }

  // Deduplicate
  return [...new Set(keywords)];
}
```

### 3. `.ralf/hooks/on-task-start.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_start
 * Triggered: Before story-executor spawns
 *
 * Compounding Knowledge: Queries past learnings to provide context
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
 * Output (JSON to stdout when relevant knowledge found):
 * {
 *   "additionalContext": "Previous auth work used JWT pattern in src/auth/..."
 * }
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { findRelevantKnowledge, extractKeywords } from "./knowledge.js";

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

  const { storyId, title, branch, iteration, priority, acceptanceCriteria } = context;

  console.error(`[on_task_start] ${storyId}: ${title}`);
  console.error(`  Branch: ${branch}`);
  console.error(`  Iteration: ${iteration}`);
  console.error(`  Priority: ${priority}`);

  // Query compounding knowledge
  const keywords = extractKeywords(context);
  const relevantKnowledge = await findRelevantKnowledge(keywords);

  let additionalContext = null;

  if (relevantKnowledge.length > 0) {
    console.error(`  Found ${relevantKnowledge.length} relevant knowledge entries`);

    try {
      const knowledgeSummary = relevantKnowledge
        .map((k) => `- [${k.source}] ${k.summary || k.pattern || k.resolution || JSON.stringify(k)}`)
        .join("\n");

      const prompt = `A development task is starting. Based on past learnings from similar tasks, provide a brief context summary that would help with this task:

Current Task:
- Story ID: ${storyId}
- Title: ${title}
- Acceptance Criteria: ${JSON.stringify(acceptanceCriteria)}

Relevant Past Learnings:
${knowledgeSummary}

Synthesize the most relevant insights into 2-3 actionable sentences. Focus on patterns to follow, pitfalls to avoid, and key files/modules to reference.`;

      additionalContext = await askClaude(prompt);
      console.error(`\n  Compounded Knowledge:\n${additionalContext.split("\n").map((l) => "    " + l).join("\n")}`);
    } catch (err) {
      console.error(`  Claude: (unavailable) ${err.message}`);
    }
  } else {
    console.error(`  No relevant past knowledge found (keywords: ${keywords.slice(0, 5).join(", ")})`);

    // Generate kickoff message without knowledge context
    try {
      const prompt = `A development task is starting. Generate a brief, encouraging one-line status message:

Story ID: ${storyId}
Title: ${title}
Iteration: ${iteration}

Respond with just the status message, no quotes or extra formatting.`;

      const summary = await askClaude(prompt);
      console.error(`  Claude: ${summary}`);
    } catch (err) {
      console.error(`  Claude: (unavailable) ${err.message}`);
    }
  }

  // Output additional context for story-executor if found
  if (additionalContext) {
    console.log(JSON.stringify({ additionalContext }));
  }
}

main().catch((err) => {
  console.error("[on_task_start] Error:", err.message);
  process.exit(1);
});
```

### 4. `.ralf/hooks/on-task-completed.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_completed
 * Triggered: After story passes all checks
 *
 * Compounding Knowledge: Extracts patterns and decisions for future tasks
 *
 * Context (JSON via stdin):
 * {
 *   "storyId": "US-001",
 *   "title": "Add user authentication",
 *   "commitHash": "abc123",
 *   "filesChanged": ["src/auth.ts"],
 *   "diff": "...", // optional: git diff of changes
 *   "metrics": {
 *     "startedAt": "2024-01-15T10:30:00Z",
 *     "completedAt": "2024-01-15T10:45:00Z",
 *     "durationMs": 900000,
 *     "tokensConsumed": 45000
 *   }
 * }
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { appendKnowledge, extractKeywords } from "./knowledge.js";

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

  const { storyId, title, commitHash, filesChanged, diff, metrics } = context;

  const durationSeconds = Math.round((metrics?.durationMs || 0) / 1000);
  const durationMinutes = Math.round(durationSeconds / 60);

  console.error(`[on_task_completed] ${storyId}: ${title}`);
  console.error(`  Commit: ${commitHash}`);
  console.error(`  Files changed: ${filesChanged?.length || 0}`);
  console.error(`  Duration: ${durationMinutes}m ${durationSeconds % 60}s`);
  console.error(`  Tokens consumed: ${metrics?.tokensConsumed || "N/A"}`);

  // Extract and store learnings
  try {
    const prompt = `A development task has been completed. Extract reusable learnings from this task:

Story ID: ${storyId}
Title: ${title}
Files Changed: ${JSON.stringify(filesChanged)}
${diff ? `Diff Summary (first 2000 chars):\n${diff.slice(0, 2000)}` : ""}

Provide a JSON response with the following structure:
{
  "pattern": "Brief description of the implementation pattern used (1 sentence)",
  "keyFiles": ["list", "of", "key", "files"],
  "decisions": ["Key technical decision 1", "Key technical decision 2"],
  "reusableFor": ["future task type 1", "future task type 2"]
}

Respond with only the JSON, no markdown formatting.`;

    const learningsJson = await askClaude(prompt);

    let learnings;
    try {
      learnings = JSON.parse(learningsJson.replace(/```json\n?|\n?```/g, "").trim());
    } catch {
      // If parsing fails, create a simple learning entry
      learnings = {
        pattern: `Completed: ${title}`,
        keyFiles: filesChanged?.slice(0, 5) || [],
        decisions: [],
        reusableFor: [],
      };
    }

    // Store pattern
    const keywords = extractKeywords(context);
    await appendKnowledge("patterns.jsonl", {
      storyId,
      title,
      pattern: learnings.pattern,
      keyFiles: learnings.keyFiles,
      keywords,
      metrics: {
        durationMs: metrics?.durationMs,
        tokensConsumed: metrics?.tokensConsumed,
      },
    });

    // Store decisions
    if (learnings.decisions?.length > 0) {
      for (const decision of learnings.decisions) {
        await appendKnowledge("decisions.jsonl", {
          storyId,
          title,
          decision,
          keyFiles: learnings.keyFiles,
          keywords,
        });
      }
    }

    console.error(`\n  Knowledge captured:`);
    console.error(`    Pattern: ${learnings.pattern}`);
    console.error(`    Key files: ${learnings.keyFiles.join(", ")}`);
    if (learnings.decisions?.length > 0) {
      console.error(`    Decisions: ${learnings.decisions.length} recorded`);
    }
    console.error(`    Reusable for: ${learnings.reusableFor.join(", ") || "general"}`);

  } catch (err) {
    console.error(`  Knowledge extraction failed: ${err.message}`);

    // Store basic completion record even if extraction fails
    await appendKnowledge("patterns.jsonl", {
      storyId,
      title,
      pattern: `Completed: ${title}`,
      keyFiles: filesChanged?.slice(0, 5) || [],
      keywords: extractKeywords(context),
    });
  }

  // Generate completion message
  try {
    const prompt = `A development task has been completed successfully. Generate a brief celebratory one-line summary:

Story ID: ${storyId}
Title: ${title}
Files Changed: ${filesChanged?.length || 0}
Duration: ${durationMinutes} minutes

Respond with just the summary message, no quotes or extra formatting.`;

    const summary = await askClaude(prompt);
    console.error(`\n  Claude: ${summary}`);
  } catch (err) {
    console.error(`  Claude: (unavailable) ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_completed] Error:", err.message);
  process.exit(1);
});
```

### 5. `.ralf/hooks/on-task-blocked.js`

```javascript
#!/usr/bin/env node
/**
 * Ralf Lifecycle Hook: on_task_blocked
 * Triggered: After max retries exceeded
 *
 * Compounding Knowledge: Records blockers and resolutions for future prevention
 *
 * Context (JSON via stdin):
 * {
 *   "storyId": "US-001",
 *   "title": "Add user authentication",
 *   "blockedReason": "Typecheck failed",
 *   "retryCount": 3,
 *   "errors": ["Error 1", "Error 2"]
 * }
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { appendKnowledge, findRelevantKnowledge, extractKeywords } from "./knowledge.js";

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

  console.error(`[on_task_blocked] ${storyId}: ${title}`);
  console.error(`  Blocked reason: ${blockedReason}`);
  console.error(`  Retry count: ${retryCount}`);
  if (errors?.length) {
    console.error(`  Errors:`);
    errors.slice(0, 5).forEach((err, i) => console.error(`    ${i + 1}. ${err}`));
    if (errors.length > 5) {
      console.error(`    ... and ${errors.length - 5} more`);
    }
  }

  // Check for similar past blockers
  const errorKeywords = errors?.flatMap((e) =>
    e.toLowerCase().split(/\s+/).filter((w) => w.length > 4)
  ) || [];
  const keywords = [...extractKeywords(context), blockedReason.toLowerCase(), ...errorKeywords];

  const pastBlockers = await findRelevantKnowledge(keywords, {
    files: ["blockers.jsonl"],
    maxResults: 3
  });

  if (pastBlockers.length > 0) {
    console.error(`\n  Similar past blockers found:`);
    pastBlockers.forEach((b, i) => {
      console.error(`    ${i + 1}. ${b.blockedReason}: ${b.resolution || "unresolved"}`);
    });
  }

  // Analyze blockage and suggest solutions
  try {
    const pastBlockerContext = pastBlockers.length > 0
      ? `\nPast similar blockers and their resolutions:\n${pastBlockers.map((b) =>
          `- ${b.blockedReason}: ${b.resolution || "unresolved"}`
        ).join("\n")}`
      : "";

    const prompt = `A development task has been blocked after ${retryCount} retries. Analyze the situation:

Story ID: ${storyId}
Title: ${title}
Blocked Reason: ${blockedReason}
Errors: ${JSON.stringify(errors?.slice(0, 10), null, 2)}
${pastBlockerContext}

Provide a JSON response:
{
  "rootCause": "One-line diagnosis of the likely root cause",
  "category": "One of: dependency, type-error, test-failure, build-error, environment, logic-error, other",
  "suggestedActions": ["Action 1", "Action 2", "Action 3"],
  "preventionTip": "How to prevent this in future tasks"
}

Respond with only the JSON, no markdown formatting.`;

    const analysisJson = await askClaude(prompt);

    let analysis;
    try {
      analysis = JSON.parse(analysisJson.replace(/```json\n?|\n?```/g, "").trim());
    } catch {
      analysis = {
        rootCause: blockedReason,
        category: "other",
        suggestedActions: ["Review error logs", "Check dependencies", "Retry with different approach"],
        preventionTip: "Unknown",
      };
    }

    // Store blocker for future reference
    await appendKnowledge("blockers.jsonl", {
      storyId,
      title,
      blockedReason,
      category: analysis.category,
      rootCause: analysis.rootCause,
      errors: errors?.slice(0, 5),
      keywords,
      resolution: null, // Will be updated if manually resolved
    });

    console.error(`\n  Analysis:`);
    console.error(`    Root cause: ${analysis.rootCause}`);
    console.error(`    Category: ${analysis.category}`);
    console.error(`    Suggested actions:`);
    analysis.suggestedActions.forEach((action, i) => {
      console.error(`      ${i + 1}. ${action}`);
    });
    console.error(`    Prevention tip: ${analysis.preventionTip}`);

    console.error(`\n  Blocker recorded in knowledge base for future reference.`);

  } catch (err) {
    console.error(`  Analysis failed: ${err.message}`);

    // Store basic blocker record even if analysis fails
    await appendKnowledge("blockers.jsonl", {
      storyId,
      title,
      blockedReason,
      category: "other",
      errors: errors?.slice(0, 5),
      keywords,
    });
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

Test the knowledge system:

```bash
# Test task start (no prior knowledge)
echo '{"storyId":"US-001","title":"Add authentication","branch":"ralf/auth","iteration":1,"priority":1,"acceptanceCriteria":["Users can log in"]}' | node .ralf/hooks/on-task-start.js

# Test task completed (stores knowledge)
echo '{"storyId":"US-001","title":"Add authentication","commitHash":"abc123","filesChanged":["src/auth.ts","src/login.tsx"],"metrics":{"durationMs":900000}}' | node .ralf/hooks/on-task-completed.js

# Verify knowledge was stored
cat .ralf/knowledge/patterns.jsonl

# Test task start again (should find relevant knowledge)
echo '{"storyId":"US-002","title":"Add user logout","branch":"ralf/logout","iteration":1,"priority":1,"acceptanceCriteria":["Users can log out"]}' | node .ralf/hooks/on-task-start.js
```

## Output

After creating hooks, inform the user:

```
Created .ralf/ structure with Compounding Knowledge System:
  .ralf/
  ├── .gitignore           # Excludes state.json, metrics.jsonl
  ├── knowledge/           # Compounding knowledge storage
  │   ├── patterns.jsonl   # Successful patterns by domain
  │   ├── decisions.jsonl  # Architecture decisions made
  │   └── blockers.jsonl   # Common blockers and resolutions
  └── hooks/
      ├── package.json     # ES module config + @anthropic-ai/claude-agent-sdk
      ├── node_modules/
      ├── knowledge.js     # Shared knowledge utilities
      ├── on-task-start.js    # Queries knowledge, provides context
      ├── on-task-completed.js # Extracts and stores learnings
      └── on-task-blocked.js   # Records blockers for prevention

Knowledge compounds across runs:
- Completed tasks → patterns.jsonl, decisions.jsonl
- Blocked tasks → blockers.jsonl
- New tasks query knowledge for relevant context

Uses Claude Agent SDK - no separate API key required.
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
├── knowledge/        # Compounding knowledge (tracked)
│   ├── patterns.jsonl
│   ├── decisions.jsonl
│   └── blockers.jsonl
└── hooks/
    ├── package.json
    ├── node_modules/
    ├── knowledge.js
    ├── on-task-start.js
    ├── on-task-completed.js
    └── on-task-blocked.js
```

## Requirements

- Node.js 18+ (for ES modules and async iteration support)
- Claude Code CLI installed and logged in

## How It Works

### Claude Agent SDK

The hooks use the `@anthropic-ai/claude-agent-sdk` which:
- Provides programmatic access to Claude Code's capabilities
- Uses your existing Claude Code authentication (no separate API key needed)
- Streams responses via async generators
- Supports the same tools as the terminal version (but hooks use `allowedTools: []` for simple prompts)

The `query()` function returns an async generator that yields messages. The final result is in a message with `type: "result"` and `subtype: "success"`.

### Compounding Knowledge

Knowledge is stored in JSONL files for append-only, git-friendly storage:

**patterns.jsonl** - Successful implementation patterns:
```json
{"storyId":"US-001","title":"Add auth","pattern":"JWT with refresh tokens","keyFiles":["src/auth.ts"],"keywords":["auth","login"],"timestamp":"..."}
```

**decisions.jsonl** - Architecture decisions:
```json
{"storyId":"US-001","decision":"Used HttpOnly cookies for token storage","keywords":["auth","security"],"timestamp":"..."}
```

**blockers.jsonl** - Blockers and resolutions:
```json
{"storyId":"US-003","blockedReason":"Type error","category":"type-error","rootCause":"Missing null check","resolution":"Added optional chaining","timestamp":"..."}
```

When a new task starts, `on-task-start.js` extracts keywords and queries all knowledge files for relevant entries, then uses Claude to synthesize actionable context for the story-executor.
