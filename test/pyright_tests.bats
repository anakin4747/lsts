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
    lsts_hover "main.py:2:9" "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.py:2:9" > "hover.rpc.json"
}

@test "completion at start of line returns items" {
    lsts_completion "main.py:3:1" "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.py:3:1" > "completion.rpc.json"
}

@test "document symbols lists module-level names" {
    lsts_document_symbols "main.py" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.py" > "document_symbols.rpc.json"
}

@test "references to 'items' returns all uses" {
    lsts_references "main.py:1:1" "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.py:1:1" "true" > "references.rpc.json"
}

@test "signature help inside len() returns signatures" {
    lsts_signature_help "main.py:2:11" "signature_help.rpc.json"
}

@test "dummy signature_help to emit warning for snapshot mode" {
    lsts_signature_help "main.py:2:11" > "signature_help.rpc.json"
}

@test "document highlight on 'items' marks all occurrences" {
    lsts_document_highlight "main.py:1:1" "document_highlight.rpc.json"
}

@test "dummy document_highlight to emit warning for snapshot mode" {
    lsts_document_highlight "main.py:1:1" > "document_highlight.rpc.json"
}

@test "rename 'items' produces workspace edit" {
    lsts_rename "main.py:1:1" "elements" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.py:1:1" "elements" > "rename.rpc.json"
}
