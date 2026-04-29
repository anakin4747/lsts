#!/usr/bin/env bats
# lsts_tests.bats — unit tests for the lsts library.
#
# Uses fake-ls, a scriptable fake LSP server, so no real language server is
# required. Each test exercises lsts behaviour directly and in isolation.

LSTS_LIB="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/lsts"
FAKE_LS="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fake-ls"
FIXTURES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fake-ls-fixtures"

source "$LSTS_LIB"

lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
lsts_set_langId "plaintext"

# Write a fake-ls script from stdin and store the path in $_script.
_write_script() {
    _script="$(mktemp /tmp/fake-ls-script.XXXXXX.sh)"
    cat > "$_script"
}

# Start fake-ls using the script written by _write_script.
_start_fake_ls() {
    export FAKE_LS_SCRIPT="$_script"
    export LSTS_ROOT
    lsts_set_cmd "$FAKE_LS"
    lsts_start
}

_script=""

setup() {
    _LSTS_FILTERS=()
    _script=""
}

teardown() {
    lsts_stop 2>/dev/null || true
    if [[ -n "$_script" ]]; then rm -f "$_script"; fi
}

# ---------------------------------------------------------------------------
# lsts_recv: framing
# ---------------------------------------------------------------------------

@test "lsts_recv returns non-zero when server closes without sending anything" {
    lsts_set_cmd "true"
    lsts_start
    run lsts_recv
    [[ "$status" -ne 0 ]]
}

@test "lsts_recv reads a correctly framed message" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && fake_ls_respond '{"capabilities":{}}'
    [[ "$1" == "initialized" ]] && return 0
}
EOF
    _start_fake_ls
    lsts_request "initialize" \
        '{"processId":null,"rootUri":"file:///tmp","rootPath":"/tmp","capabilities":{}}'
    lsts_recv_response
    printf '%s' "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' > /dev/null
}

# ---------------------------------------------------------------------------
# lsts_initialize
# ---------------------------------------------------------------------------

@test "lsts_initialize succeeds when server returns capabilities" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && fake_ls_respond '{"capabilities":{"hoverProvider":true}}'
    [[ "$1" == "initialized" ]] && return 0
}
EOF
    _start_fake_ls
    lsts_initialize
    printf '%s' "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' > /dev/null
}

@test "lsts_initialize fails when server returns a JSON-RPC error" {
    _write_script << 'EOF'
fake_ls_handle() {
    if [[ "$1" == "initialize" ]]; then
        local body='{"jsonrpc":"2.0","id":1,"error":{"code":-32002,"message":"not ready"}}'
        printf 'Content-Length: %d\r\n\r\n%s' "${#body}" "$body"
    fi
}
EOF
    _start_fake_ls
    run lsts_initialize
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# lsts_hover / fixture comparison
# ---------------------------------------------------------------------------

@test "lsts_hover passes when response matches fixture" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && fake_ls_respond '{"capabilities":{"hoverProvider":true}}'
    [[ "$1" == "initialized" ]] && return 0
    [[ "$1" == "textDocument/didOpen" ]] && return 0
    [[ "$1" == "textDocument/hover" ]] && \
        fake_ls_respond '{"contents":{"kind":"plaintext","value":"hello"}}'
}
EOF
    _start_fake_ls
    lsts_hover "lsts_tests.bats:1:1" "$FIXTURES_DIR/hover_hello.rpc.json"
}

@test "lsts_hover fails when response does not match fixture" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && fake_ls_respond '{"capabilities":{"hoverProvider":true}}'
    [[ "$1" == "initialized" ]] && return 0
    [[ "$1" == "textDocument/didOpen" ]] && return 0
    [[ "$1" == "textDocument/hover" ]] && \
        fake_ls_respond '{"contents":{"kind":"plaintext","value":"wrong"}}'
}
EOF
    _start_fake_ls
    run lsts_hover "lsts_tests.bats:1:1" "$FIXTURES_DIR/hover_hello.rpc.json"
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# lsts_add_filter
# ---------------------------------------------------------------------------

@test "lsts_add_filter rewrites matching patterns before fixture comparison" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && fake_ls_respond '{"capabilities":{"definitionProvider":true}}'
    [[ "$1" == "initialized" ]] && return 0
    [[ "$1" == "textDocument/didOpen" ]] && return 0
    [[ "$1" == "textDocument/definition" ]] && \
        fake_ls_respond '[{"uri":"file:///nix/store/abc123-go-1.22/share/go/src/fmt/print.go"}]'
}
EOF
    _start_fake_ls
    lsts_add_filter \
        "file:///nix/store/[a-z0-9]*-go-[0-9.]*/share/go" \
        'file://$GOROOT'
    lsts_definition "lsts_tests.bats:1:1" "$FIXTURES_DIR/definition_filtered.rpc.json"
}

# ---------------------------------------------------------------------------
# _lsts_reply_to_request: server-to-client requests
# ---------------------------------------------------------------------------

@test "lsts_recv_response auto-replies to server-initiated requests" {
    _write_script << 'EOF'
fake_ls_handle() {
    if [[ "$1" == "initialize" ]]; then
        fake_ls_request "window/workDoneProgress/create" '{"token":"tok1"}'
        fake_ls_respond '{"capabilities":{}}'
    fi
    [[ "$1" == "initialized" ]] && return 0
}
EOF
    _start_fake_ls
    lsts_initialize
    printf '%s' "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' > /dev/null
}

# ---------------------------------------------------------------------------
# lsts_diagnostics
# ---------------------------------------------------------------------------

@test "lsts_diagnostics passes when server reports diagnostics matching fixture" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && \
        fake_ls_respond '{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    [[ "$1" == "initialized" ]] && return 0
    if [[ "$1" == "textDocument/didOpen" ]]; then
        fake_ls_notify "textDocument/publishDiagnostics" \
            "{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":5}},\"severity\":1,\"message\":\"test error\"}]}"
    fi
}
EOF
    _start_fake_ls
    lsts_diagnostics "lsts_tests.bats" "$FIXTURES_DIR/diag_error.rpc.json"
}

@test "lsts_diagnostics fails when server reports an empty diagnostics array" {
    _write_script << 'EOF'
fake_ls_handle() {
    [[ "$1" == "initialize" ]] && \
        fake_ls_respond '{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    [[ "$1" == "initialized" ]] && return 0
    if [[ "$1" == "textDocument/didOpen" ]]; then
        fake_ls_notify "textDocument/publishDiagnostics" \
            "{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[]}"
    fi
}
EOF
    _start_fake_ls
    run lsts_diagnostics "lsts_tests.bats"
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# lsts_set_cmd validation
# ---------------------------------------------------------------------------

@test "lsts_set_cmd fails when the command is not found" {
    run lsts_set_cmd "this-command-does-not-exist-lsts-test"
    [[ "$status" -ne 0 ]]
}

@test "lsts_set_cmd succeeds when the command exists" {
    lsts_set_cmd "true"
}

# ---------------------------------------------------------------------------
# lsts_start precondition validation
# ---------------------------------------------------------------------------

@test "lsts_start fails when lsts_set_cmd has not been called" {
    LSTS_CMD="" run lsts_start
    [[ "$status" -ne 0 ]]
}

@test "lsts_start fails when lsts_set_root has not been called" {
    lsts_set_cmd "true"
    LSTS_ROOT="" run lsts_start
    [[ "$status" -ne 0 ]]
}

@test "lsts_start fails when lsts_set_langId has not been called" {
    lsts_set_cmd "true"
    lsts_set_root "/tmp"
    LSTS_LANG_ID="" run lsts_start
    [[ "$status" -ne 0 ]]
}
