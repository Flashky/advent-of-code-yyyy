#!/bin/bash
# =================================================================================
# Usage:       ./validate-year.test.sh
# Description: A valid year prints exactly the three output lines and nothing on
#              stderr. Every rejection names the reason on stderr and leaves
#              stdout empty, so redirecting it never pollutes GITHUB_OUTPUT.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"

CURRENT_YEAR=$(date +%Y)
MAX_YEAR=$((CURRENT_YEAR + 1))

run_script "$SCRIPT_DIR/validate-year.sh" "$CURRENT_YEAR"
expect_status "año válido: exit" 0
expect_stdout_is "año válido: stdout exacto" "year=$CURRENT_YEAR
repo_name_solutions=advent-of-code-$CURRENT_YEAR
repo_name_data=advent-of-code-$CURRENT_YEAR-data"
expect_no_stderr "año válido: no avisa"

run_script "$SCRIPT_DIR/validate-year.sh" "$MAX_YEAR"
expect_status "año siguiente: exit" 0
expect_stdout "año siguiente: lo acepta" "year=$MAX_YEAR"
expect_no_stderr "año siguiente: no avisa"

run_script "$SCRIPT_DIR/validate-year.sh"
expect_status "sin argumento: exit" 1
expect_stdout_is "sin argumento: stdout vacío" ""
expect_stderr "sin argumento: lo dice" "::error title=Missing Year::"

run_script "$SCRIPT_DIR/validate-year.sh" ""
expect_status "argumento vacío: exit" 1
expect_stderr "argumento vacío: lo dice" "::error title=Missing Year::"

run_script "$SCRIPT_DIR/validate-year.sh" 26
expect_status "dos cifras: exit" 1
expect_stdout_is "dos cifras: stdout vacío" ""
expect_stderr "dos cifras: lo dice" "Please provide a valid 4-digit year"

run_script "$SCRIPT_DIR/validate-year.sh" 20261
expect_status "cinco cifras: exit" 1
expect_stderr "cinco cifras: lo dice" "Please provide a valid 4-digit year"

run_script "$SCRIPT_DIR/validate-year.sh" 1999
expect_status "demasiado antiguo: exit" 1
expect_stderr "demasiado antiguo: lo dice" "Year must be between 2015 and $MAX_YEAR."

run_script "$SCRIPT_DIR/validate-year.sh" "$((MAX_YEAR + 1))"
expect_status "demasiado nuevo: exit" 1
expect_stderr "demasiado nuevo: lo dice" "Year must be between 2015 and $MAX_YEAR."

# 0999 is four digits: without the 10# guard bash would try to read it as octal
# and fail with a different error.
run_script "$SCRIPT_DIR/validate-year.sh" 0999
expect_status "con ceros: exit" 1
expect_stderr "con ceros: lo dice" "Year must be between 2015 and $MAX_YEAR."

finish
