#!/bin/bash
# =================================================================================
# Usage:       ./provision-environment.sh <owner> <repository>
# Description: Creates or updates the `workshop` environment and its `master`
#              branch policy. Idempotent: an existing policy is left untouched.
# Example:     ./provision-environment.sh Flashky advent-of-code-2026
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

FULL_NAME="$ORGANIZATION/$REPOSITORY"
ENVIRONMENT_URL="repos/$FULL_NAME/environments/workshop"

echo "Setting branch policies to workshop..."
gh api --method PUT "$ENVIRONMENT_URL" \
  -F 'deployment_branch_policy[custom_branch_policies]=true' \
  -F 'deployment_branch_policy[protected_branches]=false'

MASTER_POLICY_ID=$(gh api "$ENVIRONMENT_URL/deployment-branch-policies" \
  --jq '.branch_policies[] | select(.name == "master") | .id')

if [ -n "$MASTER_POLICY_ID" ]; then
  echo "The master branch policy already exists (id $MASTER_POLICY_ID); leaving it untouched."
else
  echo "Setting restrictions to master branch..."
  gh api --method POST "$ENVIRONMENT_URL/deployment-branch-policies" \
    -f name=master -f type=branch
fi
