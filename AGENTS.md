
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
