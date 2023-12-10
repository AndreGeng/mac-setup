-- ranger
vim.keymap.set('n', '<leader>r', ':RnvimrToggle<cr>', { noremap = true })
vim.keymap.set('t', '<leader>r', '<C-\\><C-n>:RnvimrToggle<cr>', { noremap = true })
vim.keymap.set('t', '<C-i>', '<C-\\><C-n>:RnvimrResize<cr>', { noremap = true })
vim.keymap.set('t', '<A-f>', 'fzf_select', { noremap = true })

-- Make Ranger to be hidden after picking a file
vim.g.rnvimr_enable_picker = 1

