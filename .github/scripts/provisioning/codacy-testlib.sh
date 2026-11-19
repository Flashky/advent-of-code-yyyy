#!/bin/bash
# =================================================================================
# Usage:       sourced by the Codacy *.test.sh scripts
# Description: Stubs for the Codacy provisioning tests. `curl` and the three
#              single-endpoint scripts are replaced by local executables that
#              record every call, so no request leaves the machine.
# =================================================================================

CODACY_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$CODACY_TEST_DIR"' EXIT
mkdir -p "$CODACY_TEST_DIR/bin" "$CODACY_TEST_DIR/stubs" "$CODACY_TEST_DIR/nojq"

export CODACY_TEST_DIR
export CODACY_CALLS="$CODACY_TEST_DIR/calls"
export CODACY_BODIES="$CODACY_TEST_DIR/bodies"
: > "$CODACY_CALLS"
: > "$CODACY_BODIES"

cat > "$CODACY_TEST_DIR/bin/curl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$CODACY_CALLS"
out=""
while (($#)); do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    -X|--request) printf 'METHOD=%s\n' "$2" >> "$CODACY_CALLS"; shift 2 ;;
    --url) printf 'URL=%s\n' "$2" >> "$CODACY_CALLS"; shift 2 ;;
    --data|-d) printf '%s\n' "$2" >> "$CODACY_BODIES"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s' "${FAKE_CURL_BODY:-}" > "$out"
printf '%s' "${FAKE_CURL_STATUS:-200}"
STUB

cat > "$CODACY_TEST_DIR/stubs/codacy-list-tokens.sh" <<'STUB'
#!/bin/bash
printf 'list %s\n' "$*" >> "$CODACY_CALLS"
# Trailing newline matters: `while read` skips a final line without one.
printf '%s\n' "${FAKE_LIST:-}"
STUB

cat > "$CODACY_TEST_DIR/stubs/codacy-create-token.sh" <<'STUB'
#!/bin/bash
printf 'create %s\n' "$*" >> "$CODACY_CALLS"
if [[ -n "${CODACY_TOKEN_STATE_FILE:-}" && -n "${FAKE_CREATE_ID:-}" ]]; then
  printf 'id=%s\n' "$FAKE_CREATE_ID" >> "$CODACY_TOKEN_STATE_FILE"
fi
printf '%s' "${FAKE_CREATE_TOKEN:-new-token}"
STUB

cat > "$CODACY_TEST_DIR/stubs/codacy-revoke-token.sh" <<'STUB'
#!/bin/bash
printf 'revoke %s\n' "$*" >> "$CODACY_CALLS"
exit "${FAKE_REVOKE_STATUS:-0}"
STUB

chmod +x "$CODACY_TEST_DIR/bin/curl" \
  "$CODACY_TEST_DIR/stubs/codacy-list-tokens.sh" \
  "$CODACY_TEST_DIR/stubs/codacy-create-token.sh" \
  "$CODACY_TEST_DIR/stubs/codacy-revoke-token.sh"

# expect_call <name> <fragment>: at least one recorded call contains the text.
expect_call() {
  if grep -Fq -- "$2" "$CODACY_CALLS"; then
    pass "$1: llamada"
  else
    fail "$1" "ninguna llamada contiene '$2' -> $(tr '\n' '|' < "$CODACY_CALLS")"
  fi
}

# expect_call_count <name> <fragment> <expected-number>
expect_call_count() {
  local actual
  actual=$(grep -Fc -- "$2" "$CODACY_CALLS" || true)
  if [[ "$actual" -eq "$3" ]]; then
    pass "$1: $3 llamada(s)"
  else
    fail "$1" "$actual llamadas a '$2' (esperadas $3) -> $(tr '\n' '|' < "$CODACY_CALLS")"
  fi
}

# expect_order <name> <first-fragment> <second-fragment>
expect_order() {
  local first second
  first=$(grep -Fn -- "$2" "$CODACY_CALLS" | head -1 | cut -d: -f1)
  second=$(grep -Fn -- "$3" "$CODACY_CALLS" | head -1 | cut -d: -f1)
  if [[ -n "$first" && -n "$second" && "$first" -lt "$second" ]]; then
    pass "$1: orden"
  else
    fail "$1" "'$2' no precede a '$3' -> $(tr '\n' '|' < "$CODACY_CALLS")"
  fi
}

# expect_json_field <name> <field> <expected>: the last request body must have
# exactly that value, not merely contain it as a substring of another value.
expect_json_field() {
  local actual
  actual=$(tail -1 "$CODACY_BODIES" | jq -r --arg field "$2" '.[$field] // empty' 2>/dev/null || true)
  if [[ "$actual" == "$3" ]]; then
    pass "$1: $2=$3"
  else
    fail "$1" "$2='$actual' (esperado '$3') -> $(tail -1 "$CODACY_BODIES")"
  fi
}
