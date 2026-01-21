#!/bin/bash
# Ralf lifecycle hook: on_task_completed
# Fired after story passes all checks
#
# Receives JSON via stdin with completion context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "commitHash": "abc123def",
#   "filesChanged": ["src/auth.ts", "src/login.tsx"],
#   "metrics": {
#     "startedAt": "2024-01-15T10:30:00Z",
#     "completedAt": "2024-01-15T10:45:00Z",
#     "durationMs": 900000,
#     "tokensConsumed": 45000
#   }
# }
#
# Copy this file to: .ralf/hooks/on-task-completed.sh
# Make executable: chmod +x .ralf/hooks/on-task-completed.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
COMMIT_HASH=$(echo "$CONTEXT" | jq -r '.commitHash')
DURATION_MS=$(echo "$CONTEXT" | jq -r '.metrics.durationMs')
TOKENS=$(echo "$CONTEXT" | jq -r '.metrics.tokensConsumed')
FILES_CHANGED=$(echo "$CONTEXT" | jq -r '.filesChanged | join(", ")')

# Calculate human-readable duration
DURATION_SEC=$((DURATION_MS / 1000))
DURATION_MIN=$((DURATION_SEC / 60))
DURATION_REMAINING_SEC=$((DURATION_SEC % 60))

# Log completion
echo "[Ralf Hook] Completed story $STORY_ID: $STORY_TITLE"
echo "  Duration: ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s"
echo "  Tokens: $TOKENS"
echo "  Commit: $COMMIT_HASH"

# ============================================
# GITHUB INTEGRATION (uncomment to enable)
# ============================================
# Close GitHub issue with summary
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   gh issue comment "$ISSUE_NUM" --body "Completed in ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s using $TOKENS tokens.
#
# Commit: \`$COMMIT_HASH\`
# Files changed: $FILES_CHANGED"
#
#   # Optionally close the issue
#   # gh issue close "$ISSUE_NUM"
#
#   # Remove in-progress label
#   gh issue edit "$ISSUE_NUM" --remove-label "in-progress"
# fi

# ============================================
# GITLAB INTEGRATION (uncomment to enable)
# ============================================
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   glab issue note "$ISSUE_NUM" --message "Completed in ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s using $TOKENS tokens.
#
# Commit: \`$COMMIT_HASH\`
# Files changed: $FILES_CHANGED"
#
#   # Remove in-progress label
#   glab issue update "$ISSUE_NUM" --unlabel "in-progress"
# fi

# ============================================
# JIRA INTEGRATION (uncomment to enable)
# ============================================
# if [[ "$STORY_ID" =~ ^[A-Z]+-[0-9]+$ ]]; then
#   # Add comment
#   curl -X POST -H "Authorization: Bearer $JIRA_TOKEN" \
#     "$JIRA_URL/rest/api/3/issue/$STORY_ID/comment" \
#     -H "Content-Type: application/json" \
#     -d "{\"body\": {\"type\": \"doc\", \"version\": 1, \"content\": [{\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"Completed in ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s. Commit: $COMMIT_HASH\"}]}]}}"
#
#   # Transition to "Done"
#   curl -X POST -H "Authorization: Bearer $JIRA_TOKEN" \
#     "$JIRA_URL/rest/api/3/issue/$STORY_ID/transitions" \
#     -H "Content-Type: application/json" \
#     -d '{"transition": {"id": "31"}}'  # 31 = Done transition ID
# fi

# ============================================
# SLACK NOTIFICATION (uncomment to enable)
# ============================================
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"Ralf completed $STORY_ID: $STORY_TITLE in ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s\"}" \
#   "$SLACK_WEBHOOK_URL"

# ============================================
# METRICS LOGGING (uncomment to enable)
# ============================================
# Log metrics to a file for analysis
# echo "$CONTEXT" >> .ralf/metrics.jsonl

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here

echo "[Ralf Hook] on_task_completed finished for $STORY_ID"
