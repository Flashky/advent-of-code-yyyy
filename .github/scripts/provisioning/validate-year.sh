#!/bin/bash
# =================================================================================
# Usage:       ./validate-year.sh <year>
# Description: Validates the Advent of Code year and prints the lines the callers
#              redirect into their step outputs: the year and the two repository
#              names. Errors go to stderr, so a redirection never writes an
#              annotation into GITHUB_OUTPUT.
# Example:     ./validate-year.sh 2026 >> "$GITHUB_OUTPUT"
# =================================================================================

set -euo pipefail

YEAR="${1:-}"
CURRENT_YEAR=$(date +%Y)
MAX_YEAR=$((CURRENT_YEAR + 1))

if [[ -z "$YEAR" ]]; then
  echo "::error title=Missing Year::No year input provided and AOC_YEAR variable is not set." >&2
  exit 1
fi

if [[ ! "$YEAR" =~ ^[0-9]{4}$ ]]; then
  echo "::error title=Invalid Year::Please provide a valid 4-digit year (e.g., $CURRENT_YEAR)." >&2
  exit 1
fi

# 10# forces base 10 so values like 0999 are not parsed as octal
YEAR_NUM=$((10#$YEAR))

if (( YEAR_NUM < 2015 || YEAR_NUM > MAX_YEAR )); then
  echo "::error title=Invalid Year::Year must be between 2015 and $MAX_YEAR." >&2
  exit 1
fi

echo "year=$YEAR"
echo "repo_name_solutions=advent-of-code-$YEAR"
echo "repo_name_data=advent-of-code-$YEAR-data"
