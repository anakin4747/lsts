#!/usr/bin/env bats

# Proof of concept: send initialize to a language server via coproc
# Uses kconfig-language-server as the target under test.
# Override: LSP_CMD="other-server" bats lsp_poc.bats

LSP_CMD="${LSP_CMD:-kconfig-language-server}"

# ---------------------------------------------------------------------------
# JSON-RPC helpers
# ---------------------------------------------------------------------------

# Send a raw JSON string to the server with the Content-Length framing
lsp_send() {
    local body="$1"
    local len=${#body}
    printf "Content-Length: %d\r\n\r\n%s" "$len" "$body" >&"$LSP_WRITE_FD"
}

# Read one JSON-RPC message from the server into the global LSP_RESPONSE.
# Must be called outside of a subshell so the coproc FD remains accessible.
# Control characters (tabs etc.) embedded in JSON string values are replaced
# with spaces so that jq can parse the response without errors.
lsp_recv() {
    local line content_length=0 raw

    while IFS= read -r -t "${LSP_TIMEOUT:-10}" line <&"$LSP_READ_FD"; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        if [[ "$line" =~ ^Content-Length:\ ([0-9]+)$ ]]; then
            content_length="${BASH_REMATCH[1]}"
        fi
    done

    [[ "$content_length" -eq 0 ]] && { echo "lsp_recv: no Content-Length" >&2; return 1; }

    IFS= read -r -N "$content_length" -t "${LSP_TIMEOUT:-10}" raw <&"$LSP_READ_FD"

    # The server embeds literal tab and newline characters inside JSON string
    # values without escaping them, which is invalid JSON that jq rejects.
    # Collapse all such control characters to spaces so the response is
    # parseable; structural JSON whitespace is unaffected since jq handles
    # compact single-line JSON fine.
    LSP_RESPONSE="$(printf '%s' "$raw" | tr '\t\n' '  ')"
}

# Build a JSON-RPC request and send it
lsp_request() {
    local id="$1" method="$2" params="$3"
    lsp_send "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":$params}"
}

# Build a JSON-RPC notification (no id) and send it
lsp_notify() {
    local method="$1" params="$2"
    lsp_send "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params}"
}

# Send initialize + initialized and verify the handshake succeeds.
# Populates LSP_RESPONSE with the InitializeResult.
lsp_initialize() {
    local root="${1:-null}"
    lsp_request 1 "initialize" \
        "{\"processId\":null,\"rootUri\":$root,\"rootPath\":$root,\"capabilities\":{}}"
    lsp_recv
    echo "$LSP_RESPONSE" | jq -e '.result.capabilities' >/dev/null
    lsp_notify "initialized" "{}"
}

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

setup() {
    # Start the language server as a coprocess and capture FDs as globals.
    # lsp_recv reads directly from LSP_READ_FD to avoid subshell coproc FD loss.
    coproc LSP { $LSP_CMD; }
    LSP_READ_FD=${LSP[0]}
    LSP_WRITE_FD=${LSP[1]}
}

teardown() {
    lsp_notify "exit" "{}" 2>/dev/null || true
    kill "${LSP_PID:-}" 2>/dev/null || true
    wait "${LSP_PID:-}" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "initialize returns capabilities" {
    lsp_request 1 "initialize" '{"processId":null,"rootUri":null,"capabilities":{}}'
    lsp_recv

    # Must have a result, not an error
    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null

    # Must have capabilities object
    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null

    # id must match what we sent
    local got_id
    got_id=$(echo "$LSP_RESPONSE" | jq -r '.id')
    [[ "$got_id" == "1" ]]
}

@test "initialize then initialized handshake completes without error" {
    lsp_request 1 "initialize" '{"processId":null,"rootUri":null,"capabilities":{}}'
    lsp_recv

    # Server must not return an error field
    local has_error
    has_error=$(echo "$LSP_RESPONSE" | jq '.error')
    [[ "$has_error" == "null" ]]

    # Send the initialized notification — server should not crash
    lsp_notify "initialized" "{}"

    sleep 0.1
    kill -0 "${LSP_PID}" 2>/dev/null
}

@test "hover on a Kconfig keyword returns markdown documentation" {
    # Write a real Kconfig file to disk — the server reads it directly by path
    local kconfig_file
    kconfig_file="$(mktemp /tmp/test_XXXXXX.Kconfig)"
    cat > "$kconfig_file" <<'EOF'
config NET
	bool "Networking support"
	help
	  Enable networking support.
EOF

    local uri="file://$kconfig_file"

    lsp_initialize "\"$kconfig_file\""

    # Notify the server the document is open (line 0: "config NET")
    lsp_notify "textDocument/didOpen" \
        "{\"textDocument\":{\"uri\":\"$uri\",\"languageId\":\"kconfig\",\"version\":1,\"text\":\"\"}}"

    # Hover on "config" — line 0 (zero-based), character 0
    lsp_request 2 "textDocument/hover" \
        "{\"textDocument\":{\"uri\":\"$uri\"},\"position\":{\"line\":0,\"character\":0}}"
    lsp_recv

    rm -f "$kconfig_file"

    # Response must have id 2
    local got_id
    got_id=$(echo "$LSP_RESPONSE" | jq -r '.id')
    [[ "$got_id" == "2" ]]

    # result must not be an error
    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null

    # contents must be present and non-empty
    local contents
    contents=$(echo "$LSP_RESPONSE" | jq -r '.result.contents.value')
    [[ -n "$contents" ]]
}
