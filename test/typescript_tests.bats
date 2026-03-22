#!/usr/bin/env bats

source lsts

lsts_set_cmd "typescript-language-server --stdio"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/typescript"
lsts_set_langId "typescript"

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
    lsts_hover "main.ts:1:10" "hover.rpc.json"
}

@test "completion after 'greet' returns items" {
    lsts_completion "main.ts:5:7" "completion.rpc.json"
}

@test "definition of 'greet' jumps to declaration" {
    lsts_definition "main.ts:5:7" "definition.rpc.json"
}

@test "references to 'greet' returns all uses" {
    lsts_references "main.ts:1:10" "true" "references.rpc.json"
}

@test "document symbols lists 'greet' function and 'message'" {
    lsts_document_symbols "main.ts" "document_symbols.rpc.json"
}

@test "signature help inside greet call returns signatures" {
    lsts_signature_help "main.ts:5:14" "signature_help.rpc.json"
}

@test "document highlight on 'greet' marks all occurrences" {
    lsts_document_highlight "main.ts:1:10" "document_highlight.rpc.json"
}

@test "rename 'greet' produces workspace edit" {
    lsts_rename "main.ts:1:10" "sayHello" "rename.rpc.json"
}
