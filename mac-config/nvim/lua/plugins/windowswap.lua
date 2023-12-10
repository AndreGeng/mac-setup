-- WindowSwap.vim
vim.g.windowswap_map_keys = 0 -- prevent default bindings
vim.keymap.set('n', '<leader>ss', ':call WindowSwap#EasyWindowSwap()<cr>', { noremap = true })

