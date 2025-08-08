return {
  {
    -- extend %
    'andymass/vim-matchup'
  },
  {
    -- auto rename closing HTML/XML tags
    'AndrewRadev/tagalong.vim'
  },
  {
    -- comment stuff out
    'numToStr/Comment.nvim',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        padding = true,
        sticky = true,
        ignore = nil,
        toggler = {
          ---Line-comment toggle keymap
          line = 'gcc',
          ---Block-comment toggle keymap
          block = 'gbc',
        },
      }
    end
  },
  {
    -- common used mappings [q,]q fro :cnext, :cprevious
    'tpope/vim-unimpaired',
  },
  {
    -- icons
    'kyazdani42/nvim-web-devicons',
  },
  {
    -- This plugin provides basic support for .env and Procfile
    'tpope/vim-dotenv'
  },
  { 'editorconfig/editorconfig-vim' },
  {
    -- Auto close parentheses and repeat by dot dot dot...
    'cohama/lexima.vim',
  },
  {
    -- zoom window using <c-w>o
    'troydm/zoomwintab.vim',
  },
  {
    -- quick rename var: crs(snake_case), crm(MixedCase),crc(camelCase),cru(UPPER_CASE),cr-(dash-case),cr.(dot.case),cr<space>(space case),crt(Title Case)
    'tpope/vim-abolish',
  },
  {
    -- Repeat.vim remaps . in a way that plugins can tap into it.
    'tpope/vim-repeat',
  },
  {
    -- Surround.vim is all about "surroundings": parentheses, brackets, quotes, XML tags, and more.
    'tpope/vim-surround',
  },
  {
    -- A Neovim plugin for setting the commentstring option based on the cursor location in the file.
    -- Need to run "TSInstall tsx" to ensure parser exist
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end
  },
  {
    -- extend text objects
    -- Vim plugin that provides additional text objects
    'wellle/targets.vim',
  }
}
