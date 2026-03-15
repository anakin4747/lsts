#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "pyright-langserver --stdio"
lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/python" && pwd)"
lsts_set_langId "python"

setup() {
    lsp_start
}

teardown() {
    lsp_stop
}

@test "pyright: initialize returns capabilities" {
    lsp_initialize

    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "pyright: initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSTS_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSTS_PID}"
}

@test "pyright: hover on 'len' returns documentation" {
    lsp_hover "main.py" 1 8 "hover.rpc.json"
}
