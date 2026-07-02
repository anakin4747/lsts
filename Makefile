.PHONY: all
all:
	nix develop \
		--extra-experimental-features 'nix-command flakes' \
		--command make test lint lint_commit

.PHONY: lint_commit
lint_commit:
	cog check

.PHONY: lint
lint:
	shellcheck --shell=bash lsts test/fake-ls test/*_tests.bats

.PHONY: test
test:
	bats --formatter $(CURDIR)/lsts-format-pretty test/lsts_tests.bats

.PHONY: release
release:
	nix develop \
		--extra-experimental-features 'nix-command flakes' \
		--command ./scripts/release
