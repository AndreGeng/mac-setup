-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- In the quickfix window, simply edit any entry you like. Once you save the quickfix buffer, your changes will be made in the actual file an entry points to.
  'stefandtw/quickfix-reflector.vim',
  -- A vim-vinegar like file explorer that lets you edit your filesystem like a normal Neovim buffer
  'stevearc/oil.nvim',
  -- QFEnter allows you to open items from Vim's quickfix or location list wherever you wish.
  'yssl/QFEnter',
  -- extend %
  'andymass/vim-matchup',
  -- quickly select the closest text object
  -- 'gcmt/wildfire.vim'

  -- All the lua functions I don't want to write twice
  'nvim-lua/plenary.nvim',
  -- resize window
  {
    'simeji/winresizer',
    dependencies = {
      'nvim-lua/plenary.nvim',
    }
  },
  -- swap window
  'wesQ3/vim-windowswap',
  -- auto rename closing HTML/XML tags
  'AndrewRadev/tagalong.vim',
  -- When combined with a set of tmux key bindings, the plugin will allow you to navigate seamlessly between vim and tmux splits using a consistent set of hotkeys.
  'christoomey/vim-tmux-navigator',
  -- comment stuff out
  'tpope/vim-commentary',
  -- common used mappings [q,]q fro :cnext, :cprevious
  'tpope/vim-unimpaired',
  -- WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible key bindings of the command you started typing
  'folke/which-key.nvim',
  -- directory viewer
  'nvim-tree/nvim-tree.lua',
  -- icons
  'kyazdani42/nvim-web-devicons',

  -- find&replace
  'nvim-pack/nvim-spectre',

  -- fuzzy find
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
      },
    },
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' },
  'junegunn/fzf.vim',
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
    config = function()
      require("plugins.typescript-tools")
    end
  },

  -- basic
  'tpope/vim-dotenv',
  'editorconfig/editorconfig-vim',
  -- Auto close parentheses and repeat by dot dot dot...
  'cohama/lexima.vim',
  -- zoom window using <c-w>o
  'troydm/zoomwintab.vim',
  -- quick rename var: crs(snake_case), crm(MixedCase),crc(camelCase),cru(UPPER_CASE),cr-(dash-case),cr.(dot.case),cr<space>(space case),crt(Title Case)
  'tpope/vim-abolish',
  -- Repeat.vim remaps . in a way that plugins can tap into it.
  'tpope/vim-repeat',
  -- Surround.vim is all about "surroundings": parentheses, brackets, quotes, XML tags, and more.
  'tpope/vim-surround',
  -- find definition and reference
  'pechorin/any-jump.vim',
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  'JoosepAlviste/nvim-ts-context-commentstring',
  {
    'stevearc/conform.nvim',
    opts = {},
  },
  'mfussenegger/nvim-lint',

  -- extend text objects
  -- Vim plugin that provides additional text objects
  'wellle/targets.vim',
  -- cusom textobj
  'kana/vim-textobj-user',
  -- dae
  {
    'kana/vim-textobj-entire',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- dal
  {
    'kana/vim-textobj-line',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- dai
  {
    'kana/vim-textobj-indent',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- da/
  {
    'kana/vim-textobj-lastpat',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- dac
  {
    'glts/vim-textobj-comment',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- da, delete function parameter
  {
    'sgur/vim-textobj-parameter',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  -- dax, delete xml attr
  {
    'whatyouhide/vim-textobj-xmlattr',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
})


vim.keymap.set('n', '<C-t>', ':call GoBackToRecentBuffer()<cr>', { noremap = true })

require('plugins.oil')
require('plugins.nvim-tree')
require('plugins.which-key')
require('plugins.qf-enter')
require('plugins.tmux-navigator')
require('plugins.toggle-tool')
require('plugins.lsp')
require('plugins.treesitter')
require('plugins.windowswap')
require('plugins.winresizer')
require('plugins.telescope')
require('plugins.nvim-lint')
require('plugins.spectre')
