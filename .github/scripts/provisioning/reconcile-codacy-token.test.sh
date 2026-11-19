#!/bin/bash
# =================================================================================
# Usage:       ./reconcile-codacy-token.test.sh
# Description: Tests for reconcile-codacy-token.sh. The list/revoke scripts are
#              stubbed, so no request leaves the machine.
# Example:     ./reconcile-codacy-token.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/reconcile-codacy-token.sh"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/codacy-testlib.sh"

export CODACY_API_TOKEN=stub
export CODACY_SCRIPTS_DIR="$CODACY_TEST_DIR/stubs"

KEEP='{"id":1,"name":"aoc-advent-of-code-2026","token":"tok-keep","expiresAt":"2030-01-01T00:00:00Z","createdAt":"2026-01-01T00:00:00Z"}'
ORPHAN_1='{"id":2,"name":"pt-abc","token":"tok-orphan-1","expiresAt":"2030-01-01T00:00:00Z","createdAt":"2026-02-01T00:00:00Z"}'
ORPHAN_2='{"id":3,"name":"pt-def","token":"tok-orphan-2","expiresAt":"2027-01-01T00:00:00Z","createdAt":"2026-03-01T00:00:00Z"}'
ALL_TOKENS=$(printf '%s\n%s\n%s' "$KEEP" "$ORPHAN_1" "$ORPHAN_2")

: > "$CODACY_CALLS"
FAKE_LIST="$ALL_TOKENS" run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 tok-keep
expect_status "conserva uno y revoca el resto" 0
expect_stdout_is "conserva uno y revoca el resto" ""
expect_call_count "dos revocaciones" "revoke " 2
expect_call "revoca el primer huérfano" "revoke Flashky advent-of-code-2026 2"
expect_call "revoca el segundo huérfano" "revoke Flashky advent-of-code-2026 3"
expect_call_count "no crea tokens" "create " 0

: > "$CODACY_CALLS"
FAKE_LIST="$ALL_TOKENS" run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 tok-inexistente
expect_status "token a conservar ausente" 1
expect_stdout_is "token a conservar ausente" ""
expect_call_count "falla sin revocar nada" "revoke " 0
expect_stderr "token a conservar ausente" "nothing was revoked"

: > "$CODACY_CALLS"
FAKE_LIST="$ALL_TOKENS" run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 tok-keep --dry-run
expect_status "dry run" 0
expect_stdout_is "dry run" ""
expect_call_count "dry run no revoca" "revoke " 0
expect_stderr "dry run" "Would revoke pt-abc (id 2)"

: > "$CODACY_CALLS"
FAKE_LIST='' run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 tok-keep
expect_status "listado vacío" 1
expect_call_count "listado vacío no revoca" "revoke " 0

: > "$CODACY_CALLS"
FAKE_LIST="$ALL_TOKENS" FAKE_REVOKE_STATUS=1 \
  run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026 tok-keep
expect_status "fallo al revocar" 1

: > "$CODACY_CALLS"
run_script "$TOKEN_SCRIPT" Flashky advent-of-code-2026
expect_status "sin token a conservar" 1
expect_call_count "sin token a conservar no revoca" "revoke " 0

: > "$CODACY_CALLS"
run_script "$TOKEN_SCRIPT" "bad owner!" advent-of-code-2026 tok-keep
expect_status "owner inválido" 1
expect_call_count "owner inválido no revoca" "revoke " 0

finish
