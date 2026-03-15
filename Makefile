.PHONY: all test lint

all:
	nix develop --command make test lint

lint:
	-shellcheck --shell=bash lsts.bash test/*_tests.bats

test:
	bats test/*_tests.bats
