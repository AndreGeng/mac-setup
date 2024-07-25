local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>gr', '<cmd>TSToolsFileReferences<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rf', '<cmd>TSToolsRenameFile<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ri', '<cmd>TSToolsRemoveUnusedImports<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rs', '<cmd>TSToolsRemoveUnused<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ai', '<cmd>TSToolsAddMissingImports<CR>', opts)
end
require("typescript-tools").setup({
  on_attach = on_attach,
})
