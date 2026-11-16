#!/bin/bash
# =================================================================================
# Usage:       ./set-repository-secrets.sh <owner> <repository> [option]...
# Description: Stores repository secrets and variables. Each name is read from the
#              environment variable with the same name, so the workflow keeps
#              declaring the values and this script keeps working when a list
#              grows. Options:
#                --secret <NAME>             repository secret (Actions)
#                --variable <NAME>           repository variable (Actions)
#                --dependabot-secret <NAME>  repository secret for Dependabot
# Example:     ./set-repository-secrets.sh Flashky advent-of-code-2026 \
#                --secret AOC_CI_APP_CLIENT_ID --variable AOC_YEAR
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository> [--secret NAME]... [--variable NAME]... [--dependabot-secret NAME]..."
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"
shift 2

SECRETS=()
VARIABLES=()
DEPENDABOT_SECRETS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --secret)
      SECRETS+=("${2:?--secret needs a name}")
      shift 2
      ;;
    --variable)
      VARIABLES+=("${2:?--variable needs a name}")
      shift 2
      ;;
    --dependabot-secret)
      DEPENDABOT_SECRETS+=("${2:?--dependabot-secret needs a name}")
      shift 2
      ;;
    *)
      echo "::error title=Invalid Argument::Unknown option '$1'."
      exit 1
      ;;
  esac
done

if [ "${#SECRETS[@]}" -eq 0 ] && [ "${#VARIABLES[@]}" -eq 0 ] && [ "${#DEPENDABOT_SECRETS[@]}" -eq 0 ]; then
  echo "::error title=Invalid Argument::Nothing to set; pass at least one --secret, --variable or --dependabot-secret."
  exit 1
fi

# Validations

: "${GH_TOKEN:?GH_TOKEN is not set}"

for value in "$ORGANIZATION" "$REPOSITORY"; do
  [[ "$value" =~ ^[A-Za-z0-9_.-]+$ ]] || {
    echo "::error title=Invalid Argument::'$value' is not a valid GitHub owner/repository name."
    exit 1
  }
done

for name in "${SECRETS[@]}" "${VARIABLES[@]}" "${DEPENDABOT_SECRETS[@]}"; do
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    echo "::error title=Invalid Argument::'$name' is not a valid secret or variable name."
    exit 1
  }

  # Storing an empty value would silently break the workflow that reads it.
  [ -n "${!name:-}" ] || {
    echo "::error title=Missing Secret::$name is empty; refusing to store an empty value."
    exit 1
  }
done

FULL_NAME="$ORGANIZATION/$REPOSITORY"

if [ "${#SECRETS[@]}" -gt 0 ]; then
  echo "Setting secrets for Actions..."
  for name in "${SECRETS[@]}"; do
    gh secret set "$name" --repo "$FULL_NAME" --body "${!name}"
  done
fi

if [ "${#VARIABLES[@]}" -gt 0 ]; then
  echo "Setting variables for Actions..."
  for name in "${VARIABLES[@]}"; do
    gh variable set "$name" --repo "$FULL_NAME" --body "${!name}"
  done
fi

if [ "${#DEPENDABOT_SECRETS[@]}" -gt 0 ]; then
  echo "Setting secrets for Dependabot..."
  for name in "${DEPENDABOT_SECRETS[@]}"; do
    gh secret set "$name" --app dependabot --repo "$FULL_NAME" --body "${!name}"
  done
fi
