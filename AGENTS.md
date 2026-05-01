
# Language Server Test Suite

I want to make a `bats` library for testing language servers since the tests
for any language server will be similar.

Since all LSPs use json-rpc I need to send JSON data with a header to and from
the language servers.

I want this test suite to provide an easy way to start the language server
under test and then send it on stdin the initialization request and confirm it
provides the correct response. I also want it to test sending it the
initialiazation request and then another request like hover.

Help me come up with how to properly structure this as a bats library that can
be reused in several language servers for rigorous end to end testing

## The ./language-server-protocol folder

This folder is the git repo for the offical language server protocol
specification from microsoft. Use this as reference for expected methods and
arguments to methods.

## Git discipline

Commit every logical atomic addition or change using git. Each commit should
represent one coherent unit of work (e.g. add a helper function, fix a bug,
update the flake). Do not batch unrelated changes into a single commit. Commit
messages MUST follow the [Conventional Commits](https://www.conventionalcommits.org/)
spec — CI will reject commits that don't. Allowed types are defined in
`cog.toml`.

## CI

After pushing a branch or opening a PR, ALWAYS check that CI passes before
considering the work done. Use `gh run list --repo anakin4747/lsts` to see the
latest run status, and `gh run view <id> --log-failed` to see failure details.
Do not move on to the next task until CI is green. If CI fails, diagnose the
root cause and fix it. If the failure was introduced by the immediately
preceding commit and that commit has not yet been pushed to a remote, amend it.
Otherwise create a new `fix:` commit.

## Amending commits

If a review comment or CI failure reveals a mistake in the immediately
preceding commit, **amend that commit** rather than adding a new one — provided
the commit has not yet been pushed, or you are the sole author and a force-push
is acceptable. Only create a new commit if the original commit is already part
of shared history that others may have based work on.

## Code review

After creating a commit code review your work. Ask the following questions to
see how the code can be made cleaner:
- Did your change create any dead code?
- Did your change invalidate some comments?
- Is your change in the style of the codebase?
- Can guard clauses be used to avoid indenting?
- Can this code be refactored into a function to improve readibility?
- Is this commit atomic and only focused on one topic?
- Did anything unrelated get included in the commit by accident?
- Does this code reuse functionality already present in the codebase?
- Did the commit duplicate any functionality already present in the codebase?
- Is there a simplier way to implement this solution?
- Did you add anything extra functionality that doesn't have a corresponding
  test?

If fixes are needed and the commit has not yet been pushed, amend it.
Otherwise create a new fix commit.
