local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rf', '<cmd>TSToolsRenameFile<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ri', '<cmd>TSToolsRemoveUnusedImports<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rs', '<cmd>TSToolsRemoveUnused<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>mi', '<cmd>TSToolsAddMissingImports<CR>', opts)
end
return {
  {
    'pmizio/typescript-tools.nvim',
    opts = {
      on_attach = on_attach,
    },
  }
}
