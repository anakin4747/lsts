#!/usr/bin/env bats

source lsts

lsts_set_cmd "gopls"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/go"
lsts_set_langId "go"
lsts_add_filter \
    "file:///nix/store/[a-z0-9]*-go-[0-9.]*/share/go" \
    "file://\$GOROOT"

setup() {
    lsts_start
}

teardown() {
    lsts_stop
}

@test "initializes successfully" {
    lsts_initialize
}

@test "hover on 'fmt' package returns documentation" {
    lsts_hover "main.go:3:9" "hover.rpc.json"
}

@test "completion after 'fmt.' returns members" {
    lsts_completion "main.go:6:6" "completion.rpc.json"
}

@test "definition of 'fmt' jumps to package" {
    lsts_definition "main.go:3:9" "definition.rpc.json"
}

@test "references to 'fmt' returns usage sites" {
    lsts_references "main.go:3:9" "true" "references.rpc.json"
}

@test "document symbols lists 'main' function" {
    lsts_document_symbols "main.go" "document_symbols.rpc.json"
}

@test "signature help inside Println call returns signatures" {
    lsts_signature_help "main.go:6:14" "signature_help.rpc.json"
}

@test "document highlight on 'fmt' marks all occurrences" {
    lsts_document_highlight "main.go:3:9" "document_highlight.rpc.json"
}

@test "formatting returns text edits for the file" {
    lsts_formatting "main.go" 4 true "formatting.rpc.json"
}

@test "rename 'main' function produces workspace edit" {
    lsts_rename "main.go:5:6" "renamedMain" "rename.rpc.json"
}

@test "code action on import line returns available actions" {
    lsts_code_action "main.go:3:1:3:13" "code_action.rpc.json"
}

@test "incoming calls on 'Println' returns callers" {
    lsts_goto_incoming_calls "main.go:6:6" "incoming_calls.rpc.json"
}

@test "outgoing calls on 'main' returns callees" {
    lsts_goto_outgoing_calls "main.go:5:6" "outgoing_calls.rpc.json"
}

@test "prepare call hierarchy on 'main' returns item" {
    lsts_call_hierarchy_prepare "main.go:5:6" "call_hierarchy_prepare.rpc.json"
}
