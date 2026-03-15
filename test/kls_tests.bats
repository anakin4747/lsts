#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "kconfig-language-server"
lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/kconfig" && pwd)"
lsts_set_langId "kconfig"

setup() {
    lsp_start
}

teardown() {
    lsp_stop
}

@test "kconfig: initialize returns capabilities" {
    lsp_initialize

    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "kconfig: initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSTS_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]
}

@test "kconfig: hover on 'config' keyword returns documentation" {
    lsp_hover "test.Kconfig" 0 0 "hover.rpc.json"
}
