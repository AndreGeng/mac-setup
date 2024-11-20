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
  -- color highlighter
  'norcalli/nvim-colorizer.lua',
  -- <leader>dn delete nameless buffers
  'Asheq/close-buffers.vim',

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
  -- Single tabpage interface for easily cycling through diffs for all modified files for any git rev.
  'sindrets/diffview.nvim',
  -- auto rename closing HTML/XML tags
  'AndrewRadev/tagalong.vim',
  -- open built-in terminal in floating window
  'voldikss/vim-floaterm',
  -- easy motion
  'phaazon/hop.nvim',
  -- When combined with a set of tmux key bindings, the plugin will allow you to navigate seamlessly between vim and tmux splits using a consistent set of hotkeys.
  'christoomey/vim-tmux-navigator',
  -- comment stuff out
  'tpope/vim-commentary',
  -- git
  'tpope/vim-fugitive',
  -- common used mappings [q,]q fro :cnext, :cprevious
  'tpope/vim-unimpaired',
  -- show git history for specific range
  'junegunn/gv.vim',
  -- WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible key bindings of the command you started typing
  'folke/which-key.nvim',
  -- Run your favorite search tool from Vim, with an enhanced results list.
  'mileszs/ack.vim',
  -- emmet-vim is a vim plug-in which provides support for expanding abbreviations similar to emmet.
  'mattn/emmet-vim',
  -- directory viewer
  'nvim-tree/nvim-tree.lua',
  -- icons
  'kyazdani42/nvim-web-devicons',
  -- gitgutter
  'lewis6991/gitsigns.nvim',

  -- find&replace
  'nvim-pack/nvim-spectre',
  'junegunn/vim-easy-align',

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
  { 'junegunn/fzf',                             dir = '~/.fzf',                                                                                                                        build = './install --all' },
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
  -- one stop shop for vim colorschemes
  'flazz/vim-colorschemes',
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
  -- Neovim setup for init.lua and plugin development with full signature help, docs and completion for the nvim lua API.
  'folke/neodev.nvim',
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

  -- lsp
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  'neovim/nvim-lspconfig',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline',
  'hrsh7th/cmp-vsnip',
  'hrsh7th/vim-vsnip',
})


vim.keymap.set('n', '<C-t>', ':call GoBackToRecentBuffer()<cr>', { noremap = true })

-- for lua, IMPORTANT: make sure to setup neodev BEFORE lspconfig
require('plugins.neodev')
require('plugins.oil')
require('plugins.floaterm')
require('plugins.gv')
require('plugins.ack')
require('plugins.hop')
require('plugins.colorizer')
require('plugins.close-buffers')
require('plugins.nvim-tree')
require('plugins.gitsigns')
require('plugins.which-key')
require('plugins.qf-enter')
require('plugins.tmux-navigator')
require('plugins.toggle-tool')
require('plugins.cmp')
require('plugins.lsp')
require('plugins.treesitter')
require('plugins.diffview')
require('plugins.windowswap')
require('plugins.emmet')
require('plugins.winresizer')
require('plugins.telescope')
require('plugins.fzf')
require('plugins.conform')
require('plugins.nvim-lint')
require('plugins.colorscheme')
require('plugins.spectre')
require('plugins.easy-align')
