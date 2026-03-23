
test if the language server implements all the capabilities they say they do
this would allow the test framework to write itself based on the capabilities
from initialization

- Add simple way to create input fixtures and output fixtures. Likely needs
  editor scripting to get this. Like I am in a file and I want to create a test
  for my exact cursor location
- separate neovim plugin for that

---

how to make all tests provide the location of where the test is defined in an
output like `grep -rn`

---

language server benchmarks with this test converage


---

how to specify test fixtures in more readable ways like via markdown instead of
markdown inside json but still being able to choose either


---

Show me the human readable markdown test fixtures so that I can approve of them
before you continue.

---

## Potential lsts enhancements to upstream

These are missing helpers that would allow wksls tests to use lsts conventions
rather than calling `lsts_notify`/`lsts_request` inline.

- **`lsts_change <path> <version> <new-text>`:** A helper for
  `textDocument/didChange` (full-sync). Would let the `didChange` test use a
  single lsts call instead of hand-building the notification params.

- **`lsts_close <path>`:** A helper for `textDocument/didClose`. Needed before
  a `didClose` test can be written using lsts conventions.

- **`lsts_shutdown`:** A helper that sends the `shutdown` request and waits for
  a response, then sends `exit`. Needed before a conformant shutdown test can be
  written using lsts conventions.

- **`lsts_recv_notification`:** A helper that reads messages until a
  server-initiated notification (no `id`, has `method`) is received. Needed to
  test push-model diagnostics (`textDocument/publishDiagnostics`).

- **Position-only request helpers that skip implicit initialize/open:** `lsts_hover`
  always calls `lsts_initialize` and `lsts_open` internally. Tests that need to
  send a request mid-session (e.g. after a `didChange`) cannot use `lsts_hover`
  and must hand-roll `lsts_request`/`lsts_recv_response` instead.

## Potential lsts bugs to upstream

These were observed while debugging wksls and may warrant fixes or improvements
in the `tests/lsts` submodule.

- **No strict mode:** `lsts` does not use `set -o errexit/nounset/pipefail`.
  Not fixable as a sourced library: enabling `errexit` in a sourced file
  affects the calling bats shell, which deliberately disables it between test
  blocks. Enabling `nounset` breaks `${LSTS_PID:-}` patterns used
  intentionally throughout. Functions should instead check return codes
  explicitly.

- **`lsts_initialize` does not assert specific capabilities:** It only checks
  that `.result.capabilities` is an object. Asserting specific capabilities
  here would make the library opinionated about which features a server must
  advertise, breaking servers that expose capabilities incrementally or under
  different keys. Tests that care about specific capabilities should assert
  them directly after calling `lsts_initialize`.

- ~~**`lsts_stop` sends `exit` with params `{}`**~~ Fixed: exit notification
  now sends `null` params as required by the LSP spec.

- ~~**`lsts_recv_response` has no timeout on the outer loop**~~ Fixed: the
  loop now aborts with an error after `LSTS_TIMEOUT` seconds (default 10).

- ~~**`LSTS_RESPONSE` normalises tabs and newlines to spaces**~~ Fixed: `tr`
  replaced with `jq -c` so responses are compacted to canonical JSON
  regardless of server formatting.

- allow fixtures to support preprocessing so that one developers path isn't
  hardcoded into every test
