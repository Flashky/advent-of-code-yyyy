#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.sh <owner> <repository-name>
# Description: Generates a project-level Codacy token for the specified repository.
# Example:     ./codacy-create-token.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

GIT_PROVIDER="gh"
ORGANIZATION="${1:?Usage: $0 <owner> <repository-name>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name>}"

# Validations

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

# Temporary file to store the API response
RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

# Generate a token
HTTP_STATUS=$(curl -sSX POST "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens" \
     -H "api-token: $CODACY_API_TOKEN" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE") || {
   rc=$?
   echo "::error title=Codacy API::Request to Codacy failed (curl exit $rc)"
   exit 1
}

# Check results
if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then

  # Extract the token
  TOKEN=$(grep -o -m1 '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | sed 's/.*:"\(.*\)"/\1/' || true)

  # Print the token
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "$TOKEN"
    exit 0
  fi
fi

# Error cases - Log the error
if [ -s "$RESPONSE_FILE" ]; then
  ERR_TITLE=$(grep -o -m1 '"error"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | sed 's/.*:"\(.*\)"/\1/' || true)
  ERR_MSG=$(grep -o -m1 '"message"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | sed 's/.*:"\(.*\)"/\1/' || true)

  ERR_TITLE="${ERR_TITLE:-Error}"
  ERR_MSG="${ERR_MSG:-$(cat "$RESPONSE_FILE")}"

  echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG"
else
  echo "$HTTP_STATUS Error: Empty response from server."
fi

echo "::error title=Codacy Token Error::Failed to generate Codacy token."

exit 1