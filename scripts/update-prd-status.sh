#!/bin/bash

# Update PRD Status Script
# Updates a story's pass status and notes in prd.json

set -euo pipefail

# Usage: update-prd-status.sh <story-id> <pass|fail> [notes]

if [[ $# -lt 2 ]]; then
  echo "Usage: update-prd-status.sh <story-id> <pass|fail> [notes]" >&2
  exit 1
fi

STORY_ID="$1"
STATUS="$2"
NOTES="${3:-}"
PRD_PATH="${PRD_PATH:-prd.json}"

if [[ ! -f "$PRD_PATH" ]]; then
  echo "Error: PRD file not found: $PRD_PATH" >&2
  exit 1
fi

# Validate status
case "$STATUS" in
  pass|true|1)
    PASSES=true
    ;;
  fail|false|0)
    PASSES=false
    ;;
  *)
    echo "Error: Status must be 'pass' or 'fail', got: $STATUS" >&2
    exit 1
    ;;
esac

# Check if story exists
if ! jq -e ".userStories[] | select(.id == \"$STORY_ID\")" "$PRD_PATH" > /dev/null 2>&1; then
  echo "Error: Story not found: $STORY_ID" >&2
  exit 1
fi

# Update the story
TEMP_FILE="${PRD_PATH}.tmp.$$"

if [[ -n "$NOTES" ]]; then
  jq "(.userStories[] | select(.id == \"$STORY_ID\")) |= . + {passes: $PASSES, notes: \"$NOTES\"}" "$PRD_PATH" > "$TEMP_FILE"
else
  jq "(.userStories[] | select(.id == \"$STORY_ID\")).passes = $PASSES" "$PRD_PATH" > "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$PRD_PATH"

# Output result
echo "Updated $STORY_ID: passes=$PASSES"

# Check if all stories pass
TOTAL=$(jq '.userStories | length' "$PRD_PATH")
PASSING=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH")

echo "Progress: $PASSING/$TOTAL stories passing"

if [[ "$PASSING" -eq "$TOTAL" ]]; then
  echo ""
  echo "All stories complete!"
fi
