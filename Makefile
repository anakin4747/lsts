.PHONY: all test lint

all:
	nix develop --command make test

lint:
	shellcheck --shell=bash lsts.bash test/lsts_tests.bats

test:
	bats test/lsts_tests.bats
