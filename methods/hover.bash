# hover.bash — textDocument/hover method helper
#
# Globals read:   LSTS_ROOT
# Globals written: LSP_RESPONSE

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
