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
    printf "Content-Length: %d\r\n\r\n%s" "$len" "$body" >&"${LSP[1]}"
}

# Read one JSON-RPC message from the server.
# Reads the Content-Length header, then exactly that many bytes of body.
lsp_recv() {
    local header line content_length body

    # Read headers until blank line
    content_length=0
    while IFS= read -r -t "${LSP_TIMEOUT:-10}" line <&"${LSP[0]}"; do
        # Strip carriage return
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        if [[ "$line" =~ ^Content-Length:\ ([0-9]+)$ ]]; then
            content_length="${BASH_REMATCH[1]}"
        fi
    done

    [[ "$content_length" -eq 0 ]] && { echo "lsp_recv: no Content-Length" >&2; return 1; }

    # Read exactly content_length bytes
    IFS= read -r -N "$content_length" -t "${LSP_TIMEOUT:-10}" body <&"${LSP[0]}"
    printf '%s' "$body"
}

# Build a JSON-RPC request and send it; echoes the id used
lsp_request() {
    local id="$1" method="$2" params="$3"
    lsp_send "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":$params}"
}

# Build a JSON-RPC notification (no id) and send it
lsp_notify() {
    local method="$1" params="$2"
    lsp_send "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params}"
}

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

setup() {
    # Start the language server as a coprocess
    coproc LSP { $LSP_CMD; }
}

teardown() {
    # Best-effort graceful shutdown
    lsp_notify "exit" "{}" 2>/dev/null || true
    kill "${LSP_PID:-}" 2>/dev/null || true
    wait "${LSP_PID:-}" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "initialize returns capabilities" {
    local params response

    params=$(cat <<'EOF'
{
  "processId": null,
  "rootUri": null,
  "capabilities": {}
}
EOF
)
    lsp_request 1 "initialize" "$params"

    response=$(lsp_recv)

    # Must have a result field (not an error)
    echo "$response" | jq -e '.result' >/dev/null

    # Must have capabilities object
    echo "$response" | jq -e '.result.capabilities | objects' >/dev/null

    # id must match what we sent
    local got_id
    got_id=$(echo "$response" | jq -r '.id')
    [[ "$got_id" == "1" ]]
}

@test "initialize then initialized handshake completes without error" {
    local params response

    params='{"processId":null,"rootUri":null,"capabilities":{}}'

    lsp_request 1 "initialize" "$params"
    response=$(lsp_recv)

    # Server must not return an error
    run bash -c "echo '$response' | jq -e '.error' >/dev/null 2>&1"
    [ "$status" -ne 0 ]   # jq -e exits non-zero when key is null/absent

    # Send the initialized notification — server should not crash
    lsp_notify "initialized" "{}"

    # Give the server a moment; if it crashes the coproc fd closes
    sleep 0.1
    kill -0 "${LSP_PID}" 2>/dev/null
}
