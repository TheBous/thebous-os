#!/usr/bin/env bash
# GitHub PR Comments & Reviews Query (Task 5)
# Queries PR comments and reviews from a specific person
set -euo pipefail

# Input Validation
: "${WORKITEM_TYPE:?WORKITEM_TYPE not set}"
: "${RESOLVED_ID:?RESOLVED_ID not set}"
: "${PERSON_INPUT:?PERSON_INPUT not set}"
: "${GITHUB_REPOS:?GITHUB_REPOS not set}"

# Early Exit for Non-GitHub Work Items
if [ "$WORKITEM_TYPE" != "github" ]; then
  echo "[]"
  exit 0
fi

# Extract First Repo
# GITHUB_REPOS can be comma or space separated
FIRST_REPO=$(echo "$GITHUB_REPOS" | tr ',' ' ' | awk '{print $1}')

if [ -z "$FIRST_REPO" ]; then
  echo "[]"
  exit 0
fi

# Get GitHub User Handle
# Try to resolve PERSON_INPUT to a GitHub handle
get_github_user() {
  local input="$1"
  # If it looks like email, search for GitHub user
  if [[ "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    # Email input - search for GitHub user
    gh search users --query="$input" --json login --limit 1 2>/dev/null | jq -r '.[0].login // empty' || echo ""
  else
    # Assume it's already a username
    echo "$input"
  fi
}

GITHUB_USER=$(get_github_user "$PERSON_INPUT")

if [ -z "$GITHUB_USER" ]; then
  echo "[]"
  exit 0
fi

# Query PR Comments
query_pr_comments() {
  local repo="$1" pr_num="$2" username="$3"
  gh api "repos/$repo/pulls/$pr_num/comments" --paginate 2>/dev/null | jq --arg user "$username" '[
    .[] |
    select(.user.login == $user) |
    {
      timestamp: .created_at,
      author: .user.login,
      body: .body,
      url: .html_url
    }]' || echo "[]"
}

# Query PR Reviews
query_pr_reviews() {
  local repo="$1" pr_num="$2" username="$3"
  gh api "repos/$repo/pulls/$pr_num/reviews" --paginate 2>/dev/null | jq --arg user "$username" '[
    .[] |
    select(.user.login == $user) |
    {
      timestamp: .submitted_at,
      author: .user.login,
      state: .state,
      url: .html_url
    }]' || echo "[]"
}

# Collect All Results and sort by timestamp
(
  query_pr_comments "$FIRST_REPO" "$RESOLVED_ID" "$GITHUB_USER" 2>/dev/null || echo "[]"
  query_pr_reviews "$FIRST_REPO" "$RESOLVED_ID" "$GITHUB_USER" 2>/dev/null || echo "[]"
) | jq -s 'add | sort_by(.timestamp)' 2>/dev/null || echo "[]"
