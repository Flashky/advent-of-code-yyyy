#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.sh <repository-name>
# Description: Generates a project-level Codacy token for the specified repository.
# Example:     ./codacy-create-token.sh advent-of-code-2026
# =================================================================================

set -e

GIT_PROVIDER="gh"
ORGANIZATION="Flashky"
REPOSITORY=$1

# Temporary file to store the API response
RESPONSE_FILE=$(mktemp)
trap "rm -f $RESPONSE_FILE" EXIT

# Generate a token
HTTP_STATUS=$(curl -sX POST "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens" \
     -H "api-token: $CODACY_API_TOKEN" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE")

# Check results
if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then

  # Extract the token
  TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | head -n 1 | sed 's/.*:"\(.*\)"/\1/')

  # Print the token
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "$TOKEN"
    exit 0
  fi
fi

# Error cases - Log the error
if [ -s "$RESPONSE_FILE" ]; then
  ERR_TITLE=$(grep -o '"error"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | head -n 1 | sed 's/.*:"\(.*\)"/\1/')
  ERR_MSG=$(grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | head -n 1 | sed 's/.*:"\(.*\)"/\1/')

  ERR_TITLE="${ERR_TITLE:-Error}"
  ERR_MSG="${ERR_MSG:-$(cat "$RESPONSE_FILE")}"

  echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG"
else
  echo "$HTTP_STATUS Error: Empty response from server."
fi
exit 1