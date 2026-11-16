#!/bin/bash
# =================================================================================
# Usage:       sourced by the *.test.sh scripts
# Description: Harness for the workflow script tests. It puts a stub `gh` first on
#              PATH, records every call and lets each test answer them with a
#              `gh_handler` function, so no request leaves the runner.
# =================================================================================

FAILURES=0

setup_stub() {
  TEST_WORK_DIR=$(mktemp -d)
  trap 'rm -rf "$TEST_WORK_DIR"' EXIT
  export GH_CALLS="$TEST_WORK_DIR/calls"
  : > "$GH_CALLS"

  mkdir -p "$TEST_WORK_DIR/bin"
  export GH_STDIN="$TEST_WORK_DIR/stdin"
  : > "$GH_STDIN"
  cat > "$TEST_WORK_DIR/bin/gh" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$GH_CALLS"
# `gh api --input -` reads the body from stdin; keep it so a test can assert what
# was sent, and consume it either way or the producer dies with SIGPIPE.
case " $* " in
  *" --input - "*) cat > "$GH_STDIN" ;;
esac
if declare -F gh_handler > /dev/null; then
  gh_handler "$@"
  exit $?
fi
exit "${GH_STATUS:-0}"
STUB
  chmod +x "$TEST_WORK_DIR/bin/gh"
  export PATH="$TEST_WORK_DIR/bin:$PATH"
}

# run_script <script> [arguments]...: leaves the status in RUN_STATUS and the
# combined output in RUN_OUTPUT.
run_script() {
  set +e
  RUN_OUTPUT=$(bash "$@" 2>&1)
  RUN_STATUS=$?
  set -e
}

pass() {
  echo "ok   $1"
}

fail() {
  echo "FAIL $1: $2"
  FAILURES=$((FAILURES + 1))
}

# expect_status <name> <expected-exit>
expect_status() {
  if [ "$RUN_STATUS" -eq "$2" ]; then
    pass "$1: exit"
  else
    fail "$1" "exit $RUN_STATUS (esperado $2) -> $RUN_OUTPUT"
  fi
}

# expect_output <name> <fragment>
expect_output() {
  if [[ "$RUN_OUTPUT" == *"$2"* ]]; then
    pass "$1: salida"
  else
    fail "$1" "la salida no contiene '$2' -> $RUN_OUTPUT"
  fi
}

# expect_no_output <name> <fragment>
expect_no_output() {
  if [[ "$RUN_OUTPUT" == *"$2"* ]]; then
    fail "$1" "la salida contiene '$2' -> $RUN_OUTPUT"
  else
    pass "$1: sin salida"
  fi
}

# expect_stdin <name> <jq expression that must hold>
expect_stdin() {
  if jq -e "$2" "$GH_STDIN" > /dev/null 2>&1; then
    pass "$1: cuerpo"
  else
    fail "$1" "el cuerpo enviado no cumple '$2' -> $(cat "$GH_STDIN" 2>/dev/null)"
  fi
}

# expect_call <name> <exact `gh` invocation>
expect_call() {
  if grep -Fxq -- "$2" "$GH_CALLS"; then
    pass "$1: llamada"
  else
    fail "$1" "no llamó a 'gh $2' -> $(tr '\n' '|' < "$GH_CALLS")"
  fi
}

# expect_no_call <name> <fragment>
expect_no_call() {
  if grep -Fq -- "$2" "$GH_CALLS"; then
    fail "$1" "llamó a 'gh $2' -> $(tr '\n' '|' < "$GH_CALLS")"
  else
    pass "$1: sin llamada"
  fi
}

finish() {
  if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "$FAILURES FALLOS"
    exit 1
  fi
  echo
  echo "TODO OK"
}
