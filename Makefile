.PHONY: all
all:
	nix develop --extra-experimental-features 'nix-command flakes' --command make test lint verify

.PHONY: verify
verify:
	@cog verify "$(shell git log -1 --pretty=%B)" &> /dev/null

.PHONY: lint
lint:
	shellcheck --shell=bash lsts test/fake-ls test/*_tests.bats

.PHONY: test
test:
	bats --formatter $(CURDIR)/lsts-format-pretty test/lsts_tests.bats

.PHONY: release
release:
	nix develop --extra-experimental-features 'nix-command flakes' --command cog bump --auto
	git push --follow-tags
