return {
  {
    'simeji/winresizer',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      vim.keymap.set('n', '<leader>m', ':WinResizerStartResize<cr>', { noremap = true })
    end,
  }
}
