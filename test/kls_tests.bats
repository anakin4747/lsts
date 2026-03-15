#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "kconfig-language-server"
lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures" && pwd)"
lsts_set_langId "kconfig"

setup() {
    lsp_start
}

teardown() {
    lsp_stop
}

@test "kconfig: initialize returns capabilities" {
    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "kconfig: initialize handshake completes without error" {
    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]
}

@test "kconfig: hover on 'config' keyword returns markdown documentation" {
    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null

    local contents
    contents="$(echo "$LSP_RESPONSE" | jq -r '.result.contents.value')"
    [[ -n "$contents" ]]
}

@test "kconfig: hover response id matches the request" {
    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    local got_id expected_id
    got_id="$(echo "$LSP_RESPONSE" | jq -r '.id')"
    expected_id=2
    [[ "$got_id" == "$expected_id" ]]
}
