local filename = assert(vim.env.RUST_STANDALONE_FILE)
local bufnr = vim.api.nvim_get_current_buf()
assert(vim.wait(15000, function()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'rust_analyzer' })[1]
  return client and client.initialized
end, 100), 'standalone rust-analyzer did not attach')
local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'rust_analyzer' })[1]
-- Notify without writing: the same check can inspect a real user's saved file.
client:notify('textDocument/didSave', { textDocument = { uri = vim.uri_from_bufnr(bufnr) } })
local function compiler_errors()
  return vim.tbl_filter(function(diagnostic)
    return diagnostic.code == 'E0277'
  end, vim.diagnostic.get(bufnr))
end
local next_check = 0
assert(vim.wait(45000, function()
  if vim.uv.now() >= next_check then
    client:notify('textDocument/didSave', { textDocument = { uri = vim.uri_from_bufnr(bufnr) } })
    next_check = vim.uv.now() + 2000
  end
  return #compiler_errors() > 0
end, 100),
  'standalone compiler error E0277 was not published to Neovim')
assert(compiler_errors()[1].severity == vim.diagnostic.severity.ERROR)
if vim.uv.fs_realpath(filename) == vim.uv.fs_realpath(vim.env.RUST_TEST_FIXTURE) then
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for index, line in ipairs(lines) do lines[index] = line:gsub('names%.iter%(%)', 'names.into_iter()') end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.cmd.write()
  assert(vim.wait(20000, function() return #compiler_errors() == 0 end, 100),
    'compiler diagnostic did not clear after correcting the fixture')
end
client:stop(true)
print('PASS full Neovim startup: standalone E0277 diagnostics and correction')
