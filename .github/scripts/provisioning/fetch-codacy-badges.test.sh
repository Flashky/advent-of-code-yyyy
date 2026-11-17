#!/bin/bash
# =================================================================================
# Usage:       ./fetch-codacy-badges.test.sh
# Description: The badge URLs come back as output lines, and a project without
#              badges reports the skip without failing. `curl` is stubbed with a
#              canned response and records its arguments, so nothing leaves the
#              runner and the token can be asserted to travel in a header.
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../testlib.sh"

setup_stub
CODACY_PROJECT_TOKEN=stub
CURL_RESPONSE="$TEST_WORK_DIR/response.json"
CURL_CALLS="$TEST_WORK_DIR/curl-calls"
export CODACY_PROJECT_TOKEN CURL_RESPONSE CURL_CALLS
: > "$CURL_CALLS"

cat > "$TEST_WORK_DIR/bin/curl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$CURL_CALLS"
cat "$CURL_RESPONSE"
STUB
chmod +x "$TEST_WORK_DIR/bin/curl"

expect_curl() {
  if grep -Fq -- "$2" "$CURL_CALLS"; then
    pass "$1: curl"
  else
    fail "$1" "curl no recibió '$2' -> $(tr '\n' '|' < "$CURL_CALLS")"
  fi
}

printf '%s' '{"data":{"badges":{"grade":"https://grade","coverage":"https://coverage"}}}' > "$CURL_RESPONSE"
run_script "$SCRIPT_DIR/fetch-codacy-badges.sh" Flashky repo
expect_status "badges presentes: exit" 0
expect_stdout_is "badges presentes: stdout exacto" "skip_badges=false
grade_url=https://grade
coverage_url=https://coverage"
expect_no_stderr "badges presentes: no avisa"
expect_curl "badges presentes: endpoint" "api/v3/organizations/gh/Flashky/repositories/repo"
expect_curl "badges presentes: token en cabecera" "project-token: stub"
if grep -Fq -- "?project-token" "$CURL_CALLS"; then
  fail "badges presentes" "el token viajó en la URL"
else
  pass "badges presentes: token fuera de la URL"
fi

printf '%s' '{"data":{"badges":{"grade":null,"coverage":null}}}' > "$CURL_RESPONSE"
run_script "$SCRIPT_DIR/fetch-codacy-badges.sh" Flashky repo
expect_status "sin badges: exit" 0
expect_stdout_is "sin badges: stdout exacto" "skip_badges=true"
expect_stderr "sin badges: avisa" "::warning title=Codacy Badges Missing::"

printf '%s' '' > "$CURL_RESPONSE"
run_script "$SCRIPT_DIR/fetch-codacy-badges.sh" Flashky repo
expect_status "respuesta vacía: exit" 0
expect_stdout_is "respuesta vacía: stdout exacto" "skip_badges=true"

unset CODACY_PROJECT_TOKEN
run_script "$SCRIPT_DIR/fetch-codacy-badges.sh" Flashky repo
expect_status "sin token: exit" 1
expect_stdout_is "sin token: stdout vacío" ""
expect_stderr "sin token: lo dice" "CODACY_PROJECT_TOKEN is not set"

finish
