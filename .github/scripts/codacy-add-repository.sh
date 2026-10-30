#!/bin/bash
# =================================================================================
# Usage:       ./codacy-add-repository.sh <repository-name>
# Description: Adds the specified repository to Codacy
# Example:     ./codacy-create-token.sh advent-of-code-2026
# =================================================================================

set -e

GIT_PROVIDER="gh"
ORGANIZATION="Flashky"
REPOSITORY=$1

# Temporary file to store the API response
RESPONSE_FILE=$(mktemp)
trap "rm -f $RESPONSE_FILE" EXIT

echo "Adding repository to Codacy..."

# Add the repository to Codacy
HTTP_STATUS=$(curl -sX POST "https://app.codacy.com/api/v3/repositories" \
     -H "Content-Type: application/json" \
     -H "api-token: $CODACY_API_TOKEN" \
     -d "{
       \"provider\": \"$GIT_PROVIDER\",
       \"repositoryFullPath\": \"$ORGANIZATION/$REPOSITORY\"
     }" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE")

# Check results
if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  echo "Repository successfully added to Codacy."
  exit 0
else

  # Extract the error message and log it
  if [ -s "$RESPONSE_FILE" ]; then
    ERR_TITLE=$(grep -o '"error"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | head -n 1 | sed 's/.*:"\(.*\)"/\1/')
    ERR_MSG=$(grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | head -n 1 | sed 's/.*:"\(.*\)"/\1/')

    # Default values if there are no messages
    ERR_TITLE="${ERR_TITLE:-Error}"
    ERR_MSG="${ERR_MSG:-$(cat "$RESPONSE_FILE")}"

    echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG"
  else
    echo "$HTTP_STATUS Error: Empty response from server."
  fi

  exit 1
fi