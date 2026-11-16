#!/bin/bash
# =================================================================================
# Usage:       ./set-repository-secrets.test.sh
# Description: One call per value, grouped by destination, and no call at all when
#              a value is empty or the options do not make sense. `gh` is stubbed.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/testlib.sh"

setup_stub
GH_TOKEN=stub
AOC_CI_APP_CLIENT_ID=client
AOC_CI_APP_PRIVATE_KEY=key
CODACY_PROJECT_TOKEN=codacy
AOC_YEAR=2026
export GH_TOKEN AOC_CI_APP_CLIENT_ID AOC_CI_APP_PRIVATE_KEY CODACY_PROJECT_TOKEN AOC_YEAR

run_script "$SCRIPT_DIR/set-repository-secrets.sh" Flashky repo \
  --secret AOC_CI_APP_CLIENT_ID \
  --secret AOC_CI_APP_PRIVATE_KEY \
  --secret CODACY_PROJECT_TOKEN \
  --variable AOC_YEAR \
  --dependabot-secret AOC_CI_APP_CLIENT_ID \
  --dependabot-secret AOC_CI_APP_PRIVATE_KEY \
  --dependabot-secret CODACY_PROJECT_TOKEN
expect_status "repositorio de soluciones" 0
expect_output "repositorio de soluciones" "Setting secrets for Actions..."
expect_output "repositorio de soluciones" "Setting variables for Actions..."
expect_output "repositorio de soluciones" "Setting secrets for Dependabot..."
expect_call "repositorio de soluciones" "secret set AOC_CI_APP_CLIENT_ID --repo Flashky/repo --body client"
expect_call "repositorio de soluciones" "variable set AOC_YEAR --repo Flashky/repo --body 2026"
expect_call "repositorio de soluciones" "secret set CODACY_PROJECT_TOKEN --app dependabot --repo Flashky/repo --body codacy"

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/set-repository-secrets.sh" Flashky repo --variable AOC_YEAR
expect_status "solo la variable (repo de datos)" 0
expect_output "solo la variable (repo de datos)" "Setting variables for Actions..."
expect_no_output "solo la variable (repo de datos)" "Setting secrets for Actions"
expect_call "solo la variable (repo de datos)" "variable set AOC_YEAR --repo Flashky/repo --body 2026"

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/set-repository-secrets.sh" Flashky repo --secret EMPTY_VALUE --variable AOC_YEAR
expect_status "valor vacío" 1
expect_output "valor vacío" "EMPTY_VALUE is empty; refusing to store an empty value."
expect_no_call "valor vacío" "secret set"

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/set-repository-secrets.sh" Flashky repo --token AOC_YEAR
expect_status "opción desconocida" 1
expect_output "opción desconocida" "Unknown option '--token'"

: > "$GH_CALLS"
run_script "$SCRIPT_DIR/set-repository-secrets.sh" Flashky repo
expect_status "sin opciones" 1
expect_output "sin opciones" "Nothing to set"
expect_no_call "sin opciones" "secret"

finish
