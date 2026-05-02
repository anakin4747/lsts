.PHONY: all test lint verify

all:
	nix develop --extra-experimental-features 'nix-command flakes' --command make test lint verify

verify:
	@cog verify "$(shell git log -1 --pretty=%B)" > /dev/null

lint:
	shellcheck --shell=bash lsts test/fake-ls test/*_tests.bats

test:
	bats --formatter $(CURDIR)/lsts-format-pretty test/lsts_tests.bats
