#!/bin/bash
# =================================================================================
# Usage:       ./dispatch-setup.sh <owner> <repository>
# Description: Dispatches the `Setup` workflow in the target repository. It is the
#              last step of the provisioning: everything else is in place by then.
# Example:     ./dispatch-setup.sh Flashky advent-of-code-2026
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

echo "Triggering 'Setup' workflow in $ORGANIZATION/$REPOSITORY..."
gh workflow run "Setup" --repo "$ORGANIZATION/$REPOSITORY"
echo "Setup workflow successfully triggered!"
