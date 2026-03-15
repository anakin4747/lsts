#!/usr/bin/env bats

load '../lsts'

lsts_set_cmd "gopls"
lsts_set_root "$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/go" && pwd)"
lsts_set_langId "go"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "gopls: initialize returns capabilities" {
    lsts_initialize

    echo "$LSTS_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "gopls: initialize handshake completes without error" {
    lsts_initialize

    local err
    err="$(echo "$LSTS_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]
}

@test "gopls: hover on 'fmt' package returns documentation" {
    lsts_hover "main.go" 2 8 "hover.rpc.json"
}
