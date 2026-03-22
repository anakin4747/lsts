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
    lsts_hover "main.nix:4:7" "hover.rpc.json"
}

@test "completion in let block returns items" {
    lsts_completion "main.nix:4:7" "completion.rpc.json"
}

@test "document symbols lists top-level bindings" {
    lsts_document_symbols "main.nix" "document_symbols.rpc.json"
}

@test "references to 'greeting' returns all uses" {
    lsts_references "main.nix:4:7" "true" "references.rpc.json"
}

@test "rename 'greeting' produces workspace edit" {
    lsts_rename "main.nix:4:7" "msg" "rename.rpc.json"
}
