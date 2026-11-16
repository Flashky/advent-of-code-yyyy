#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.sh <owner> <repository-name>
# Description: Generates a project-level Codacy token for the specified repository.
#              Requires jq: the response is parsed as JSON, not with grep/sed.
# Example:     ./codacy-create-token.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

GIT_PROVIDER="gh"
ORGANIZATION="${1:?Usage: $0 <owner> <repository-name>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name>}"

# Validations

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to parse the Codacy API response."
  exit 1
}

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

  # `jq -e` fails on malformed JSON and on a missing or empty token, so a broken
  # response can never be mistaken for a valid token.
  if TOKEN=$(jq -er '.token | select(type == "string" and length > 0)' "$RESPONSE_FILE" 2>/dev/null); then
    echo "$TOKEN"
    exit 0
  fi

  echo "::error title=Codacy Token Error::Codacy returned HTTP $HTTP_STATUS without a usable token (invalid JSON or missing field)."
  exit 1
fi

# Error cases - Log the error
if [ -s "$RESPONSE_FILE" ]; then
  ERR_TITLE=$(jq -r '.error // empty' "$RESPONSE_FILE" 2>/dev/null || true)
  ERR_MSG=$(jq -r '.message // empty' "$RESPONSE_FILE" 2>/dev/null || true)

  ERR_TITLE="${ERR_TITLE:-Error}"
  ERR_MSG="${ERR_MSG:-$(cat "$RESPONSE_FILE")}"

  echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG"
else
  echo "$HTTP_STATUS Error: Empty response from server."
fi

echo "::error title=Codacy Token Error::Failed to generate Codacy token."

exit 1
