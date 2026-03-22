#!/usr/bin/env bats

source lsts

lsts_set_cmd "bash-language-server start"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/bash"
lsts_set_langId "shellscript"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'greet' returns documentation" {
    lsts_hover "main.sh:3:1" "hover.rpc.json"
}

@test "completion inside function body returns items" {
    lsts_completion "main.sh:4:5" "completion.rpc.json"
}

@test "definition of 'greet' jumps to declaration" {
    lsts_definition "main.sh:8:1" "definition.rpc.json"
}

@test "references to 'greet' returns all uses" {
    lsts_references "main.sh:3:1" "true" "references.rpc.json"
}

@test "document symbols lists 'greet' function" {
    lsts_document_symbols "main.sh" "document_symbols.rpc.json"
}

@test "document highlight on 'greet' marks all occurrences" {
    lsts_document_highlight "main.sh:3:1" "document_highlight.rpc.json"
}

@test "rename 'greet' produces workspace edit" {
    lsts_rename "main.sh:3:1" "hello" "rename.rpc.json"
}
