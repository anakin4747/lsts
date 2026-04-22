# lsts

A bash library for testing Language Server Protocol (LSP) servers with [bats](https://github.com/bats-core/bats-core).

## Usage

Source `lsts` in a bats test file, configure the language server, then call the provided helpers.

```bash
#!/usr/bin/env bats

source lsts

lsts_set_cmd "bash-language-server start"
lsts_set_root "$(dirname "$BATS_TEST_FILENAME")/fixtures/bash"
lsts_set_langId "shellscript"

setup()    { lsts_start; }
teardown() { lsts_stop; }

@test "hover returns documentation" {
    lsts_hover "main.sh:3:5" "hover.rpc.json"
}
```

Each `*.rpc.json` fixture contains the expected LSP response. Paths inside fixtures may use `$LSTS_ROOT` and standard environment variables; they are expanded at comparison time.

## Helpers

| Function | Description |
|---|---|
| `lsts_set_cmd <cmd>` | Command to start the language server |
| `lsts_set_root <dir>` | Workspace root passed to the server |
| `lsts_set_langId <id>` | Language identifier (e.g. `go`, `shellscript`) |
| `lsts_start` / `lsts_stop` | Start / stop the server process |
| `lsts_initialize` | Send LSP `initialize` / `initialized` |
| `lsts_hover <pos> <fixture>` | `textDocument/hover` |
| `lsts_completion <pos> <fixture>` | `textDocument/completion` |
| `lsts_definition <pos> <fixture>` | `textDocument/definition` |
| `lsts_references <pos> <inc-decl> <fixture>` | `textDocument/references` |
| `lsts_document_symbols <file> <fixture>` | `textDocument/documentSymbol` |
| `lsts_rename <pos> <new-name> <fixture>` | `textDocument/rename` |
| `lsts_formatting <file> <tab-size> <insert-spaces> <fixture>` | `textDocument/formatting` |
| `lsts_diagnostics <fixture>` | Wait for `textDocument/publishDiagnostics` |

## Running the tests

```sh
make
```

Requires [Nix](https://nixos.org/) — `nix develop` drops into a shell with all dependencies.

## License

GPL-2.0
