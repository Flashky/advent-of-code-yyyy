#!/bin/bash
# =================================================================================
# Usage:       ./fetch-codacy-badges.sh <owner> <repository>
# Description: Reads the badge URLs of the Codacy project and prints the lines the
#              caller redirects into its step outputs: `skip_badges=true` when
#              Codacy has no badges yet, or `skip_badges=false` plus the two URLs.
#              Warnings go to stderr.
# Example:     ./fetch-codacy-badges.sh Flashky advent-of-code-2026 >> "$GITHUB_OUTPUT"
# =================================================================================

set -euo pipefail

USAGE="Usage: $0 <owner> <repository>"
ORGANIZATION="${1:?$USAGE}"
REPOSITORY="${2:?$USAGE}"

# Validations

: "${CODACY_PROJECT_TOKEN:?CODACY_PROJECT_TOKEN is not set}"

command -v jq > /dev/null 2>&1 || {
  echo "::error title=Missing Tool::jq is required to read the Codacy response." >&2
  exit 1
}

RESPONSE=$(curl -s --request GET \
  --url "https://app.codacy.com/api/v3/organizations/gh/$ORGANIZATION/repositories/$REPOSITORY" \
  --header "project-token: $CODACY_PROJECT_TOKEN")

GRADE_URL=$(jq -r '.data.badges.grade // empty' <<< "$RESPONSE")
COVERAGE_URL=$(jq -r '.data.badges.coverage // empty' <<< "$RESPONSE")

if [ -z "$GRADE_URL" ] || [ -z "$COVERAGE_URL" ]; then
  echo "::warning title=Codacy Badges Missing::Could not fetch badge URLs from Codacy API. Skipping badge injection." >&2
  echo "skip_badges=true"
  exit 0
fi

echo "skip_badges=false"
echo "grade_url=$GRADE_URL"
echo "coverage_url=$COVERAGE_URL"
