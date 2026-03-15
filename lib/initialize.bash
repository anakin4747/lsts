# initialize.bash — LSP initialize/initialized handshake
#
# Globals read:   LSTS_ROOT
# Globals written: LSP_RESPONSE

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
