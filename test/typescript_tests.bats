#!/usr/bin/env bats

source lsts

lsts_set_cmd "typescript-language-server --stdio"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/typescript"
lsts_set_langId "typescript"

setup() {
    lsts_print_test_location
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'greet' returns documentation" {
    lsts_hover "main.ts" 0 9 "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.ts" 0 9 > "hover.rpc.json"
}

@test "completion after 'greet' returns items" {
    lsts_completion "main.ts" 4 6 "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.ts" 4 6 > "completion.rpc.json"
}

@test "definition of 'greet' jumps to declaration" {
    lsts_definition "main.ts" 4 6 "definition.rpc.json"
}

@test "dummy definition to emit warning for snapshot mode" {
    lsts_definition "main.ts" 4 6 > "definition.rpc.json"
}

@test "references to 'greet' returns all uses" {
    lsts_references "main.ts" 0 9 "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.ts" 0 9 "true" > "references.rpc.json"
}

@test "document symbols lists 'greet' function and 'message'" {
    lsts_document_symbols "main.ts" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.ts" > "document_symbols.rpc.json"
}

@test "signature help inside greet call returns signatures" {
    lsts_signature_help "main.ts" 4 13 "signature_help.rpc.json"
}

@test "dummy signature_help to emit warning for snapshot mode" {
    lsts_signature_help "main.ts" 4 13 > "signature_help.rpc.json"
}

@test "document highlight on 'greet' marks all occurrences" {
    lsts_document_highlight "main.ts" 0 9 "document_highlight.rpc.json"
}

@test "dummy document_highlight to emit warning for snapshot mode" {
    lsts_document_highlight "main.ts" 0 9 > "document_highlight.rpc.json"
}

@test "rename 'greet' produces workspace edit" {
    lsts_rename "main.ts" 0 9 "sayHello" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.ts" 0 9 "sayHello" > "rename.rpc.json"
}
