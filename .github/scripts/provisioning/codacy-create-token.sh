#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.sh <owner> <repository-name> <name> <expiresAt>
# Description: Creates one project-level Codacy token with an explicit name and
#              expiry date. Only talks to the token-creation endpoint.
#              Requires jq: the response is parsed as JSON, not with grep/sed.
# Example:     ./codacy-create-token.sh Flashky advent-of-code-2026 aoc-advent-of-code-2026 2027-10-30T17:50:35Z
# =================================================================================

set -euo pipefail

GIT_PROVIDER="gh"
ORGANIZATION="${1:?Usage: $0 <owner> <repository-name> <name> <expiresAt>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name> <name> <expiresAt>}"
TOKEN_NAME="${3:?Usage: $0 <owner> <repository-name> <name> <expiresAt>}"
EXPIRES_AT="${4:?Usage: $0 <owner> <repository-name> <name> <expiresAt>}"

# Validations

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to build the request and parse the Codacy API response." >&2
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name." >&2
    exit 1
  }
done

# Codacy only accepts alphanumeric characters and dashes, up to 100 characters.
[[ "$TOKEN_NAME" =~ ^[A-Za-z0-9-]{1,100}$ ]] || {
  echo "::error title=Invalid Argument::'$TOKEN_NAME' is not a valid Codacy token name." >&2
  exit 1
}

# Codacy requires an ISO-8601 timestamp in the future and at most one year away.
if [[ ! "$EXPIRES_AT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$ ]]; then
  echo "::error title=Invalid Argument::'$EXPIRES_AT' is not a valid Codacy expiry timestamp." >&2
  exit 1
fi
EXPIRY_EPOCH=$(date -u -d "$EXPIRES_AT" +%s 2>/dev/null) || {
  echo "::error title=Invalid Argument::'$EXPIRES_AT' is not a valid Codacy expiry timestamp." >&2
  exit 1
}
NOW_EPOCH=$(date -u +%s)
if (( EXPIRY_EPOCH <= NOW_EPOCH || EXPIRY_EPOCH > NOW_EPOCH + 365 * 86400 )); then
  echo "::error title=Invalid Argument::'$EXPIRES_AT' must be in the future and no more than one year away." >&2
  exit 1
fi

# Temporary file to store the API response
RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

# Generate a token
# This script's stdout is the token and nothing else: the callers capture it in
# a variable, so anything written there is swallowed when the step fails. Every
# diagnostic, including workflow annotations, goes to stderr. The optional
# CODACY_TOKEN_STATE_FILE is a side channel for the caller's rollback step: the
# numeric id is not a secret and never goes to stdout.
REQUEST_BODY=$(jq -nc --arg name "$TOKEN_NAME" --arg expiresAt "$EXPIRES_AT" \
  '{name: $name, expiresAt: $expiresAt}')

HTTP_STATUS=$(curl -sS -X POST "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "api-token: $CODACY_API_TOKEN" \
     --data "$REQUEST_BODY" \
     -w "%{http_code}" \
     -o "$RESPONSE_FILE") || {
   rc=$?
   echo "::error title=Codacy API::Request to Codacy failed (curl exit $rc)" >&2
   exit 1
}

# Check results
if [[ "$HTTP_STATUS" =~ ^2[0-9]{2}$ ]]; then

  # `-s` slurps the body, so a stream of two documents is one value and not two:
  # the caller writes this token straight into `$GITHUB_OUTPUT`, where an extra
  # line would become an output nobody asked for. `jq -e` fails on malformed JSON
  # and on a missing field, and the token has to be a single run of printable
  # ASCII, so neither a newline nor a tab can get through.
  # Codacy wraps the created token in a `data` object; there is no flat `token`
  # at the top level. The slurp keeps the single-document check below: it also
  # rejects a response carrying two documents, which would otherwise inject an
  # extra line into $GITHUB_OUTPUT.
  if TOKEN=$(jq -ser 'if length == 1 then .[0].data.token | select(type == "string" and test("^[!-~]+$")) else empty end' "$RESPONSE_FILE" 2>/dev/null); then
    if [[ -n "${CODACY_TOKEN_STATE_FILE:-}" ]]; then
      TOKEN_ID=$(jq -sr 'if length == 1 then .[0].data.id | numbers else empty end' "$RESPONSE_FILE" 2>/dev/null || true)
      if [[ -n "$TOKEN_ID" ]]; then
        printf 'id=%s\n' "$TOKEN_ID" >> "$CODACY_TOKEN_STATE_FILE"
      fi
    fi
    echo "$TOKEN"
    exit 0
  fi

  echo "::error title=Codacy Token Error::Codacy returned HTTP $HTTP_STATUS without a usable token (invalid JSON, missing field or an unusable value)." >&2
  exit 1
fi

# Error cases - Log the error, flattened to a single line: a value carrying a
# newline would otherwise start a line of its own, and Actions would read what
# follows as a workflow command (`::warning::`, `::add-mask::`, ...).
if [ -s "$RESPONSE_FILE" ]; then
  ERR_TITLE=$(jq -r '(.error // empty) | strings | gsub("[[:cntrl:]]+"; " ")' "$RESPONSE_FILE" 2>/dev/null || true)
  ERR_MSG=$(jq -r '(.message // empty) | strings | gsub("[[:cntrl:]]+"; " ")' "$RESPONSE_FILE" 2>/dev/null || true)

  ERR_TITLE="${ERR_TITLE:-Error}"
  ERR_MSG="${ERR_MSG:-$(tr -s '[:space:]' ' ' < "$RESPONSE_FILE")}"

  echo "$HTTP_STATUS $ERR_TITLE: $ERR_MSG" >&2
else
  echo "$HTTP_STATUS Error: Empty response from server." >&2
fi

echo "::error title=Codacy Token Error::Failed to generate Codacy token." >&2

exit 1
