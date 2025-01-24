return {
  { -- color highlighter
    'norcalli/nvim-colorizer.lua',
  },
  {
    -- one stop shop for vim colorschemes
    'flazz/vim-colorschemes',
    config = function()
      vim.cmd([[
        colorscheme evening
      ]])
    end,
  }
}
