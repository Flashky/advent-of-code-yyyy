#!/bin/bash
# =================================================================================
# Usage:       ./set-environment-secrets.sh <owner> <repository>
# Description: Stores the GitHub App credentials on the `workshop` environment, so
#              the jobs that declare that environment can mint tokens. The values
#              come from AOC_APP_CLIENT_ID and AOC_APP_PRIVATE_KEY.
# Example:     ./set-environment-secrets.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"

# Validations

: "${GH_TOKEN:?GH_TOKEN is not set}"
: "${AOC_APP_CLIENT_ID:?AOC_APP_CLIENT_ID is not set}"
: "${AOC_APP_PRIVATE_KEY:?AOC_APP_PRIVATE_KEY is not set}"

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

FULL_NAME="$ORGANIZATION/$REPOSITORY"

echo "Setting secrets for Workshop..."
gh secret set AOC_APP_CLIENT_ID --env workshop --repo "$FULL_NAME" --body "$AOC_APP_CLIENT_ID"
gh secret set AOC_APP_PRIVATE_KEY --env workshop --repo "$FULL_NAME" --body "$AOC_APP_PRIVATE_KEY"
