# transport.bash — JSON-RPC framing and low-level send/recv
#
# Globals read:   LSP_READ_FD, LSP_WRITE_FD, LSP_TIMEOUT
# Globals written: LSP_RESPONSE, _LSTS_ID

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
