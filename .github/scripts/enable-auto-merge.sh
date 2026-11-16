#!/bin/bash
# =================================================================================
# Usage:       ./enable-auto-merge.sh <owner> <repository>
# Description: Enables auto-merge on the repository, which the setup pull request
#              needs to merge itself once the checks pass.
# Example:     ./enable-auto-merge.sh Flashky advent-of-code-2026
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"

# Validations

: "${GH_TOKEN:?GH_TOKEN is not set}"

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

echo "Enabling auto-merge for $REPOSITORY..."
gh api "repos/$ORGANIZATION/$REPOSITORY" -X PATCH -F allow_auto_merge=true
