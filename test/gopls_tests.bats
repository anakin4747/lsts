#!/usr/bin/env bats

source lsts

lsts_set_cmd "gopls"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/go"
lsts_set_langId "go"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'fmt' package returns documentation" {
    lsts_hover "main.go" 2 8 "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.go" 2 8 > "hover.rpc.json"
}
