#!/bin/bash
# =================================================================================
# Usage:       ./codacy-revoke-token.sh <owner> <repository-name> <token-id>
# Description: Revokes one project-level Codacy token by its numeric id. Only
#              talks to the token-deletion endpoint.
# Example:     ./codacy-revoke-token.sh Flashky advent-of-code-2026 3753476
# =================================================================================

set -euo pipefail

GIT_PROVIDER="gh"
ORGANIZATION="${1:?Usage: $0 <owner> <repository-name> <token-id>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name> <token-id>}"
TOKEN_ID="${3:?Usage: $0 <owner> <repository-name> <token-id>}"

# Validations

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name." >&2
    exit 1
  }
done

[[ "$TOKEN_ID" =~ ^[1-9][0-9]*$ ]] || {
  echo "::error title=Invalid Argument::'$TOKEN_ID' is not a valid Codacy token id." >&2
  exit 1
}

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_STATUS=$(curl -sS -X DELETE "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens/$TOKEN_ID" \
     -H "Accept: application/json" \
     -H "api-token: $CODACY_API_TOKEN" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE") || {
   rc=$?
   echo "::error title=Codacy API::Request to Codacy failed (curl exit $rc)" >&2
   exit 1
}

if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then
  # stdout stays empty: this script reports success through its exit status.
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

echo "::error title=Codacy Token Error::Failed to revoke Codacy token $TOKEN_ID." >&2
exit 1
