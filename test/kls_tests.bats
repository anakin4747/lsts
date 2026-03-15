#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "kconfig-language-server"
lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/kconfig" && pwd)"
lsts_set_langId "kconfig"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "kconfig: initialize returns capabilities" {
    lsts_initialize

    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "kconfig: initialize handshake completes without error" {
    lsts_initialize

    local err
    err="$(echo "$LSTS_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]
}

@test "kconfig: hover on 'config' keyword returns documentation" {
    lsts_hover "test.Kconfig" 0 0 "hover.rpc.json"
}
