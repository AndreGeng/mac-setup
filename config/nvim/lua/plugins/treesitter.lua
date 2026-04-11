return {
  { 'HerringtonDarkholme/yats.vim' },
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'typescript', 'tsx', 'javascript', 'jsdoc',
        'lua', 'vim', 'vimdoc', 'html', 'css',
        'json', 'yaml', 'markdown', 'bash', 'python',
        'java',
      })
    end,
  },
}
