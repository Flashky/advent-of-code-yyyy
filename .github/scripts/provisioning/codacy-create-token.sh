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
# This script's stdout is the token and nothing else: the callers capture it in
# a variable, so anything written there is swallowed when the step fails. Every
# diagnostic, including workflow annotations, goes to stderr.
HTTP_STATUS=$(curl -sSX POST "https://app.codacy.com/api/v3/organizations/$GIT_PROVIDER/$ORGANIZATION/repositories/$REPOSITORY/tokens" \
     -H "api-token: $CODACY_API_TOKEN" \
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
  if TOKEN=$(jq -ser 'if length == 1 then .[0].token | select(type == "string" and test("^[!-~]+$")) else empty end' "$RESPONSE_FILE" 2>/dev/null); then
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
