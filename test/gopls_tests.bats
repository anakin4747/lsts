#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "gopls"
LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/go" && pwd)"

setup() {
    lsp_start
}

teardown() {
    lsp_stop
}

@test "gopls: initialize returns capabilities" {
    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "gopls: initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

@test "gopls: hover on 'fmt' package returns documentation" {
    local fixture="${LSTS_ROOT}/main.go"
    local uri="file://${fixture}"

    lsp_hover "$uri" "go" 2 8

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null
}
