.PHONY: all test lint

all: lint test

lint:
	nix develop --command shellcheck --shell=bash lsp_poc.bats
	nix develop --command shfmt --diff lsp_poc.bats

test:
	nix develop --command bats lsp_poc.bats
