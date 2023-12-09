local has_rg = vim.fn.executable('rg')

-- Set global variable
if has_rg then
  vim.g.ackprg = "rg --vimgrep"
end

-- Define keymap
vim.keymap.set('n', '<leader>a', ':Ack -i ', { noremap = true })
