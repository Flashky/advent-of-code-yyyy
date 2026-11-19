#!/bin/bash
# =================================================================================
# Usage:       ./codacy-list-tokens.sh <owner> <repository-name>
# Description: Lists the project-level Codacy tokens of one repository. Only
#              talks to the token-listing endpoint.
# Example:     ./codacy-list-tokens.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

GIT_PROVIDER="gh"
ORGANIZATION="${1:?Usage: $0 <owner> <repository-name>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name>}"

# Validations

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to parse the Codacy API response." >&2
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name." >&2
    exit 1
  }
done

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_STATUS=$(curl -sS -X GET "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens" \
     -H "Accept: application/json" \
     -H "api-token: $CODACY_API_TOKEN" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE") || {
   rc=$?
   echo "::error title=Codacy API::Request to Codacy failed (curl exit $rc)" >&2
   exit 1
}

if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  # NDJSON: one compact object per line. The token is a secret, so the caller
  # must mask it; this script never copies it into a diagnostic.
  # Codacy reports pagination in the response but does not document a cursor
  # parameter for this endpoint; a repository has only a handful of tokens, so
  # the first page is sufficient here.
  jq -cr '.data[] | {id, name, token, expiresAt, createdAt}' "$RESPONSE_FILE" || {
    echo "::error title=Codacy Token Error::Codacy returned HTTP $HTTP_STATUS without a usable token list." >&2
    exit 1
  }
  exit 0
fi

if [ -s "$RESPONSE_FILE" ]; then
  ERR_TITLE=$(jq -r '(.error // empty) | strings | gsub("[[:cntrl:]]+"; " ")' "$RESPONSE_FILE" 2>/dev/null || true)
  ERR_MSG=$(jq -r '(.message // empty) | strings | gsub("[[:cntrl:]]+"; " ")' "$RESPONSE_FILE" 2>/dev/null || true)
  ERR_TITLE="${ERR_TITLE:-Error}"
  ERR_MSG="${ERR_MSG:-$(tr -s '[:space:]' ' ' < "$RESPONSE_FILE")}"
  echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG" >&2
else
  echo "$HTTP_STATUS Error: Empty response from server." >&2
fi

echo "::error title=Codacy Token Error::Failed to list Codacy tokens." >&2
exit 1
