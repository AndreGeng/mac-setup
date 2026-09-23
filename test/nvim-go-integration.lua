local root = assert(vim.env.MAC_SETUP_TEST_ROOT)
vim.opt.rtp:prepend(root .. '/config/nvim')
vim.opt.rtp:append(assert(vim.env.CONFORM_TEST_PATH))
local spec = dofile(root .. '/config/nvim/lua/plugins/conform.lua')
spec.init()
require('conform').setup(spec.opts)
vim.cmd.edit(vim.env.GO_TEST_DIR .. '/main.go')
vim.bo.filetype = 'go'
local id = vim.lsp.start({
  name = 'gopls', cmd = { vim.fn.exepath('gopls') }, root_dir = vim.env.GO_TEST_DIR,
  settings = { gopls = { gofumpt = true } },
  capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = false } } },
})
assert(id, 'gopls failed to start')
assert(vim.wait(15000, function()
  local c = vim.lsp.get_client_by_id(id)
  return c and c.initialized and vim.lsp.buf_is_attached(0, id)
end, 100), 'gopls did not attach')
-- Request symbols from the actual server before exercising save hooks.
local client = vim.lsp.get_client_by_id(id)
local response = client:request_sync('textDocument/documentSymbol', {
  textDocument = vim.lsp.util.make_text_document_params(0),
}, 15000, 0)
assert(response and not response.err, vim.inspect(response))
vim.cmd.write()
local actual = table.concat(vim.fn.readfile(vim.env.GO_TEST_DIR .. '/main.go'), '\n')
assert(actual:find('import "fmt"', 1, true), actual)
assert(not actual:find('"os"', 1, true), actual)
assert(actual:find('func main() { fmt.Println("hello") }', 1, true), actual)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'package main', '', 'import "fmt"', '', 'func main(){fmt.Println("hello")}' })
vim.cmd('FormatDisable!')
vim.cmd.write()
local disabled = table.concat(vim.fn.readfile(vim.env.GO_TEST_DIR .. '/main.go'), '\n')
assert(disabled:find('func main(){', 1, true), disabled)
vim.cmd('FormatEnable')
vim.cmd.write()
local enabled = table.concat(vim.fn.readfile(vim.env.GO_TEST_DIR .. '/main.go'), '\n')
assert(enabled:find('func main() { fmt.Println', 1, true), enabled)
client:stop()
print('PASS real gopls + Conform: add/remove imports, format, save to disk, disable/re-enable')
