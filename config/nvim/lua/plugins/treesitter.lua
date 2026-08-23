local parsers = {
  'typescript', 'tsx', 'javascript', 'jsdoc',
  'lua', 'vim', 'vimdoc', 'html', 'css',
  'json', 'yaml', 'markdown', 'bash', 'python',
  'java', 'go', 'gomod', 'gosum', 'gowork',
}

return {
  { 'HerringtonDarkholme/yats.vim' },
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local install = require('nvim-treesitter').install(parsers)
      if vim.env.MAC_SETUP_NVIM_BOOTSTRAP == '1' then
        install:wait(300000)
      end
    end,
  },
}
