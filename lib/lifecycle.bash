# lifecycle.bash — server process management
#
# Globals read:   LSP_CMD
# Globals written: LSP_READ_FD, LSP_WRITE_FD, LSP_PID, _LSTS_ID

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
