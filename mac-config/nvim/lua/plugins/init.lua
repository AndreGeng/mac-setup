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

  -- auto rename closing HTML/XML tags
  'AndrewRadev/tagalong.vim',
  -- All the lua functions I don't want to write twice
  'nvim-lua/plenary.nvim',
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

  -- syntax
  'pangloss/vim-javascript',
  'leafgarland/typescript-vim',
  'othree/html5.vim',
  -- Vim syntax and indent plugin for .vue files
  'leafOfTree/vim-vue-plugin',

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
  -- a smooth scrolling neovim plugin written in lua
  'karb94/neoscroll.nvim'
})


vim.keymap.set('n', '<C-t>', ':call GoBackToRecentBuffer()<cr>', { noremap = true })


require('plugins.oil')
require('plugins.floaterm')
require('plugins.gv')
require('plugins.ack')
require('plugins.hop')
