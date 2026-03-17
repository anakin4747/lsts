#!/usr/bin/env bats

source lsts

lsts_set_cmd "pyright-langserver --stdio"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/python"
lsts_set_langId "python"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'len' returns documentation" {
    lsts_hover "main.py" 1 8 "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.py" 1 8 > "hover.rpc.json"
}
