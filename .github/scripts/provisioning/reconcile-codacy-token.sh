#!/bin/bash
# =================================================================================
# Usage:       ./reconcile-codacy-token.sh <owner> <repository-name> <keep-token> [--dry-run]
# Description: Leaves exactly one Codacy token in the repository: the one whose
#              value is keep-token. Every other token is revoked by id. It does
#              not create tokens and it does not read repository secrets.
#              With --dry-run it only reports what it would revoke.
# Example:     ./reconcile-codacy-token.sh Flashky advent-of-code-2026 "$TOKEN" --dry-run
# =================================================================================

set -euo pipefail

ORGANIZATION="${1:?Usage: $0 <owner> <repository-name> <keep-token> [--dry-run]}"
REPOSITORY="${2:?Usage: $0 <owner> <repository-name> <keep-token> [--dry-run]}"
shift 2

KEEP_TOKEN=""
DRY_RUN=0
for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=1 ;;
    *)
      if [[ -n "$KEEP_TOKEN" ]]; then
        echo "::error title=Invalid Argument::Unexpected argument '$argument'." >&2
        exit 1
      fi
      KEEP_TOKEN="$argument"
      ;;
  esac
done
[[ -n "$KEEP_TOKEN" ]] || {
  echo "::error title=Invalid Argument::A token to keep is required." >&2
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name." >&2
    exit 1
  }
done

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to compare the Codacy tokens." >&2
  exit 1
}

# Call the single-endpoint scripts through bash: the repository keeps them
# non-executable, so invoking them by name would fail with permission denied.
# CODACY_SCRIPTS_DIR exists so the tests can point these calls at stubs.
SCRIPT_DIR="${CODACY_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

for helper in codacy-list-tokens.sh codacy-revoke-token.sh; do
  [[ -f "$SCRIPT_DIR/$helper" ]] || {
    echo "::error title=Missing Tool::$helper is required." >&2
    exit 1
  }
done

TOKENS_FILE=$(mktemp)
trap 'rm -f "$TOKENS_FILE"' EXIT

bash "$SCRIPT_DIR/codacy-list-tokens.sh" "$ORGANIZATION" "$REPOSITORY" > "$TOKENS_FILE"

# Fail safe: an empty or stale keep-token must never turn into a mass revocation.
if ! jq -se --arg token "$KEEP_TOKEN" 'any(.[]; .token == $token)' "$TOKENS_FILE" > /dev/null; then
  echo "::error title=Codacy Token Error::The token to keep is not present in $ORGANIZATION/$REPOSITORY; nothing was revoked." >&2
  exit 1
fi

while IFS= read -r line; do
  TOKEN_VALUE=$(jq -r '.token // empty' <<< "$line")
  [[ "$TOKEN_VALUE" == "$KEEP_TOKEN" ]] && continue

  TOKEN_ID=$(jq -r '.id // empty' <<< "$line")
  TOKEN_NAME=$(jq -r '.name // empty' <<< "$line")
  if [[ -z "$TOKEN_ID" ]]; then
    echo "::error title=Codacy Token Error::Token '$TOKEN_NAME' has no id; cannot revoke it." >&2
    exit 1
  fi

  if (( DRY_RUN )); then
    echo "Would revoke $TOKEN_NAME (id $TOKEN_ID) from $ORGANIZATION/$REPOSITORY." >&2
  else
    echo "Revoking $TOKEN_NAME (id $TOKEN_ID) from $ORGANIZATION/$REPOSITORY." >&2
    bash "$SCRIPT_DIR/codacy-revoke-token.sh" "$ORGANIZATION" "$REPOSITORY" "$TOKEN_ID"
  fi
done < "$TOKENS_FILE"
