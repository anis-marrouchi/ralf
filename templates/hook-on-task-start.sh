#!/bin/bash
# Ralf lifecycle hook: on_task_start
# Fired before story-executor spawns
#
# Receives JSON via stdin with story context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "branch": "ralf/user-auth",
#   "iteration": 1,
#   "priority": 1,
#   "acceptanceCriteria": ["...", "..."]
# }
#
# Copy this file to: .ralf/hooks/on-task-start.sh
# Make executable: chmod +x .ralf/hooks/on-task-start.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
BRANCH=$(echo "$CONTEXT" | jq -r '.branch')
ITERATION=$(echo "$CONTEXT" | jq -r '.iteration')

# Log start
echo "[Ralf Hook] Starting story $STORY_ID: $STORY_TITLE (iteration $ITERATION)"

# ============================================
# GITHUB INTEGRATION (uncomment to enable)
# ============================================
# Update GitHub issue if story ID matches issue format (#123)
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   gh issue edit "$ISSUE_NUM" --add-label "in-progress"
#   gh issue comment "$ISSUE_NUM" --body "Starting implementation on branch \`$BRANCH\` (iteration $ITERATION)"
# fi

# ============================================
# GITLAB INTEGRATION (uncomment to enable)
# ============================================
# Update GitLab issue using glab CLI
# if [[ "$STORY_ID" =~ ^#([0-9]+)$ ]]; then
#   ISSUE_NUM="${BASH_REMATCH[1]}"
#   glab issue update "$ISSUE_NUM" --label "in-progress"
#   glab issue note "$ISSUE_NUM" --message "Starting implementation on branch \`$BRANCH\` (iteration $ITERATION)"
# fi

# ============================================
# JIRA INTEGRATION (uncomment to enable)
# ============================================
# if [[ "$STORY_ID" =~ ^[A-Z]+-[0-9]+$ ]]; then
#   # Transition to "In Progress"
#   curl -X POST -H "Authorization: Bearer $JIRA_TOKEN" \
#     "$JIRA_URL/rest/api/3/issue/$STORY_ID/transitions" \
#     -H "Content-Type: application/json" \
#     -d '{"transition": {"id": "21"}}'  # 21 = In Progress transition ID
# fi

# ============================================
# SLACK NOTIFICATION (uncomment to enable)
# ============================================
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"Ralf starting $STORY_ID: $STORY_TITLE\"}" \
#   "$SLACK_WEBHOOK_URL"

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here

echo "[Ralf Hook] on_task_start completed for $STORY_ID"
