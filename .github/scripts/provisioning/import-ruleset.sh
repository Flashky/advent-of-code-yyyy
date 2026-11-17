#!/bin/bash
# =================================================================================
# Usage:       ./import-ruleset.sh <owner> <repository> <ruleset-file>
# Description: Imports the branch protection ruleset into the repository. If a
#              ruleset with the same name already exists it is updated in place,
#              which keeps the id (and anything referencing it) stable.
# Example:     ./import-ruleset.sh Flashky advent-of-code-2026 .github/settings/branch-protection-ruleset.json
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository> <ruleset-file>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"
RULESET_FILE="${3:?$USAGE}"

# Validations

: "${GH_TOKEN:?GH_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to read the ruleset file."
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

if [ ! -f "$RULESET_FILE" ]; then
  echo "::error title=Ruleset Missing::Ruleset file not found at $RULESET_FILE."
  exit 1
fi

FULL_NAME="$ORGANIZATION/$REPOSITORY"
RULESET_NAME=$(jq -r '.name' "$RULESET_FILE")

# Paginated: a repository can hold more rulesets than fit in one page.
RULESET_ID=$(gh api --paginate --slurp "repos/$FULL_NAME/rulesets" \
  | jq -r --arg name "$RULESET_NAME" 'first(.[][] | select(.name == $name) | .id) // empty')

if [ -n "$RULESET_ID" ]; then
  echo "Ruleset '$RULESET_NAME' already exists (id $RULESET_ID); updating it..."
  # source_type is read-only: the update endpoint rejects it.
  jq 'del(.source_type)' "$RULESET_FILE" \
    | gh api "repos/$FULL_NAME/rulesets/$RULESET_ID" --method PUT --input -
else
  echo "Importing branch protection ruleset into $REPOSITORY..."
  gh api "repos/$FULL_NAME/rulesets" --method POST --input "$RULESET_FILE"
fi

echo "Ruleset successfully applied!"
