#!/bin/bash

# Check Completion Script
# Checks if all stories in prd.json are passing

set -euo pipefail

PRD_PATH="${1:-prd.json}"

if [[ ! -f "$PRD_PATH" ]]; then
  echo "Error: PRD file not found: $PRD_PATH" >&2
  exit 1
fi

# Count stories
TOTAL=$(jq '.userStories | length' "$PRD_PATH")
PASSING=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH")
FAILING=$((TOTAL - PASSING))

# Output status
echo "PRD Status: $PRD_PATH"
echo "============================================"
echo ""

# List all stories with status
jq -r '.userStories[] | "\(.id): \(.title) [\(if .passes then "PASS" else "FAIL" end)]"' "$PRD_PATH"

echo ""
echo "============================================"
echo "Progress: $PASSING/$TOTAL passing ($FAILING remaining)"
echo ""

if [[ "$FAILING" -eq 0 ]]; then
  echo "STATUS: COMPLETE - All stories passing!"
  exit 0
else
  # Show next story to work on
  NEXT_STORY=$(jq -r '[.userStories[] | select(.passes == false)][0] | "\(.id): \(.title)"' "$PRD_PATH")
  echo "STATUS: IN PROGRESS"
  echo "Next story: $NEXT_STORY"
  exit 1
fi
