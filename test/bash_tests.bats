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
    lsts_hover "main.sh:2:0" "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.sh:2:0" > "hover.rpc.json"
}

@test "completion inside function body returns items" {
    lsts_completion "main.sh:3:4" "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.sh:3:4" > "completion.rpc.json"
}

@test "definition of 'greet' jumps to declaration" {
    lsts_definition "main.sh:7:0" "definition.rpc.json"
}

@test "dummy definition to emit warning for snapshot mode" {
    lsts_definition "main.sh:7:0" > "definition.rpc.json"
}

@test "references to 'greet' returns all uses" {
    lsts_references "main.sh:2:0" "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.sh:2:0" "true" > "references.rpc.json"
}

@test "document symbols lists 'greet' function" {
    lsts_document_symbols "main.sh" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.sh" > "document_symbols.rpc.json"
}

@test "document highlight on 'greet' marks all occurrences" {
    lsts_document_highlight "main.sh:2:0" "document_highlight.rpc.json"
}

@test "dummy document_highlight to emit warning for snapshot mode" {
    lsts_document_highlight "main.sh:2:0" > "document_highlight.rpc.json"
}

@test "rename 'greet' produces workspace edit" {
    lsts_rename "main.sh:2:0" "hello" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.sh:2:0" "hello" > "rename.rpc.json"
}
