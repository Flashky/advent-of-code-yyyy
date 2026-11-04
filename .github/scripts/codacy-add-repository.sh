#!/bin/bash
# =================================================================================
# Usage:       ./codacy-add-repository.sh <owner> <repository-name>
# Description: Adds the specified repository to Codacy
# Example:     ./codacy-add-repository.sh Flashky advent-of-code-2026
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

echo "Adding repository to Codacy..."

# Add the repository to Codacy
HTTP_STATUS=$(curl -sSX POST "https://app.codacy.com/api/v3/repositories" \
     -H "Content-Type: application/json" \
     -H "api-token: $CODACY_API_TOKEN" \
     -d "{
       \"provider\": \"$GIT_PROVIDER\",
       \"repositoryFullPath\": \"$ORGANIZATION/$REPOSITORY\"
     }" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE") || {
  rc=$?
  echo "::error title=Codacy API::Request to Codacy failed (curl exit $rc)"
  exit 1
}

# Check results
if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  echo "Repository successfully added to Codacy."
  exit 0
else

  # Extract the error message and log it
  if [ -s "$RESPONSE_FILE" ]; then
    ERR_TITLE=$(grep -o -m1 '"error"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | sed 's/.*:"\(.*\)"/\1/' || true)
    ERR_MSG=$(grep -o -m1 '"message"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESPONSE_FILE" | sed 's/.*:"\(.*\)"/\1/' || true)

    # Default values if there are no messages
    ERR_TITLE="${ERR_TITLE:-Error}"
    ERR_MSG="${ERR_MSG:-$(cat "$RESPONSE_FILE")}"

    echo "::error title=Codacy API::$HTTP_STATUS $ERR_TITLE: $ERR_MSG"
  else
    echo "::error title=Codacy API::$HTTP_STATUS Empty response from server."
  fi

  exit 1
fi