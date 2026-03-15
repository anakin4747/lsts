# lsts.bash — Language Server Test Suite
#
# Load this file from a bats test with:
#   load '../lsts'          # adjust path relative to your test file
#
# Required globals (set before setup()):
#   LSP_CMD    — command to launch the language server, e.g. "kconfig-language-server"
#   LSTS_ROOT  — workspace root path passed to initialize (optional, defaults to null)
#
# Typical test file structure:
#
#   load '../lsts'
#
#   LSP_CMD="kconfig-language-server"
#   LSTS_ROOT="/path/to/fixture/workspace"
#
#   setup()    { lsp_start; }
#   teardown() { lsp_stop;  }
#
#   @test "hover on keyword returns docs" {
#       lsp_hover "file:///path/to/fixture/test.Kconfig" "kconfig" 0 0
#       echo "$LSP_RESPONSE" | jq -e '.result.contents'
#   }

# ---------------------------------------------------------------------------
# Transport — JSON-RPC framing and low-level send/recv
#
# Globals read:    LSP_READ_FD, LSP_WRITE_FD, LSP_TIMEOUT
# Globals written: LSP_RESPONSE, _LSTS_ID
# ---------------------------------------------------------------------------

_LSTS_ID=0

# Send a raw JSON string with Content-Length framing
lsp_send() {
	local body="$1"
	local len=${#body}
	printf "Content-Length: %d\r\n\r\n%s" "$len" "$body" >&"$LSP_WRITE_FD"
}

# Read one JSON-RPC message into LSP_RESPONSE.
# Must be called outside a subshell — coproc FDs are close-on-exec.
# Sanitizes unescaped control characters that some servers embed in string
# values (violating RFC 8259) so jq can parse the response.
lsp_recv() {
	local line content_length=0 raw

	while IFS= read -r -t "${LSP_TIMEOUT:-10}" line <&"$LSP_READ_FD"; do
		line="${line%$'\r'}"
		[[ -z "$line" ]] && break
		if [[ "$line" =~ ^Content-Length:\ ([0-9]+)$ ]]; then
			content_length="${BASH_REMATCH[1]}"
		fi
	done

	[[ "$content_length" -eq 0 ]] && {
		echo "lsp_recv: no Content-Length header received" >&2
		return 1
	}

	IFS= read -r -N "$content_length" -t "${LSP_TIMEOUT:-10}" raw <&"$LSP_READ_FD"

	LSP_RESPONSE="$(printf '%s' "$raw" | tr '\t\n' '  ')"
}

# Send a JSON-RPC request with an auto-incremented id
lsp_request() {
	local method="$1" params="$2"
	_LSTS_ID=$((_LSTS_ID + 1))
	lsp_send "{\"jsonrpc\":\"2.0\",\"id\":${_LSTS_ID},\"method\":\"${method}\",\"params\":${params}}"
}

# Send a JSON-RPC notification (no id, no response expected)
lsp_notify() {
	local method="$1" params="$2"
	lsp_send "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params}}"
}

# ---------------------------------------------------------------------------
# Lifecycle — server process management
#
# Globals read:    LSP_CMD
# Globals written: LSP_READ_FD, LSP_WRITE_FD, LSP_PID, _LSTS_ID
# ---------------------------------------------------------------------------

# Start the language server as a coprocess.
# Call from bats setup().
# LSP_CMD must be set to the server executable before calling.
lsp_start() {
	: "${LSP_CMD:?LSP_CMD must be set to the language server command}"
	_LSTS_ID=0
	coproc LSP { ${LSP_CMD}; }
	LSP_READ_FD=${LSP[0]}
	LSP_WRITE_FD=${LSP[1]}
}

# Stop the language server gracefully, then forcefully if needed.
# Call from bats teardown().
lsp_stop() {
	lsp_notify "exit" "{}" 2>/dev/null || true
	kill "${LSP_PID:-}" 2>/dev/null || true
	wait "${LSP_PID:-}" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Initialize — LSP initialize/initialized handshake
#
# Globals read:    LSTS_ROOT
# Globals written: LSP_RESPONSE
# ---------------------------------------------------------------------------

# Perform the initialize request + initialized notification.
# This must be the first exchange on every fresh server connection.
#
# LSTS_ROOT should be set to the workspace root path before calling any
# method helper. It is passed as both rootUri and rootPath for compatibility
# with servers that use either field.
#
# Populates LSP_RESPONSE with the InitializeResult on success.
# Returns non-zero if the server responds with an error.
lsp_initialize() {
	local root

	if [[ -n "${LSTS_ROOT:-}" ]]; then
		root="\"${LSTS_ROOT}\""
	else
		root="null"
	fi

	lsp_request "initialize" \
		"{\"processId\":null,\"rootUri\":${root},\"rootPath\":${root},\"capabilities\":{}}"
	lsp_recv

	# Fail fast if the server returned a JSON-RPC error
	local err
	err="$(printf '%s' "$LSP_RESPONSE" | jq -r '.error')"
	[[ "$err" == "null" ]] || {
		echo "lsp_initialize: server returned error: $err" >&2
		return 1
	}

	lsp_notify "initialized" "{}"
}

# ---------------------------------------------------------------------------
# textDocument/hover
#
# Globals read:    LSTS_ROOT
# Globals written: LSP_RESPONSE
# ---------------------------------------------------------------------------

# Send the full initialize handshake followed by a textDocument/didOpen
# notification and a textDocument/hover request.
#
# Usage:
#   lsp_hover <uri> <languageId> <line> <character>
#
#   uri          — file URI of the document, e.g. "file:///path/to/file.kconfig"
#   languageId   — language identifier string, e.g. "kconfig"
#   line         — zero-based line number of the hover position
#   character    — zero-based character offset of the hover position
#
# The test author is responsible for the fixture file existing on disk at the
# path encoded in <uri> before calling this function.
#
# Populates LSP_RESPONSE with the Hover result (or null result) on success.
lsp_hover() {
	local uri="$1" language_id="$2" line="$3" character="$4"

	lsp_initialize

	lsp_notify "textDocument/didOpen" \
		"{\"textDocument\":{\"uri\":\"${uri}\",\"languageId\":\"${language_id}\",\"version\":1,\"text\":\"\"}}"

	lsp_request "textDocument/hover" \
		"{\"textDocument\":{\"uri\":\"${uri}\"},\"position\":{\"line\":${line},\"character\":${character}}}"
	lsp_recv
}
