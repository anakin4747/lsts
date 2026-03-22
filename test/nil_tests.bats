#!/usr/bin/env bats

source lsts

lsts_set_cmd "nil"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/nix"
lsts_set_langId "nix"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'greeting' returns documentation" {
    lsts_hover "main.nix:3:6" "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.nix:3:6" > "hover.rpc.json"
}

@test "completion in let block returns items" {
    lsts_completion "main.nix:3:6" "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.nix:3:6" > "completion.rpc.json"
}

@test "document symbols lists top-level bindings" {
    lsts_document_symbols "main.nix" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.nix" > "document_symbols.rpc.json"
}

@test "references to 'greeting' returns all uses" {
    lsts_references "main.nix:3:6" "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.nix:3:6" "true" > "references.rpc.json"
}

@test "rename 'greeting' produces workspace edit" {
    lsts_rename "main.nix:3:6" "msg" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.nix:3:6" "msg" > "rename.rpc.json"
}
