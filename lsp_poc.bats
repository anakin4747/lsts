#!/usr/bin/env bats

# kconfig-language-server end-to-end tests using the lsts library.
# Demonstrates the intended usage pattern for library consumers.

load 'lsts'

LSP_CMD="kconfig-language-server"
LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/test/fixtures" && pwd)"
export LSP_CMD LSTS_ROOT

setup()    { lsp_start; }
teardown() { lsp_stop;  }

# ---------------------------------------------------------------------------
# initialize
# ---------------------------------------------------------------------------

@test "initialize returns capabilities" {
    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

# ---------------------------------------------------------------------------
# textDocument/hover
# ---------------------------------------------------------------------------

@test "hover on 'config' keyword returns markdown documentation" {
    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null

    local contents
    contents="$(echo "$LSP_RESPONSE" | jq -r '.result.contents.value')"
    [[ -n "$contents" ]]
}

@test "hover response id matches the request" {
    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    local got_id expected_id
    got_id="$(echo "$LSP_RESPONSE" | jq -r '.id')"
    expected_id=2
    [[ "$got_id" == "$expected_id" ]]
}
