return {
  'wesQ3/vim-windowswap',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    -- WindowSwap.vim
    vim.g.windowswap_map_keys = 0 -- prevent default bindings
    vim.keymap.set('n', '<leader>ss', ':call WindowSwap#EasyWindowSwap()<cr>', { noremap = true })
  end,
}
