local root = assert(vim.env.MAC_SETUP_TEST_ROOT)
vim.opt.rtp:prepend(root .. '/config/nvim')
local spec = dofile(root .. '/config/nvim/lua/plugins/conform.lua')
local events = {}
local conform = { format = function() events[#events + 1] = 'format' end }
package.loaded.conform = conform
spec.init()
-- Simulate Conform's documented format_on_save callback registration.
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    if spec.opts.format_on_save(args.buf) then conform.format() end
  end,
})
vim.bo.filetype = 'go'
local action = { edit = { changes = {} } }
local client = {
  offset_encoding = 'utf-16',
  request_sync = function(_, method, params)
    if method == 'textDocument/codeAction' then
      assert(params.context.only[1] == 'source.organizeImports')
      events[#events + 1] = 'imports'
      return { result = { action } }
    elseif method == 'codeAction/resolve' then
      return { result = { edit = { changes = {} } } }
    elseif method == 'workspace/executeCommand' then
      events[#events + 1] = 'command'
      return { result = vim.NIL }
    end
    error(method)
  end,
  supports_method = function() return true end,
}
vim.lsp.get_clients = function(filter)
  assert(filter.name == 'gopls')
  return { client }
end
vim.lsp.util.apply_workspace_edit = function(_, encoding)
  assert(encoding == 'utf-16')
  events[#events + 1] = 'edit'
end
local function save(expected)
  events = {}
  vim.api.nvim_exec_autocmds('BufWritePre', { buffer = 0 })
  assert(vim.deep_equal(events, expected), vim.inspect(events))
end
save({ 'imports', 'edit', 'format' })
vim.cmd('FormatDisable!')
save({})
vim.cmd('FormatEnable')
vim.cmd('FormatDisable')
save({})
vim.cmd('FormatEnable')
save({ 'imports', 'edit', 'format' })
vim.bo.filetype = 'lua'
save({ 'format' })
vim.bo.filetype = 'go'
action = { data = {} }
save({ 'imports', 'edit', 'format' })
action = { command = { command = 'gopls.apply_fix' } }
save({ 'imports', 'command', 'format' })
action = { disabled = { reason = 'unavailable' } }
save({ 'imports', 'format' })
client.request_sync = function() return nil, 'timeout' end
local ok, err = pcall(require('config.go').organize_imports, 0)
assert(not ok and tostring(err):find('timeout', 1, true))
vim.lsp.get_clients = function() return {} end
save({ 'format' })
assert(spec.opts.formatters_by_ft.go.lsp_format == 'prefer')
print('PASS Go save order, one format, disable flags, non-Go, resolve, commands, errors, no client')
