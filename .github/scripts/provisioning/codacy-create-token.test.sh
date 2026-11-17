#!/bin/bash
# =================================================================================
# Usage:       ./codacy-create-token.test.sh
# Description: Regression tests for codacy-create-token.sh. Replaces curl with a
#              stub that returns a canned response, so nothing leaves the machine.
# Example:     ./codacy-create-token.test.sh
# =================================================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_SCRIPT="$SCRIPT_DIR/codacy-create-token.sh"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

FAILURES=0

mkdir -p "$WORK_DIR/bin"
cat > "$WORK_DIR/bin/curl" <<'STUB'
#!/bin/bash
# Stand-in for curl: honour -o <file>, ignore everything else, then print the
# canned body and the canned HTTP status.
out=""
while (($#)); do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s' "${FAKE_CURL_BODY:-}" > "$out"
printf '%s' "${FAKE_CURL_STATUS:-200}"
STUB
chmod +x "$WORK_DIR/bin/curl"

# run_case <name> <status> <body> <expected-exit> <expected> [exact] [forbidden]
#   exact:     the whole output must be <expected>, so echoing the response back
#              instead of extracting the token does not pass.
#   forbidden: no line of the output may start with this prefix, which is how a
#              workflow command smuggled in the response would surface.
run_case() {
  local name="$1" status="$2" body="$3" expected_exit="$4" expected="$5"
  local mode="${6:-substring}" forbidden="${7:-}"
  local output rc
  local stdout_file="$WORK_DIR/stdout" stderr_file="$WORK_DIR/stderr"
  set +e
  PATH="$WORK_DIR/bin:$PATH" \
    CODACY_API_TOKEN=stub \
    FAKE_CURL_STATUS="$status" \
    FAKE_CURL_BODY="$body" \
    bash "$TOKEN_SCRIPT" Flashky advent-of-code-2026 > "$stdout_file" 2> "$stderr_file"
  rc=$?
  set -e
  # The callers capture stdout in a variable: a diagnostic there is lost as soon
  # as `set -e` ends the step, which is exactly what hid the Codacy error.
  output=$(cat "$stdout_file" "$stderr_file")

  if [ "$rc" -ne "$expected_exit" ]; then
    echo "FAIL $name: exit $rc (esperado $expected_exit) -> $output"
    FAILURES=$((FAILURES + 1))
  elif [ "$expected_exit" -ne 0 ] && [ -s "$stdout_file" ]; then
    echo "FAIL $name: el error fue a stdout, donde el caller lo captura y pierde -> $(cat "$stdout_file")"
    FAILURES=$((FAILURES + 1))
  elif [ "$expected_exit" -eq 0 ] && [ -s "$stderr_file" ]; then
    echo "FAIL $name: el éxito escribió en stderr -> $(cat "$stderr_file")"
    FAILURES=$((FAILURES + 1))
  elif [ "$mode" = "exact" ] && [ "$output" != "$expected" ]; then
    echo "FAIL $name: salida '$output' (esperado exactamente '$expected')"
    FAILURES=$((FAILURES + 1))
  elif [ "$mode" != "exact" ] && [[ "$output" != *"$expected"* ]]; then
    echo "FAIL $name: no contiene '$expected' -> $output"
    FAILURES=$((FAILURES + 1))
  elif [ -n "$forbidden" ] && grep -q "^${forbidden}" <<< "$output"; then
    echo "FAIL $name: una línea empieza por '$forbidden' -> $output"
    FAILURES=$((FAILURES + 1))
  else
    echo "ok   $name"
  fi
}

run_case "token válido" 200 '{"token":"abc123"}' 0 "abc123" exact
run_case "token tras otras claves" 200 '{"expiresAt":"2027-01-01","token":"xyz789"}' 0 "xyz789" exact
run_case "token ausente" 200 '{"message":"ok"}' 1 "without a usable token"
run_case "token nulo" 200 '{"token":null}' 1 "without a usable token"
run_case "JSON malformado" 200 '{"token":"abc123"' 1 "without a usable token"
run_case "dos documentos JSON" 200 '{"token":"a"} {"token":"b"}' 1 "without a usable token"
run_case "token con salto de línea" 200 '{"token":"abc\nname=injected"}' 1 "without a usable token" substring "name=injected"
run_case "token con tabulador" 200 '{"token":"abc\tdef"}' 1 "without a usable token"
run_case "error de la API" 404 '{"error":"Not Found","message":"repository not found"}' 1 "404 Not Found: repository not found"
run_case "error con comando de workflow" 404 '{"error":"Not Found","message":"a\n::warning::b"}' 1 "404 Not Found: a ::warning::b" substring "::warning::"
run_case "error con objeto en error" 500 '{"error":{"code":1}}' 1 "500 Error:"
run_case "respuesta vacía" 500 '' 1 "Empty response from server."

if [ "$FAILURES" -ne 0 ]; then
  echo
  echo "$FAILURES FALLOS"
  exit 1
fi

echo
echo "TODO OK"
