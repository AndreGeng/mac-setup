-- emmet
vim.keymap.set('i', '<tab>', '<plug>(emmet-expand-abbr)', { noremap = true })
-- useless
vim.g.user_emmet_leader_key='<C-\\>'
-- enable emmet for ts/tsx
vim.g.user_emmet_settings = {
  typescript = {
      extends = 'jsx',
  },
}

