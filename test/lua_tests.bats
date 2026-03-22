#!/usr/bin/env bats

source lsts

lsts_set_cmd "lua-language-server"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/lua"
lsts_set_langId "lua"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'print' returns documentation" {
    lsts_hover "main.lua:3:1" "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.lua:3:1" > "hover.rpc.json"
}

@test "completion after 'print' returns members" {
    lsts_completion "main.lua:3:6" "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.lua:3:6" > "completion.rpc.json"
}

@test "document symbols lists top-level names" {
    lsts_document_symbols "main.lua" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.lua" > "document_symbols.rpc.json"
}

@test "references to 'items' returns all uses" {
    lsts_references "main.lua:1:7" "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.lua:1:7" "true" > "references.rpc.json"
}

@test "document highlight on 'count' marks all occurrences" {
    lsts_document_highlight "main.lua:2:7" "document_highlight.rpc.json"
}

@test "dummy document_highlight to emit warning for snapshot mode" {
    lsts_document_highlight "main.lua:2:7" > "document_highlight.rpc.json"
}

@test "rename 'count' produces workspace edit" {
    lsts_rename "main.lua:2:7" "n" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.lua:2:7" "n" > "rename.rpc.json"
}
