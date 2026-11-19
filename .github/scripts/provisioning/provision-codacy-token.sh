#!/bin/bash
# =================================================================================
# Usage:       ./provision-codacy-token.sh <owner> <repository-name>
# Description: Resolves the Codacy token for one repository: reuses the token
#              named aoc-<repository> while it is valid, revokes it and creates
#              a replacement when it has expired, and creates it when absent.
#              Prints the chosen token and nothing else to stdout. It does NOT
#              write the repository secret; that is a workflow step.
#              CODACY_TOKEN_STATE_FILE, when set, is truncated at the start and
#              receives `id=<id>` when a new token is created, so a workflow can
#              roll it back if a later step fails before writing the secret.
# Example:     ./provision-codacy-token.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

ORGANIZATION="${1:?Usage: $0 <owner> <repository-name>}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name>}"

: "${CODACY_API_TOKEN:?CODACY_API_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to compare the Codacy tokens." >&2
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name." >&2
    exit 1
  }
done

# Call the single-endpoint scripts by name. CODACY_SCRIPTS_DIR exists so the
# tests can point these calls at stubs without touching the real scripts.
SCRIPT_DIR="${CODACY_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export PATH="$SCRIPT_DIR:$PATH"

for helper in codacy-list-tokens.sh codacy-revoke-token.sh codacy-create-token.sh; do
  command -v "$helper" > /dev/null 2>&1 || {
    echo "::error title=Missing Tool::$helper is required." >&2
    exit 1
  }
done

if [[ -n "${CODACY_TOKEN_STATE_FILE:-}" ]]; then
  : > "$CODACY_TOKEN_STATE_FILE"
fi

TOKENS_FILE=$(mktemp)
trap 'rm -f "$TOKENS_FILE"' EXIT

codacy-list-tokens.sh "$ORGANIZATION" "$REPOSITORY" > "$TOKENS_FILE"

# Codacy token names allow only letters, digits and dashes. Repositories may
# legitimately use dots or underscores, so normalise those and keep the whole
# name within Codacy's 100-character limit (4 for the `aoc-` prefix).
SAFE_REPOSITORY=$(printf '%s' "$REPOSITORY" | tr '._' '--' | cut -c1-96)
TOKEN_NAME="aoc-$SAFE_REPOSITORY"

# Codacy enforces a unique token name per repository, but picking the newest
# createdAt keeps the choice deterministic if that ever changes.
MATCH=$(jq -sr --arg name "$TOKEN_NAME" \
  '[.[] | select(.name == $name)] | sort_by(.createdAt // "") | last // empty' \
  "$TOKENS_FILE")

is_live() {
  local expires_at="$1" epoch
  [[ "$expires_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$ ]] || return 1
  epoch=$(date -u -d "$expires_at" +%s 2>/dev/null) || return 1
  (( epoch > $(date -u +%s) ))
}

is_expired() {
  local expires_at="$1" epoch
  [[ "$expires_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$ ]] || return 1
  epoch=$(date -u -d "$expires_at" +%s 2>/dev/null) || return 1
  (( epoch <= $(date -u +%s) ))
}

if [[ -n "$MATCH" ]]; then
  TOKEN=$(jq -r '.token // empty' <<< "$MATCH")
  MATCH_EXPIRES=$(jq -r '.expiresAt // empty' <<< "$MATCH")
  if [[ -n "$TOKEN" ]] && is_live "$MATCH_EXPIRES"; then
    echo "$TOKEN"
    exit 0
  fi

  # Only revoke once expiry is confirmed. A missing token value or an
  # unparseable expiry is not proof that the token is dead: revoking it and
  # then failing to create a replacement would break the stored secret.
  if ! is_expired "$MATCH_EXPIRES"; then
    echo "::error title=Codacy Token Error::Cannot confirm that $TOKEN_NAME has expired; refusing to revoke it." >&2
    exit 1
  fi

  # The name is unique in Codacy: the expired token has to go before a new one
  # with the same name can be created (otherwise POST returns HTTP 400).
  TOKEN_ID=$(jq -r '.id // empty' <<< "$MATCH")
  if [[ -z "$TOKEN_ID" ]]; then
    echo "::error title=Codacy Token Error::The existing $TOKEN_NAME token has no id to revoke." >&2
    exit 1
  fi
  echo "Codacy token $TOKEN_NAME has expired; revoking id $TOKEN_ID before creating a replacement." >&2
  codacy-revoke-token.sh "$ORGANIZATION" "$REPOSITORY" "$TOKEN_ID"
fi

# 364 days, not 365, to stay inside Codacy's "no more than one year" rule.
EXPIRES_AT=$(date -u -d '+364 days' +%Y-%m-%dT%H:%M:%SZ)
codacy-create-token.sh "$ORGANIZATION" "$REPOSITORY" "$TOKEN_NAME" "$EXPIRES_AT"
