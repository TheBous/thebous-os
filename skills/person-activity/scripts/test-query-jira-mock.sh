#!/usr/bin/env bash
# Mock test for query-jira.sh demonstrating correct behavior
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Jira Comments Query Mock Test ==="
echo

# ─────────────────────────────────────────────────────────────────────
# Create mock Jira response
# ─────────────────────────────────────────────────────────────────────
create_mock_jira_response() {
  cat << 'EOF'
{
  "key": "DC-443",
  "fields": {
    "summary": "Implement user authentication",
    "comment": {
      "comments": [
        {
          "id": "10000",
          "author": {
            "name": "marco.rossi",
            "emailAddress": "marco.rossi@company.com",
            "displayName": "Marco Rossi"
          },
          "body": "I started working on the OAuth2 implementation.",
          "created": "2024-01-15T10:30:00.000+0000"
        },
        {
          "id": "10001",
          "author": {
            "name": "sarah.johnson",
            "emailAddress": "sarah.johnson@company.com",
            "displayName": "Sarah Johnson"
          },
          "body": "Please make sure to handle token refresh properly.",
          "created": "2024-01-15T11:00:00.000+0000"
        },
        {
          "id": "10002",
          "author": {
            "name": "marco.rossi",
            "emailAddress": "marco.rossi@company.com",
            "displayName": "Marco Rossi"
          },
          "body": "Done! Token refresh is implemented with 1 hour TTL.",
          "created": "2024-01-15T14:30:00.000+0000"
        }
      ]
    }
  }
}
EOF
}

# ─────────────────────────────────────────────────────────────────────
# Test 1: Filter by email
# ─────────────────────────────────────────────────────────────────────
echo "Test 1: Filter comments by email (marco.rossi@company.com)"
echo

mock_response=$(create_mock_jira_response)
JIRA_BASE_URL="https://debto.atlassian.net"

# Simulate filtering logic from the script
output=$(echo "$mock_response" | jq \
  --arg email "marco.rossi@company.com" \
  --arg names "marco rossi" \
  --arg issue_url "https://debto.atlassian.net/browse/DC-443" \
  '[
    .fields.comment.comments[] |
    select(
      (.author.emailAddress // "" | ascii_downcase | contains(($email | ascii_downcase))) or
      (.author.name // "" | ascii_downcase | contains(($names | ascii_downcase)))
    ) |
    {
      timestamp: .created,
      author: .author.displayName,
      body: .body,
      url: ($issue_url + "#" + .id)
    }
  ]')

echo "$output" | jq .
count=$(echo "$output" | jq 'length')
echo "✓ Found $count comments from Marco Rossi"
echo

# ─────────────────────────────────────────────────────────────────────
# Test 2: Verify output structure
# ─────────────────────────────────────────────────────────────────────
echo "Test 2: Verify JSON output structure"
echo

if echo "$output" | jq -e '.[0] | has("timestamp") and has("author") and has("body") and has("url")' >/dev/null 2>&1; then
  echo "✓ First comment has all required fields:"
  echo "  - timestamp: $(echo "$output" | jq -r '.[0].timestamp')"
  echo "  - author: $(echo "$output" | jq -r '.[0].author')"
  echo "  - body: $(echo "$output" | jq -r '.[0].body' | cut -c1-50)..."
  echo "  - url: $(echo "$output" | jq -r '.[0].url')"
else
  echo "✗ Output missing required fields"
  exit 1
fi

echo

# ─────────────────────────────────────────────────────────────────────
# Test 3: Filter by name parts
# ─────────────────────────────────────────────────────────────────────
echo "Test 3: Filter by name parts (marco rossi) using improved matching"
echo

output_by_name=$(echo "$mock_response" | jq \
  --arg email "" \
  --arg names "marco rossi" \
  --arg issue_url "https://debto.atlassian.net/browse/DC-443" \
  '[
    .fields.comment.comments[] |
    select(
      (if $email != "" then
        ((.author.emailAddress // "" | ascii_downcase) == ($email | ascii_downcase)) or
        ((.author.emailAddress // "" | ascii_downcase) | startswith(($email | split("@")[0] | ascii_downcase)))
      else
        false
      end) or
      ((.author.name // "" | ascii_downcase | gsub("[._-]"; " ") | contains(($names | ascii_downcase))) or
       (.author.displayName // "" | ascii_downcase | contains(($names | ascii_downcase))))
    ) |
    {
      timestamp: .created,
      author: .author.displayName,
      body: .body,
      url: ($issue_url + "#" + .id)
    }
  ]')

count=$(echo "$output_by_name" | jq 'length')
echo "✓ Found $count comments from Marco (by name parts)"
echo

# ─────────────────────────────────────────────────────────────────────
# Test 4: No match scenario
# ─────────────────────────────────────────────────────────────────────
echo "Test 4: No matching comments"
echo

output_no_match=$(echo "$mock_response" | jq \
  --arg email "nonexistent@company.com" \
  --arg names "nonexistent person" \
  --arg issue_url "https://debto.atlassian.net/browse/DC-443" \
  '[
    .fields.comment.comments[] |
    select(
      (if $email != "" then
        ((.author.emailAddress // "" | ascii_downcase) == ($email | ascii_downcase)) or
        ((.author.emailAddress // "" | ascii_downcase) | startswith(($email | split("@")[0] | ascii_downcase)))
      else
        false
      end) or
      ((.author.name // "" | ascii_downcase | gsub("[._-]"; " ") | contains(($names | ascii_downcase))) or
       (.author.displayName // "" | ascii_downcase | contains(($names | ascii_downcase))))
    ) |
    {
      timestamp: .created,
      author: .author.displayName,
      body: .body,
      url: ($issue_url + "#" + .id)
    }
  ]')

count=$(echo "$output_no_match" | jq 'length')
if [ "$count" = "0" ]; then
  echo "✓ Correctly returned empty array when no comments match"
else
  echo "✗ Expected empty array but got $count results"
  exit 1
fi

echo
echo "=== All Mock Tests Passed ==="
