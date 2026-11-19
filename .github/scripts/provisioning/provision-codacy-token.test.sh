#!/bin/bash
# =================================================================================
# Usage:       ./provision-codacy-token.test.sh
# Description: Tests for provision-codacy-token.sh. The three single-endpoint
#              scripts are stubbed, so no request leaves the machine and the
#              order of the calls can be asserted.
# Example:     ./provision-codacy-token.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/provision-codacy-token.sh"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codacy-testlib.sh"

export CODACY_API_TOKEN=stub
export CODACY_SCRIPTS_DIR="$CODACY_TEST_DIR/stubs"

# Relative fixtures: fixed dates eventually turn a "live" token into an expired
# one (or move an out-of-range expiry inside the one-year window).
LIVE_EXPIRY=$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ)
EXPIRED_EXPIRY=$(date -u -d '-30 days' +%Y-%m-%dT%H:%M:%SZ)
OLD_CREATED=$(date -u -d '-60 days' +%Y-%m-%dT%H:%M:%SZ)
NEW_CREATED=$(date -u -d '-30 days' +%Y-%m-%dT%H:%M:%SZ)
LIVE="{\"id\":1,\"name\":\"aoc-advent-of-code-2026\",\"token\":\"tok-live\",\"expiresAt\":\"$LIVE_EXPIRY\",\"createdAt\":\"$OLD_CREATED\"}"
EXPIRED="{\"id\":2,\"name\":\"aoc-advent-of-code-2026\",\"token\":\"tok-expired\",\"expiresAt\":\"$EXPIRED_EXPIRY\",\"createdAt\":\"$OLD_CREATED\"}"
OLD_NAMED="{\"id\":4,\"name\":\"aoc-advent-of-code-2026\",\"token\":\"tok-old\",\"expiresAt\":\"$LIVE_EXPIRY\",\"createdAt\":\"$OLD_CREATED\"}"
NEW_NAMED="{\"id\":5,\"name\":\"aoc-advent-of-code-2026\",\"token\":\"tok-newest\",\"expiresAt\":\"$LIVE_EXPIRY\",\"createdAt\":\"$NEW_CREATED\"}"

# run_provision <name> <list-ndjson>
run_provision() {
  : > "$CODACY_CALLS"
  FAKE_LIST="$2" FAKE_CREATE_TOKEN=new-token FAKE_CREATE_ID=9 \
    run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026
  pass "$1: ejecutado"
}

run_provision "token vigente" "$LIVE"
expect_status "token vigente" 0
expect_stdout_is "token vigente" "tok-live"
expect_call_count "token vigente sin POST" "create " 0
expect_call_count "token vigente sin DELETE" "revoke " 0
expect_call_count "token vigente consulta la lista" "list " 1

STATE_FILE="$CODACY_TEST_DIR/state"
printf 'id=999\n' > "$STATE_FILE"
: > "$CODACY_CALLS"
CODACY_TOKEN_STATE_FILE="$STATE_FILE" FAKE_LIST="$LIVE" FAKE_CREATE_TOKEN=new-token \
  run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026
expect_status "estado se limpia al reutilizar" 0
if [[ ! -s "$STATE_FILE" ]]; then
  pass "estado se limpia al reutilizar"
else
  fail "estado se limpia al reutilizar" "quedó $(cat "$STATE_FILE")"
fi

run_provision "sin tokens" ""
expect_status "sin tokens" 0
expect_stdout_is "sin tokens" "new-token"
expect_call_count "sin tokens crea una" "create " 1
expect_call_count "sin tokens no revoca" "revoke " 0
expect_call "sin tokens usa el nombre determinista" "create Flashky advent-of-code-2026 aoc-advent-of-code-2026 "

run_provision "token caducado" "$EXPIRED"
expect_status "token caducado" 0
expect_stdout_is "token caducado" "new-token"
expect_call_count "token caducado revoca" "revoke " 1
expect_call_count "token caducado crea" "create " 1
expect_order "token caducado" "revoke " "create "
expect_call "token caducado revoca por id" "revoke Flashky advent-of-code-2026 2"

run_provision "varios con el mismo nombre" "$(printf '%s\n%s' "$OLD_NAMED" "$NEW_NAMED")"
expect_status "varios con el mismo nombre" 0
expect_stdout_is "varios con el mismo nombre" "tok-newest"
expect_call_count "varios con el mismo nombre no crea" "create " 0

run_provision "expiración ausente" '{"id":6,"name":"aoc-advent-of-code-2026","token":"tok-no-expiry","createdAt":"2026-01-01T00:00:00Z"}'
expect_status "expiración ausente" 1
expect_stdout_is "expiración ausente" ""
expect_call_count "expiración ausente no revoca" "revoke " 0
expect_call_count "expiración ausente no crea" "create " 0
expect_stderr "expiración ausente" "refusing to revoke"

run_provision "token sin valor vigente" "{\"id\":7,\"name\":\"aoc-advent-of-code-2026\",\"expiresAt\":\"$LIVE_EXPIRY\",\"createdAt\":\"$OLD_CREATED\"}"
expect_status "token sin valor vigente" 1
expect_call_count "token sin valor vigente no revoca" "revoke " 0
expect_call_count "token sin valor vigente no crea" "create " 0
expect_stderr "token sin valor vigente" "refusing to revoke"

run_provision "expiración mal formada" '{"id":8,"name":"aoc-advent-of-code-2026","token":"tok-bad-expiry","expiresAt":"not-a-date"}'
expect_status "expiración mal formada" 1
expect_call_count "expiración mal formada no revoca" "revoke " 0
expect_call_count "expiración mal formada no crea" "create " 0
expect_stderr "expiración mal formada" "refusing to revoke"

: > "$CODACY_CALLS"
FAKE_LIST="" FAKE_CREATE_TOKEN=new-token \
  run_script "$TOKEN_SCRIPT" Flashky advent.of_code-2026
expect_status "nombre saneado" 0
expect_call "nombre saneado" "create Flashky advent.of_code-2026 aoc-advent-of-code-2026 "

: > "$CODACY_CALLS"
CODACY_SCRIPTS_DIR="$CODACY_TEST_DIR/nojq" FAKE_LIST="$LIVE" \
  run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026
expect_status "sin scripts auxiliares" 1
expect_stdout_is "sin scripts auxiliares" ""
expect_stderr "sin scripts auxiliares" "is required"

finish
