#!/bin/bash
# =================================================================================
# Usage:       ./check-provisioning.sh <owner> <repository>
# Description: Read-only preflight for provisioning. Prints `true` when the
#              repository already exists, so the caller resumes; `false` when it
#              does not, so the caller creates it. Fails when a previous run
#              already completed Setup: a half-provisioned workshop is worth
#              retrying, a finished one is not. It never writes anything.
# Example:     ./check-provisioning.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"

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

FULL_NAME="$ORGANIZATION/$REPOSITORY"

if ERROR=$(gh api "repos/$FULL_NAME" --silent 2>&1); then
  # Paginated: a single page can miss the old Setup run in a busy repository.
  SETUP_SUCCESSES=$(gh api --paginate --slurp "repos/$FULL_NAME/actions/runs?per_page=100" \
    | jq '[.[].workflow_runs[] | select(.path == ".github/workflows/setup.yml" and .conclusion == "success")] | length')

  if [ "$SETUP_SUCCESSES" -gt 0 ]; then
    echo "::error title=Repository Already Provisioned::$FULL_NAME already ran Setup successfully. Nothing to provision; if the other repository failed, re-run only the failed jobs."
    exit 1
  fi

  # stderr: stdout is the answer the caller captures.
  echo "::warning title=Repository Already Exists::$FULL_NAME already exists; resuming its provisioning." >&2
  echo "true"
elif grep -q 'HTTP 404' <<< "$ERROR"; then
  echo "false"
else
  echo "::error title=Repository Lookup Failed::Could not check $FULL_NAME: $ERROR"
  exit 1
fi
