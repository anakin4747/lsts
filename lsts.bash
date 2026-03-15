# lsts.bash — Language Server Test Suite
#
# Load this file from a bats test with:
#   load '../lsts'          # adjust path relative to your test file
#
# Required globals (set before setup()):
#   LSP_CMD    — command to launch the language server, e.g. "kconfig-language-server"
#   LSTS_ROOT  — workspace root path passed to initialize (optional, defaults to null)
#
# Typical test file structure:
#
#   load '../lsts'
#
#   LSP_CMD="kconfig-language-server"
#   LSTS_ROOT="/path/to/fixture/workspace"
#
#   setup()    { lsp_start; }
#   teardown() { lsp_stop;  }
#
#   @test "hover on keyword returns docs" {
#       lsp_hover "file:///path/to/fixture/test.Kconfig" "kconfig" 0 0
#       echo "$LSP_RESPONSE" | jq -e '.result.contents'
#   }

_LSTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/transport.bash
source "${_LSTS_DIR}/lib/transport.bash"
# shellcheck source=lib/lifecycle.bash
source "${_LSTS_DIR}/lib/lifecycle.bash"
# shellcheck source=lib/initialize.bash
source "${_LSTS_DIR}/lib/initialize.bash"
# shellcheck source=methods/hover.bash
source "${_LSTS_DIR}/methods/hover.bash"
