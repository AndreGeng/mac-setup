
-- fzf
vim.keymap.set('n', '<leader>fo', ':Files<cr>', { noremap = true })
vim.env.FZF_DEFAULT_COMMAND = 'fd -i --type f'
vim.g.fzf_preview_window = {}
-- search all files, including hidden files and vsc ignored files
vim.keymap.set('n', '<leader>fa', ':call fzf#run(fzf#wrap({"source": "fd -i --type f --hidden -I"}))<cr>', { noremap = true })
