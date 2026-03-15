#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "pyright-langserver --stdio"
LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/python" && pwd)"

setup() {
    lsp_start
}

teardown() {
    lsp_stop
}

@test "pyright: initialize returns capabilities" {
    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "pyright: initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

@test "pyright: hover on 'len' returns documentation" {
    local fixture="${LSTS_ROOT}/main.py"
    local uri="file://${fixture}"

    lsp_hover "$uri" "python" 1 8

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null
}
