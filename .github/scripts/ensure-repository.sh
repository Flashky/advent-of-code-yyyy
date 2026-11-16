#!/bin/bash
# =================================================================================
# Usage:       ./ensure-repository.sh <owner> <repository> <template> <public|private>
# Description: Creates the repository from a template, or resumes its provisioning
#              when it already exists. Refuses to continue when a previous run
#              already completed Setup there: a half-provisioned workshop is worth
#              retrying, a finished one is not.
# Example:     ./ensure-repository.sh Flashky advent-of-code-2026 Flashky/advent-of-code-yyyy public
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository> <template> <public|private>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"
TEMPLATE="${3:?$USAGE}"
VISIBILITY="${4:?$USAGE}"

# Validations

: "${GH_TOKEN:?GH_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to parse the GitHub API response."
  exit 1
}

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

[[ "$TEMPLATE" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || {
  echo "::error title=Invalid Argument::'$TEMPLATE' is not a valid template repository (owner/name)."
  exit 1
}

case "$VISIBILITY" in
  public | private) ;;
  *)
    echo "::error title=Invalid Argument::Visibility must be 'public' or 'private' (got '$VISIBILITY')."
    exit 1
    ;;
esac

FULL_NAME="$ORGANIZATION/$REPOSITORY"

if ERROR=$(gh api "repos/$FULL_NAME" --silent 2>&1); then
  # Paginated: a single page can miss the old Setup run in a busy repository.
  SETUP_SUCCESSES=$(gh api --paginate --slurp "repos/$FULL_NAME/actions/runs?per_page=100" \
    | jq '[.[].workflow_runs[] | select(.path == ".github/workflows/setup.yml" and .conclusion == "success")] | length')

  if [ "$SETUP_SUCCESSES" -gt 0 ]; then
    echo "::error title=Repository Already Provisioned::$FULL_NAME already ran Setup successfully. Nothing to provision; if the other repository failed, re-run only the failed jobs."
    exit 1
  fi

  echo "::warning title=Repository Already Exists::$FULL_NAME already exists; resuming its provisioning."
elif grep -q 'HTTP 404' <<< "$ERROR"; then
  echo "Creating repository $FULL_NAME from template $TEMPLATE..."
  gh repo create "$REPOSITORY" --template "$TEMPLATE" "--$VISIBILITY"
else
  echo "::error title=Repository Lookup Failed::Could not check $FULL_NAME: $ERROR"
  exit 1
fi
