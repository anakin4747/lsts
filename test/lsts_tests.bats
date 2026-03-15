#!/usr/bin/env bats

load '../lsts'

# ---------------------------------------------------------------------------
# kconfig-language-server
# ---------------------------------------------------------------------------

@test "kconfig: initialize returns capabilities" {
    LSP_CMD="kconfig-language-server"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures" && pwd)"
    lsp_start

    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "kconfig: initialize handshake completes without error" {
    LSP_CMD="kconfig-language-server"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures" && pwd)"
    lsp_start

    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

@test "kconfig: hover on 'config' keyword returns markdown documentation" {
    LSP_CMD="kconfig-language-server"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures" && pwd)"
    lsp_start

    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null

    local contents
    contents="$(echo "$LSP_RESPONSE" | jq -r '.result.contents.value')"
    [[ -n "$contents" ]]
}

@test "kconfig: hover response id matches the request" {
    LSP_CMD="kconfig-language-server"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures" && pwd)"
    lsp_start

    local fixture="${LSTS_ROOT}/test.Kconfig"
    local uri="file://${fixture}"

    lsp_hover "$uri" "kconfig" 0 0

    local got_id expected_id
    got_id="$(echo "$LSP_RESPONSE" | jq -r '.id')"
    expected_id=2
    [[ "$got_id" == "$expected_id" ]]
}

# ---------------------------------------------------------------------------
# gopls
# ---------------------------------------------------------------------------

@test "gopls: initialize returns capabilities" {
    LSP_CMD="gopls"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/go" && pwd)"
    lsp_start

    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "gopls: initialize handshake completes without error" {
    LSP_CMD="gopls"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/go" && pwd)"
    lsp_start

    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

@test "gopls: hover on 'fmt' package returns documentation" {
    LSP_CMD="gopls"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/go" && pwd)"
    lsp_start

    local fixture="${LSTS_ROOT}/main.go"
    local uri="file://${fixture}"

    lsp_hover "$uri" "go" 2 8

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null
}

# ---------------------------------------------------------------------------
# pyright
# ---------------------------------------------------------------------------

@test "pyright: initialize returns capabilities" {
    LSP_CMD="pyright-langserver --stdio"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/python" && pwd)"
    lsp_start

    lsp_initialize

    echo "$LSP_RESPONSE" | jq -e '.result.capabilities | objects' >/dev/null
}

@test "pyright: initialize handshake completes without error" {
    LSP_CMD="pyright-langserver --stdio"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/python" && pwd)"
    lsp_start

    lsp_initialize

    local err
    err="$(echo "$LSP_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]]

    kill -0 "${LSP_PID}"
}

@test "pyright: hover on 'len' returns documentation" {
    LSP_CMD="pyright-langserver --stdio"
    LSTS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures/python" && pwd)"
    lsp_start

    local fixture="${LSTS_ROOT}/main.py"
    local uri="file://${fixture}"

    lsp_hover "$uri" "python" 1 8

    echo "$LSP_RESPONSE" | jq -e '.result' >/dev/null
}

teardown() { lsp_stop; }
