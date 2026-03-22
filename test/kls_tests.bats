#!/usr/bin/env bats

source lsts

lsts_set_cmd "kconfig-language-server"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/kconfig"
lsts_set_langId "kconfig"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'config' keyword returns documentation" {
    lsts_hover "test.Kconfig:1:1" "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "test.Kconfig:1:1" > "hover.rpc.json"
}


