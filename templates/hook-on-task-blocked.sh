#!/bin/bash
# Ralf lifecycle hook: on_task_blocked
# Fired after max retries exceeded
#
# Receives JSON via stdin with blocked context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "blockedReason": "Typecheck failed: Cannot find module 'auth-lib'",
#   "retryCount": 3,
#   "errors": ["Error 1", "Error 2", "Error 3"],
#   "lastAttempt": {
#     "startedAt": "2024-01-15T10:30:00Z",
#     "completedAt": "2024-01-15T10:35:00Z",
#     "error": "Typecheck failed"
#   }
# }
#
# Copy this file to: .ralf/hooks/on-task-blocked.sh
# Make executable: chmod +x .ralf/hooks/on-task-blocked.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
BLOCKED_REASON=$(echo "$CONTEXT" | jq -r '.blockedReason')
RETRY_COUNT=$(echo "$CONTEXT" | jq -r '.retryCount')
ERRORS=$(echo "$CONTEXT" | jq -r '.errors | join("\n  - ")')

# Log blocked status
echo "[Ralf Hook] BLOCKED story $STORY_ID: $STORY_TITLE"
echo "  Reason: $BLOCKED_REASON"
echo "  Attempts: $RETRY_COUNT"
echo "  Errors:"
echo "  - $ERRORS"

# ============================================
# GITHUB INTEGRATION (uncomment to enable)
# ============================================
# Add blocked label and comment
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   gh issue edit "$ISSUE_NUM" --add-label "blocked" --remove-label "in-progress"
#   gh issue comment "$ISSUE_NUM" --body "Blocked after $RETRY_COUNT attempts.
#
# **Reason:** $BLOCKED_REASON
#
# **Errors encountered:**
# - $ERRORS
#
# Manual intervention required."
# fi

# ============================================
# GITLAB INTEGRATION (uncomment to enable)
# ============================================
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   glab issue update "$ISSUE_NUM" --label "blocked" --unlabel "in-progress"
#   glab issue note "$ISSUE_NUM" --message "Blocked after $RETRY_COUNT attempts.
#
# **Reason:** $BLOCKED_REASON
#
# **Errors encountered:**
# - $ERRORS
#
# Manual intervention required."
# fi

# ============================================
# JIRA INTEGRATION (uncomment to enable)
# ============================================
# if [[ "$STORY_ID" =~ ^[A-Z]+-[0-9]+$ ]]; then
#   # Add comment
#   curl -X POST -H "Authorization: Bearer $JIRA_TOKEN" \
#     "$JIRA_URL/rest/api/3/issue/$STORY_ID/comment" \
#     -H "Content-Type: application/json" \
#     -d "{\"body\": {\"type\": \"doc\", \"version\": 1, \"content\": [{\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"Blocked after $RETRY_COUNT attempts. Reason: $BLOCKED_REASON\"}]}]}}"
#
#   # Transition to "Blocked"
#   curl -X POST -H "Authorization: Bearer $JIRA_TOKEN" \
#     "$JIRA_URL/rest/api/3/issue/$STORY_ID/transitions" \
#     -H "Content-Type: application/json" \
#     -d '{"transition": {"id": "41"}}'  # 41 = Blocked transition ID
# fi

# ============================================
# SLACK NOTIFICATION (uncomment to enable)
# ============================================
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"BLOCKED: Ralf could not complete $STORY_ID: $STORY_TITLE after $RETRY_COUNT attempts. Reason: $BLOCKED_REASON\"}" \
#   "$SLACK_WEBHOOK_URL"

# ============================================
# PAGERDUTY/ALERT (uncomment to enable)
# ============================================
# For critical stories, you might want to alert
# curl -X POST -H "Authorization: Token token=$PAGERDUTY_TOKEN" \
#   "https://events.pagerduty.com/v2/enqueue" \
#   -d "{\"routing_key\": \"$PAGERDUTY_SERVICE_KEY\", \"event_action\": \"trigger\", \"payload\": {\"summary\": \"Ralf blocked on $STORY_ID\", \"severity\": \"warning\", \"source\": \"ralf\"}}"

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here

echo "[Ralf Hook] on_task_blocked finished for $STORY_ID"
