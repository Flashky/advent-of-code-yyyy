#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.test.sh
# Description: Regression tests for codacy-create-token.sh. Replaces curl with a
#              stub, so nothing leaves the machine.
# Example:     ./codacy-create-token.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/codacy-create-token.sh"
BASH_BIN=$(command -v bash)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codacy-testlib.sh"

export CODACY_API_TOKEN=stub
export PATH="$CODACY_TEST_DIR/bin:$PATH"
export FAKE_CURL_STATUS=200
export FAKE_CURL_BODY='{}'

EXPIRES=$(date -u -d '+364 days' +%Y-%m-%dT%H:%M:%SZ)

# run_case <name> <status> <body> <expected-exit> <expected> [exact] [forbidden] [run_path] [owner] [name] [expires]
run_case() {
  local name="$1" status="$2" body="$3" expected_exit="$4" expected="$5"
  local mode="${6:-substring}" forbidden="${7:-}"
  local run_path="${8:-$PATH}" owner="${9:-Flashky}"
  local token_name="${10:-aoc-advent-of-code-2026}" expires="${11:-$EXPIRES}"
  local output

  set +e
  PATH="$run_path" \
    FAKE_CURL_STATUS="$status" \
    FAKE_CURL_BODY="$body" \
    "$BASH_BIN" "$TOKEN_SCRIPT" "$owner" advent-of-code-2026 "$token_name" "$expires" \
    > "$CODACY_TEST_DIR/stdout" 2> "$CODACY_TEST_DIR/stderr"
  local rc=$?
  set -e
  output="$(cat "$CODACY_TEST_DIR/stdout") $(cat "$CODACY_TEST_DIR/stderr")"

  if [ "$rc" -ne "$expected_exit" ]; then
    fail "$name" "exit $rc (esperado $expected_exit) -> $output"
  elif [ "$expected_exit" -ne 0 ] && [ -s "$CODACY_TEST_DIR/stdout" ]; then
    fail "$name" "el error fue a stdout, donde el caller lo captura y pierde -> $(cat "$CODACY_TEST_DIR/stdout")"
  elif [ "$expected_exit" -eq 0 ] && [ -s "$CODACY_TEST_DIR/stderr" ]; then
    fail "$name" "el éxito escribió en stderr -> $(cat "$CODACY_TEST_DIR/stderr")"
  elif [ "$mode" = "exact" ] && [ "$(cat "$CODACY_TEST_DIR/stdout")" != "$expected" ]; then
    fail "$name" "stdout '$(cat "$CODACY_TEST_DIR/stdout")' (esperado exactamente '$expected')"
  elif [ "$mode" != "exact" ] && [[ "$output" != *"$expected"* ]]; then
    fail "$name" "no contiene '$expected' -> $output"
  elif [ -n "$forbidden" ] && grep -q "^${forbidden}" "$CODACY_TEST_DIR/stderr"; then
    fail "$name" "la stderr empieza una línea con '$forbidden' -> $(cat "$CODACY_TEST_DIR/stderr")"
  else
    pass "$name"
  fi
}

run_case "respuesta real de Codacy" 201 '{"data":{"id":3753476,"token":"REDACTED","name":"aoc-advent-of-code-2026","expiresAt":"2027-10-30T17:50:35.477430287Z","createdAt":"2026-10-30T17:50:35.479527937Z"}}' 0 "REDACTED" exact
run_case "token válido" 200 '{"data":{"token":"abc123","id":1}}' 0 "abc123" exact
run_case "token tras otras claves" 200 '{"data":{"expiresAt":"2027-01-01","token":"xyz789","id":2}}' 0 "xyz789" exact
run_case "token en la raíz" 200 '{"token":"abc123"}' 1 "without a usable token"
run_case "token ausente" 200 '{"data":{"id":3,"name":"pt-85976ce96e00"}}' 1 "without a usable token"
run_case "id ausente" 200 '{"data":{"token":"abc123"}}' 1 "numeric data.id"
run_case "id no numérico" 200 '{"data":{"token":"abc123","id":"7"}}' 1 "numeric data.id"
run_case "token nulo" 200 '{"data":{"token":null}}' 1 "without a usable token"
run_case "JSON malformado" 200 '{"data":{"token":"abc123"' 1 "without a usable token"
run_case "dos documentos JSON" 200 '{"data":{"token":"a"}} {"data":{"token":"b"}}' 1 "without a usable token"
run_case "token con salto de línea" 200 '{"data":{"token":"abc\nname=injected"}}' 1 "without a usable token"
run_case "token con tabulador" 200 '{"data":{"token":"abc\tdef"}}' 1 "without a usable token"
run_case "error de la API" 404 '{"error":"Not Found","message":"repository not found"}' 1 "404 Not Found: repository not found"
run_case "error con comando de workflow" 404 '{"error":"Not Found","message":"a\n::warning::b"}' 1 "404 Not Found: a ::warning::b"
run_case "error con objeto en error" 500 '{"error":{"code":1}}' 1 "500 Error:"
run_case "respuesta vacía" 500 '' 1 "Empty response from server."
run_case "jq ausente" 200 '{}' 1 "jq is required" substring "" "$CODACY_TEST_DIR/nojq"
run_case "argumento inválido" 200 '{}' 1 "is not a valid GitHub owner/repository name" substring "" "$PATH" "bad owner!"
run_case "nombre con espacio" 200 '{}' 1 "not a valid Codacy token name" substring "" "$PATH" Flashky "bad name!"
run_case "nombre demasiado largo" 200 '{}' 1 "not a valid Codacy token name" substring "" "$PATH" Flashky "$(printf 'a%.0s' {1..101})"
run_case "expiración pasada" 200 '{}' 1 "must be in the future" substring "" "$PATH" Flashky aoc-test "2020-01-01T00:00:00Z"
run_case "expiración demasiado lejana" 200 '{}' 1 "must be in the future" substring "" "$PATH" Flashky aoc-test "$(date -u -d '+366 days' +%Y-%m-%dT%H:%M:%SZ)"
run_case "expiración mal formada" 200 '{}' 1 "not a valid Codacy expiry timestamp" substring "" "$PATH" Flashky aoc-test "not-a-date"

: > "$CODACY_CALLS"
: > "$CODACY_BODIES"
export FAKE_CURL_STATUS=201
export FAKE_CURL_BODY='{"data":{"token":"new-token","id":7}}'
run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 aoc-advent-of-code-2026 "$EXPIRES"
expect_status "POST con body" 0
expect_stdout_is "POST con body" "new-token"
expect_call "método de la petición" "METHOD=POST"
expect_call "endpoint de creación" "/repositories/advent-of-code-2026/tokens"
expect_json_field "nombre en el body" "name" "aoc-advent-of-code-2026"
expect_json_field "caducidad en el body" "expiresAt" "$EXPIRES"

STATE_FILE="$CODACY_TEST_DIR/state"
: > "$STATE_FILE"
CODACY_TOKEN_STATE_FILE="$STATE_FILE" \
  run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 aoc-advent-of-code-2026 "$EXPIRES"
expect_status "canal de estado" 0
expect_stdout_is "canal de estado" "new-token"
if grep -qx 'id=7' "$STATE_FILE"; then
  pass "canal de estado: id"
else
  fail "canal de estado" "id no escrito -> $(cat "$STATE_FILE")"
fi

finish
