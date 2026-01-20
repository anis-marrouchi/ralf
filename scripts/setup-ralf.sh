#!/bin/bash

# Ralf Setup Script
# Initializes state for Ralf loop execution

set -euo pipefail

# Default values
PRD_PATH="prd.json"
MAX_ITERATIONS=0
COMPLETION_PROMISE="COMPLETE"

# Help message
show_help() {
  cat << 'HELP_EOF'
Ralf - PRD-driven development loop

USAGE:
  /ralf [PRD_PATH] [OPTIONS]

ARGUMENTS:
  PRD_PATH    Path to prd.json file (default: prd.json)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Custom completion phrase (default: COMPLETE)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts Ralf autonomous execution. Ralf will:
  1. Read the prd.json file
  2. Pick the highest priority story with passes: false
  3. Implement the story
  4. Update prd.json and progress.txt
  5. Loop until all stories pass or max iterations reached

COMPLETION:
  The loop ends when:
  - All stories in prd.json have passes: true (auto-complete)
  - Claude outputs <promise>COMPLETE</promise> (explicit complete)
  - Max iterations reached (if set)

EXAMPLES:
  /ralf                                    # Use default prd.json
  /ralf tasks/feature-prd.json             # Custom PRD path
  /ralf --max-iterations 20                # Limit iterations
  /ralf prd.json --max-iterations 50       # Custom path + limit

MONITORING:
  /ralf-status    Show current progress
  /cancel-ralf    Stop the loop

WORKFLOW:
  1. /prd                  # Create a PRD
  2. /prd-to-json          # Convert to prd.json
  3. /ralf                # Start execution
  4. /ralf-status         # Check progress
HELP_EOF
  exit 0
}

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      echo "Run '/ralf --help' for usage" >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# First positional arg is PRD path
if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  PRD_PATH="${POSITIONAL_ARGS[0]}"
fi

# Validate PRD file exists
if [[ ! -f "$PRD_PATH" ]]; then
  echo "Error: PRD file not found: $PRD_PATH" >&2
  echo "" >&2
  echo "Create a prd.json first:" >&2
  echo "  1. /prd           # Generate a PRD" >&2
  echo "  2. /prd-to-json   # Convert to prd.json" >&2
  echo "" >&2
  echo "Or specify a different path:" >&2
  echo "  /ralf path/to/prd.json" >&2
  exit 1
fi

# Validate PRD is valid JSON
if ! jq empty "$PRD_PATH" 2>/dev/null; then
  echo "Error: Invalid JSON in $PRD_PATH" >&2
  exit 1
fi

# Check for existing loop
if [[ -f ".claude/ralf-state.json" ]]; then
  echo "Warning: Ralf loop already active!" >&2
  echo "Run /cancel-ralf first to stop the existing loop" >&2
  exit 1
fi

# Read PRD metadata
PROJECT=$(jq -r '.project // "Unknown"' "$PRD_PATH")
BRANCH=$(jq -r '.branchName // "ralf/feature"' "$PRD_PATH")
DESCRIPTION=$(jq -r '.description // ""' "$PRD_PATH")
TOTAL_STORIES=$(jq '.userStories | length' "$PRD_PATH")
PASSING_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH")
FAILING_STORIES=$((TOTAL_STORIES - PASSING_STORIES))

# Build the prompt for the loop
PROMPT="You are Ralf, an autonomous coding agent. Execute the next incomplete story from $PRD_PATH following the Ralf workflow: read PRD, check branch, implement story, verify, commit, update status, log progress. Work on ONE story per iteration."

# Create state directory
mkdir -p .claude

# Create state file (JSON format)
cat > .claude/ralf-state.json << EOF
{
  "active": true,
  "iteration": 1,
  "maxIterations": $MAX_ITERATIONS,
  "completionPromise": "$COMPLETION_PROMISE",
  "prdPath": "$PRD_PATH",
  "project": "$PROJECT",
  "branch": "$BRANCH",
  "startedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "prompt": $(echo "$PROMPT" | jq -Rs .)
}
EOF

# Output setup message
cat << EOF
Ralf Autonomous Loop Activated

Project: $PROJECT
Branch: $BRANCH
PRD: $PRD_PATH
Description: $DESCRIPTION

Stories: $PASSING_STORIES/$TOTAL_STORIES passing ($FAILING_STORIES remaining)

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion: Auto (all stories pass) OR <promise>$COMPLETION_PROMISE</promise>

The stop hook is now active. Each iteration will:
1. Pick the next incomplete story
2. Implement and verify
3. Update prd.json and progress.txt
4. Continue until complete

Commands:
  /ralf-status  - Check progress
  /cancel-ralf  - Stop the loop

Starting execution...
EOF

# Create or update progress.txt if it doesn't exist
if [[ ! -f "progress.txt" ]]; then
  cat > progress.txt << EOF
# Ralf Progress Log

## Codebase Patterns
<!-- Add reusable patterns discovered during development -->

---

EOF
  echo ""
  echo "Created progress.txt for tracking"
fi

echo ""
echo "---"
echo ""
echo "$PROMPT"
