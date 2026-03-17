
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
messages should be concise and written in the imperative mood.

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

Fix the code accordingly in new commits.
