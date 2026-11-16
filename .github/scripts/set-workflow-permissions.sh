#!/bin/bash
# =================================================================================
# Usage:       ./set-workflow-permissions.sh <owner> <repository>
# Description: Lets the Actions workflows write and approve pull requests. Without
#              this the setup pull request cannot be approved by a workflow, and
#              the `build-report` job cannot push the coverage report.
# Example:     ./set-workflow-permissions.sh Flashky advent-of-code-2026
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

echo "Configuring workflow permissions for $REPOSITORY..."
gh api --method PUT "repos/$ORGANIZATION/$REPOSITORY/actions/permissions/workflow" \
  -F default_workflow_permissions="write" \
  -F can_approve_pull_request_reviews=true
