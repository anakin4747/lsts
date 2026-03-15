.PHONY: all test lint

all:
	nix develop --command make lint test

lint:
	shellcheck --shell=bash lsp_poc.bats

test:
	bats lsp_poc.bats
