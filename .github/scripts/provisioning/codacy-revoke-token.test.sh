#!/bin/bash
# =================================================================================
# Usage:       ./codacy-revoke-token.test.sh
# Description: Regression tests for codacy-revoke-token.sh; curl is stubbed.
# Example:     ./codacy-revoke-token.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/codacy-revoke-token.sh"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codacy-testlib.sh"

export CODACY_API_TOKEN=stub
export PATH="$CODACY_TEST_DIR/bin:$PATH"

run_case() {
  local name="$1" status="$2" body="$3" id="$4" expected_exit="$5" expected="$6"
  local owner="${7:-Flashky}"

  : > "$CODACY_CALLS"
  FAKE_CURL_STATUS="$status" FAKE_CURL_BODY="$body" \
    run_script "$TOKEN_SCRIPT" "$owner" advent-of-code-2026 "$id"
  local rc=$RUN_STATUS
  local output="$RUN_STDOUT $RUN_STDERR"

  if [ "$rc" -ne "$expected_exit" ]; then
    fail "$name" "exit $rc (esperado $expected_exit) -> $output"
  elif [ "$expected_exit" -ne 0 ] && [ -n "$RUN_STDOUT" ]; then
    fail "$name" "el error fue a stdout -> $RUN_STDOUT"
  elif [[ "$output" != *"$expected"* ]]; then
    fail "$name" "no contiene '$expected' -> $output"
  else
    pass "$name"
  fi
}

run_case "204 sin cuerpo" 204 "" 3753476 0 ""
run_case "200 con cuerpo" 200 '{}' 3753476 0 ""
run_case "404" 404 '{"error":"Not Found","message":"token not found"}' 3753476 1 "404 Not Found: token not found"
run_case "500 vacío" 500 '' 3753476 1 "Empty response from server."
run_case "id cero" 200 '{}' 0 1 "not a valid Codacy token id"
run_case "id negativo" 200 '{}' -1 1 "not a valid Codacy token id"
run_case "id no numérico" 200 '{}' abc 1 "not a valid Codacy token id"
run_case "owner inválido" 200 '{}' 3753476 1 "not a valid GitHub owner/repository name" "bad owner!"

: > "$CODACY_CALLS"
FAKE_CURL_STATUS=204 FAKE_CURL_BODY='' run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 3753476
expect_status "DELETE" 0
expect_stdout_is "DELETE" ""
expect_call "método de la petición" "METHOD=DELETE"
expect_call "id en la ruta" "/repositories/advent-of-code-2026/tokens/3753476"
expect_call_count "una sola llamada" "METHOD=" 1

finish
