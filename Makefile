.PHONY: all test lint

all:
	nix develop --extra-experimental-features 'nix-command flakes' --command make test lint

lint:
	-shellcheck --shell=bash lsts test/*_tests.bats

test:
	bats --formatter $(CURDIR)/lsts-format-pretty test/*_tests.bats
