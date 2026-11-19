#!/bin/bash
# =================================================================================
# Usage:       ./codacy-list-tokens.test.sh
# Description: Regression tests for codacy-list-tokens.sh; curl is stubbed.
# Example:     ./codacy-list-tokens.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/codacy-list-tokens.sh"
BASH_BIN=$(command -v bash)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codacy-testlib.sh"

export CODACY_API_TOKEN=stub
export PATH="$CODACY_TEST_DIR/bin:$PATH"

# Invoke the script directly (not via run_script) so a PATH without jq can be
# exercised without breaking the harness's own mktemp/rm calls.
run_case() {
  local name="$1" status="$2" body="$3" expected_exit="$4" expected="$5"
  local mode="${6:-substring}" run_path="${7:-$PATH}" owner="${8:-Flashky}"
  local rc stdout stderr output

  : > "$CODACY_CALLS"
  set +e
  PATH="$run_path" FAKE_CURL_STATUS="$status" FAKE_CURL_BODY="$body" \
    "$BASH_BIN" "$TOKEN_SCRIPT" "$owner" advent-of-code-2026 \
    > "$CODACY_TEST_DIR/stdout" 2> "$CODACY_TEST_DIR/stderr"
  rc=$?
  set -e
  stdout=$(cat "$CODACY_TEST_DIR/stdout")
  stderr=$(cat "$CODACY_TEST_DIR/stderr")
  output="$stdout $stderr"

  if [ "$rc" -ne "$expected_exit" ]; then
    fail "$name" "exit $rc (esperado $expected_exit) -> $output"
  elif [ "$expected_exit" -ne 0 ] && [ -n "$stdout" ]; then
    fail "$name" "el error fue a stdout -> $stdout"
  elif [ "$mode" = "exact" ] && [ "$stdout" != "$expected" ]; then
    fail "$name" "stdout '$stdout' (esperado exactamente '$expected')"
  elif [ "$mode" != "exact" ] && [[ "$output" != *"$expected"* ]]; then
    fail "$name" "no contiene '$expected' -> $output"
  else
    pass "$name"
  fi
}

TWO_TOKENS='{"pagination":{"cursor":"","limit":10,"total":2},"data":[{"id":1,"name":"aoc-advent-of-code-2026","token":"tok-1","expiresAt":"2027-01-01T00:00:00Z","createdAt":"2026-01-01T00:00:00Z"},{"id":2,"name":"pt-abc","token":"tok-2","expiresAt":"2027-02-01T00:00:00Z","createdAt":"2026-02-01T00:00:00Z"}]}'
EXPECTED_TWO='{"id":1,"name":"aoc-advent-of-code-2026","token":"tok-1","expiresAt":"2027-01-01T00:00:00Z","createdAt":"2026-01-01T00:00:00Z"}
{"id":2,"name":"pt-abc","token":"tok-2","expiresAt":"2027-02-01T00:00:00Z","createdAt":"2026-02-01T00:00:00Z"}'

run_case "dos tokens en NDJSON" 200 "$TWO_TOKENS" 0 "$EXPECTED_TWO" exact
run_case "listado vacío" 200 '{"pagination":{"cursor":"","limit":10,"total":0},"data":[]}' 0 "" exact
run_case "token sin createdAt" 200 '{"data":[{"id":3,"name":"pt-old","token":"tok-3","expiresAt":"2027-01-01T00:00:00Z"}]}' 0 '"createdAt":null'
run_case "sin campo data" 200 '{"pagination":{"total":0}}' 1 "not an array"
run_case "data es objeto" 200 '{"data":{"id":1,"token":"tok-1"}}' 1 "not an array"
run_case "pagina incompleta" 200 '{"pagination":{"total":2},"data":[{"id":1,"name":"aoc-advent-of-code-2026","token":"tok-1","expiresAt":"2027-01-01T00:00:00Z","createdAt":"2026-01-01T00:00:00Z"}]}' 1 "incomplete list"
run_case "JSON malformado" 200 '{"data":[' 1 "not an array"
run_case "401" 401 '{"error":"Unauthorized","message":"bad token"}' 1 "401 Unauthorized: bad token"
run_case "500 vacío" 500 '' 1 "Empty response from server."
run_case "jq ausente" 200 "$TWO_TOKENS" 1 "jq is required" substring "$CODACY_TEST_DIR/nojq"
run_case "owner inválido" 200 "$TWO_TOKENS" 1 "not a valid GitHub owner/repository name" substring "$PATH" "bad owner!"

: > "$CODACY_CALLS"
FAKE_CURL_STATUS=200 FAKE_CURL_BODY="$TWO_TOKENS" \
  run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026
expect_status "GET" 0
expect_call "método de la petición" "METHOD=GET"
expect_call "endpoint de listado" "/repositories/advent-of-code-2026/tokens"
expect_call_count "una sola llamada" "METHOD=" 1

finish
