local filename = assert(vim.env.RUST_STANDALONE_FILE)
local bufnr = vim.api.nvim_get_current_buf()
assert(vim.bo[bufnr].filetype == 'rust', 'fixture must be a Rust buffer')
assert(vim.wait(15000, function()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'rust_analyzer' })[1]
  return client and client.initialized
end, 100), 'standalone rust-analyzer did not attach')
local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'rust_analyzer' })[1]
local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
local call_line, column
for index, line in ipairs(lines) do
  if not line:match('^fn ') then
    local start = line:find('transpose(', 1, true)
    if start then call_line, column = index, start - 1 end
  end
end
assert(call_line, 'fixture must call transpose')
assert(vim.wait(20000, function()
  local response = client:request_sync('textDocument/definition', {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = call_line - 1, character = column },
  }, 2000, bufnr)
  return response and response.result and #response.result > 0
end, 500), 'standalone definition lookup returned no result')
vim.api.nvim_win_set_cursor(0, { call_line, column })
vim.cmd('normal gd')
assert(vim.wait(5000, function()
  local line = vim.api.nvim_get_current_line()
  return line:match('^fn transpose') ~= nil
end, 100), 'gd did not jump to the standalone function; mapping: '
  .. vim.inspect(vim.fn.maparg('gd', 'n', false, true))
  .. '; cursor: ' .. vim.inspect(vim.api.nvim_win_get_cursor(0))
  .. '; line: ' .. vim.api.nvim_get_current_line())
assert(vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(filename))
client:stop(true)
print('PASS full Neovim startup: standalone Rust function gd')
