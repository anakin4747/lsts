#!/usr/bin/env bats

source lsts

lsts_set_cmd "gopls"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/go"
lsts_set_langId "go"

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

@test "hover on 'fmt' package returns documentation" {
    lsts_hover "main.go" 2 8 "hover.rpc.json"
}

@test "dummy hover to emit warning for snapshot mode" {
    lsts_hover "main.go" 2 8 > "hover.rpc.json"
}

@test "completion after 'fmt.' returns members" {
    lsts_completion "main.go" 5 5 "completion.rpc.json"
}

@test "dummy completion to emit warning for snapshot mode" {
    lsts_completion "main.go" 5 5 > "completion.rpc.json"
}

@test "definition of 'fmt' jumps to package" {
    lsts_definition "main.go" 2 8 "definition.rpc.json"
}

@test "dummy definition to emit warning for snapshot mode" {
    lsts_definition "main.go" 2 8 > "definition.rpc.json"
}

@test "references to 'fmt' returns usage sites" {
    lsts_references "main.go" 2 8 "true" "references.rpc.json"
}

@test "dummy references to emit warning for snapshot mode" {
    lsts_references "main.go" 2 8 "true" > "references.rpc.json"
}

@test "document symbols lists 'main' function" {
    lsts_document_symbols "main.go" "document_symbols.rpc.json"
}

@test "dummy document_symbols to emit warning for snapshot mode" {
    lsts_document_symbols "main.go" > "document_symbols.rpc.json"
}

@test "signature help inside Println call returns signatures" {
    lsts_signature_help "main.go" 5 13 "signature_help.rpc.json"
}

@test "dummy signature_help to emit warning for snapshot mode" {
    lsts_signature_help "main.go" 5 13 > "signature_help.rpc.json"
}

@test "document highlight on 'fmt' marks all occurrences" {
    lsts_document_highlight "main.go" 2 8 "document_highlight.rpc.json"
}

@test "dummy document_highlight to emit warning for snapshot mode" {
    lsts_document_highlight "main.go" 2 8 > "document_highlight.rpc.json"
}

@test "formatting returns text edits for the file" {
    lsts_formatting "main.go" 4 true "formatting.rpc.json"
}

@test "dummy formatting to emit warning for snapshot mode" {
    lsts_formatting "main.go" 4 true > "formatting.rpc.json"
}

@test "rename 'main' function produces workspace edit" {
    lsts_rename "main.go" 4 5 "renamedMain" "rename.rpc.json"
}

@test "dummy rename to emit warning for snapshot mode" {
    lsts_rename "main.go" 4 5 "renamedMain" > "rename.rpc.json"
}

@test "code action on import line returns available actions" {
    lsts_code_action "main.go" 2 0 2 12 "code_action.rpc.json"
}

@test "dummy code_action to emit warning for snapshot mode" {
    lsts_code_action "main.go" 2 0 2 12 > "code_action.rpc.json"
}

@test "incoming calls on 'Println' returns callers" {
    lsts_goto_incoming_calls "main.go" 5 5 "incoming_calls.rpc.json"
}

@test "dummy incoming_calls to emit warning for snapshot mode" {
    lsts_goto_incoming_calls "main.go" 5 5 > "incoming_calls.rpc.json"
}

@test "outgoing calls on 'main' returns callees" {
    lsts_goto_outgoing_calls "main.go" 4 5 "outgoing_calls.rpc.json"
}

@test "dummy outgoing_calls to emit warning for snapshot mode" {
    lsts_goto_outgoing_calls "main.go" 4 5 > "outgoing_calls.rpc.json"
}

@test "prepare call hierarchy on 'main' returns item" {
    lsts_call_hierarchy_prepare "main.go" 4 5 "call_hierarchy_prepare.rpc.json"
}

@test "dummy call_hierarchy_prepare to emit warning for snapshot mode" {
    lsts_call_hierarchy_prepare "main.go" 4 5 > "call_hierarchy_prepare.rpc.json"
}
