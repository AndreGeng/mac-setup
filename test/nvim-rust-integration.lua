local root = assert(vim.env.MAC_SETUP_TEST_ROOT)
local project = assert(vim.env.RUST_TEST_DIR)
vim.opt.rtp:prepend(root .. '/config/nvim')
vim.opt.rtp:append(vim.fn.expand('~/.local/share/nvim/lazy/nvim-lspconfig'))
vim.opt.rtp:append(vim.fn.expand('~/.local/share/nvim/lazy/conform.nvim'))
package.preload.cmp_nvim_lsp = function()
  return { default_capabilities = function(c) return c end }
end
-- Load the actual repository LSP configuration without starting plugin installers.
dofile(root .. '/config/nvim/lua/plugins/lsp.lua')[1].init()
vim.cmd.cd(project)
vim.cmd.edit(project .. '/src/main.rs')
vim.bo.filetype = 'rust'
assert(vim.wait(30000, function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'rust_analyzer' })[1]
  return client and client.initialized
end, 100), 'rust-analyzer did not attach')
local client = vim.lsp.get_clients({ bufnr = 0, name = 'rust_analyzer' })[1]
local column = assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]:find('answer', 1, true)) - 1
local params = {
  textDocument = { uri = vim.uri_from_bufnr(0) },
  position = { line = 1, character = column },
}
-- Initial workspace indexing can finish after LSP initialization.
assert(vim.wait(60000, function()
  local response = client:request_sync('textDocument/definition', params, 2000, 0)
  return response and response.result and #response.result > 0
end, 500), 'cross-module definition lookup failed')
vim.api.nvim_win_set_cursor(0, { 2, column })
vim.cmd('normal gd')
assert(vim.wait(10000, function()
  return vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(project .. '/src/helper.rs')
end, 100), 'gd did not jump to helper.rs; current buffer: ' .. vim.api.nvim_buf_get_name(0))
vim.cmd.edit(project .. '/src/main.rs')
local spec = dofile(root .. '/config/nvim/lua/plugins/conform.lua')
require('conform').setup(spec.opts)
vim.cmd.write()
assert(vim.fn.readfile(project .. '/src/main.rs')[2] == 'fn main() {', 'rustfmt did not format on save')
client:stop(true)
print('PASS real rust-analyzer attachment, cross-module gd, and rustfmt on save')
