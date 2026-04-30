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

# Start fake-ls. Caller must have set FAKE_LS_RESPOND_* / FAKE_LS_NOTIFY_*
# env vars, or written a script with _write_script first.
_start_fake_ls() {
    export LSTS_ROOT
    lsts_set_cmd "$FAKE_LS"
    lsts_start
}

# Write a fake_ls_handle script from stdin; store path in $_script.
# Use when env vars are not expressive enough (e.g. server-to-client requests).
_write_script() {
    _script="$(mktemp /tmp/fake-ls-script.XXXXXX.sh)"
    cat > "$_script"
    export FAKE_LS_SCRIPT="$_script"
}

_script=""

setup() {
    _LSTS_FILTERS=()
    _script=""
    # Clear any env vars set by previous tests
    unset "${!FAKE_LS_RESPOND_@}" "${!FAKE_LS_NOTIFY_@}" FAKE_LS_SCRIPT 2>/dev/null || true
}

teardown() {
    lsts_stop 2>/dev/null || true
    if [[ -n "$_script" ]]; then rm -f "$_script"; fi
}

teardown_file() {
    lsts_check_no_snapshots
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
    export FAKE_LS_RESPOND_initialize='{"capabilities":{}}'
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
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
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
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
    export FAKE_LS_RESPOND_textDocument_hover='{"contents":{"kind":"plaintext","value":"hello"}}'
    _start_fake_ls
    lsts_hover "lsts_tests.bats:1:1" "$FIXTURES_DIR/hover_hello.rpc.json"
}

@test "lsts_hover fails when response does not match fixture" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
    export FAKE_LS_RESPOND_textDocument_hover='{"contents":{"kind":"plaintext","value":"wrong"}}'
    _start_fake_ls
    run lsts_hover "lsts_tests.bats:1:1" "$FIXTURES_DIR/hover_hello.rpc.json"
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# lsts_add_filter
# ---------------------------------------------------------------------------

@test "lsts_add_filter rewrites matching patterns before fixture comparison" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"definitionProvider":true}}'
    export FAKE_LS_RESPOND_textDocument_definition='[{"uri":"file:///nix/store/abc123-go-1.22/share/go/src/fmt/print.go"}]'
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
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":5}},\"severity\":1,\"message\":\"test error\"}]}}"
    _start_fake_ls
    lsts_diagnostics "lsts_tests.bats" "$FIXTURES_DIR/diag_error.rpc.json"
}

@test "lsts_diagnostics fails when server reports an empty diagnostics array" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[]}}"
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

# ---------------------------------------------------------------------------
# Snapshot detection
# ---------------------------------------------------------------------------

@test "lsts_check_no_snapshots passes when no snapshots were taken" {
    lsts_check_no_snapshots
}

@test "lsts_check_no_snapshots fails when a snapshot was taken" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
    export FAKE_LS_RESPOND_textDocument_hover='{"contents":{"kind":"plaintext","value":"hello"}}'
    _start_fake_ls
    # call lsts_hover with no fixture — snapshot mode
    lsts_hover "lsts_tests.bats:1:1"
    run lsts_check_no_snapshots
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# Fixture file validation
# ---------------------------------------------------------------------------

@test "lsts_hover fails with an error message when fixture file does not exist" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
    export FAKE_LS_RESPOND_textDocument_hover='{"contents":{"kind":"plaintext","value":"hello"}}'
    _start_fake_ls
    run lsts_hover "lsts_tests.bats:1:1" "/nonexistent/fixture.rpc.json"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"fixture file not found"* ]]
}

# ---------------------------------------------------------------------------
# lsts_initialize_capability
# ---------------------------------------------------------------------------

@test "lsts_initialize_capability passes when capability matches" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"hoverProvider":true}}'
    _start_fake_ls
    lsts_initialize_capability 'hoverProvider == true'
}

@test "lsts_initialize_capability fails when capability is absent" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{}}'
    _start_fake_ls
    run lsts_initialize_capability 'hoverProvider == true'
    [[ "$status" -ne 0 ]]
}

@test "lsts_initialize_capability passes for a non-boolean capability" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    _start_fake_ls
    lsts_initialize_capability 'textDocumentSync.change == 1'
}

# ---------------------------------------------------------------------------
# lsts_diagnostics_none
# ---------------------------------------------------------------------------

@test "lsts_diagnostics_none passes when server reports no diagnostics" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[]}}"
    _start_fake_ls
    lsts_diagnostics_none "lsts_tests.bats"
}

@test "lsts_diagnostics_none fails when server reports diagnostics" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[{\"severity\":1,\"message\":\"err\",\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":1}}}]}}"
    _start_fake_ls
    run lsts_diagnostics_none "lsts_tests.bats"
    [[ "$status" -ne 0 ]]
}

# ---------------------------------------------------------------------------
# lsts_change
# ---------------------------------------------------------------------------

@test "lsts_change sends didChange and receives updated publishDiagnostics" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[{\"severity\":1,\"message\":\"original\",\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":1}}}]}}"
    export FAKE_LS_NOTIFY_textDocument_didChange="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[{\"severity\":1,\"message\":\"updated\",\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":0,\"character\":1}}}]}}"
    _start_fake_ls
    lsts_initialize
    lsts_open "lsts_tests.bats"
    _lsts_recv_notification "textDocument/publishDiagnostics"
    lsts_change "lsts_tests.bats" 2 "lsts_tests.bats" \
        "$FIXTURES_DIR/diag_after_change.rpc.json"
}

@test "lsts_change does not trigger snapshot mode when called without a fixture" {
    export FAKE_LS_RESPOND_initialize='{"capabilities":{"textDocumentSync":{"openClose":true,"change":1}}}'
    export FAKE_LS_NOTIFY_textDocument_didOpen="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[]}}"
    export FAKE_LS_NOTIFY_textDocument_didChange="{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file://$LSTS_ROOT/lsts_tests.bats\",\"diagnostics\":[]}}"
    _start_fake_ls
    lsts_initialize
    lsts_open "lsts_tests.bats"
    _lsts_recv_notification "textDocument/publishDiagnostics"
    lsts_change "lsts_tests.bats" 2 "lsts_tests.bats"
}
