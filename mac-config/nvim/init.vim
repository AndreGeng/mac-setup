" Basic configurations {{{
" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
" copy to system clipboard
set clipboard+=unnamedplus
language zh_CN.UTF-8

" jump between unsaved buffers without the E37
set hidden

" set lazyredraw, makes nvim smooth in tmux
set lazyredraw

" show number column
set number
set relativenumber

" indent
set autoindent
" use whitespace insteadof tab
set expandtab
" set shiftround, used to auto indent
set shiftround
set shiftwidth=2

" set tab width
set softtabstop=2
set tabstop=2

" search
set ignorecase
set smartcase

" diff ignore whitespace
set diffopt+=iwhite,vertical

" setup nvim with python support
let g:python_host_prog = $HOME.'/.pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME.'/.pyenv/versions/neovim3/bin/python'

" complete setting
set complete+=i

" fix webpack watch option
set backupcopy=yes

" Maintain undo history between sessions
set undofile

set encoding=utf-8 fileencodings=ucs-bom,utf-8,cp936

" Disable vim E211: File no longer available @see
" https://stackoverflow.com/questions/52780939/disable-vim-e211-file-no-longer-available
autocmd FileChangedShell * execute

" autoread
set autoread
au CursorHold,CursorHoldI,FocusGained * :checktime

" default updatetime 4000ms is not good for async update
set updatetime=100

" folding
augroup folding
  au!
  au FileType git,javascript,javascript.jsx,typescript,typescript.tsx setlocal foldmethod=indent
  au FileType zsh,vim setlocal foldmethod=marker
augroup END

" disable matchparen plugin
let g:loaded_matchparen=1
" disable syntax highlight for large file
autocmd BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | endif
" }}}

" FileType specific setting {{{
" map extension to filetype
autocmd BufEnter *.less.module :setlocal filetype=less
autocmd BufEnter *.pcss :setlocal filetype=scss
autocmd BufEnter *.wxml :setlocal filetype=html
autocmd BufEnter *.ejs :setlocal filetype=html
autocmd BufEnter *.wxss :setlocal filetype=css
autocmd BufEnter *.md,*.mdx :setlocal filetype=markdown
autocmd BufEnter *.jsx :setlocal filetype=javascript.jsx
autocmd BufEnter *.js :setlocal filetype=javascript
autocmd BufEnter *.tsx :setlocal filetype=typescript.tsx
autocmd BufEnter *.ts :setlocal filetype=typescript
autocmd BufEnter *.json :setlocal filetype=jsonc

" }}}

" Custom mapping {{{
" fold shortcut
nnoremap <Space> za
" terminal
tnoremap <C-g> <C-\><C-n>
" Fast saving
nmap <leader>w :w!<cr>
" smart way to close pane
nnoremap <leader>q :q<CR>
" Fast eval
nmap <leader>en :w !node<cr>
nmap <leader>em :w !node --experimental-modules --input-type=module --es-module-specifier-resolution=node<cr>
nmap <leader>et :w !ts-node<cr>

" git shortcut
nnoremap <leader>gs :G<CR>:on<CR>
nnoremap <leader>gb :Gblame<CR>

" buffer explorer
nnoremap <leader>be :Buffers<CR>

" cmdline mapping
cnoremap <C-A> <Home>

" Move a line of text using ALT+[m,], @see https://vim.fandom.com/wiki/Moving_lines_up_or_down
nnoremap <A-m> :m .+1<CR>==
nnoremap <A-,> :m .-2<CR>==
inoremap <A-m> <Esc>:m .+1<CR>==gi
inoremap <A-,> <Esc>:m .-2<CR>==gi
vnoremap <A-m> :m '>+1<CR>gv=gv
vnoremap <A-,> :m '<-2<CR>gv=gv

" Useful mappings for managing tabs
map <leader>tt :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tn :tabnext<cr>
map <leader>tp :tabp<cr>

" always use very magic when search
nnoremap / /\v

"toggle quickfixlist/locationlist -- start
function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction

function! ToggleList(bufname, pfx)
  if bufname('%') == '[Command Line]'
    return
  endif
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      exec(a:pfx.'close')
      return
    endif
  endfor
  if a:pfx == 'l' && len(getloclist(0)) == 0
    echohl ErrorMsg
    echo "Location List is Empty."
    return
  endif
  let winnr = winnr()
  exec(a:pfx.'open')
  wincmd J
  if winnr() != winnr
    wincmd p
  endif
endfunction

nmap <silent> <leader>l :call ToggleList("Location", 'l')<CR>
nmap <silent> <leader>k :call ToggleList("Quickfix", 'c')<CR>
"toggle quickfixlist/locationlist -- end

" auto resize window size when container window size changed
autocmd VimResized * wincmd =

" <C-t>: go back to previous buffer
function! GoBackToRecentBuffer()
  let startName = bufname('%')
  while 1
    exe "normal! \<c-o>"
    let nowName = bufname('%')
    if nowName != startName
      break
    endif
  endwhile
endfunction

nnoremap <silent> <C-t> :call GoBackToRecentBuffer()<Enter>
"}}}

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'phaazon/hop.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'sindrets/diffview.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'Asheq/close-buffers.vim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'karb94/neoscroll.nvim'
Plug 'AndrewRadev/tagalong.vim'
Plug 'pechorin/any-jump.vim'
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'tpope/vim-repeat'
Plug 'gcmt/wildfire.vim'
" language packs for vim
Plug 'justinmk/vim-dirvish'
Plug 'leafOfTree/vim-vue-plugin'
Plug 'bash-lsp/bash-language-server'
Plug 'jreybert/vimagit'
" markdown preview
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
" allow comments in json
Plug 'neoclide/jsonc.vim'
" open built-in terminal in floating window
Plug 'voldikss/vim-floaterm'
" multi cursor support, use <tab> to switch mode
Plug 'mg979/vim-visual-multi'
" git
Plug 'tpope/vim-fugitive'
" show git history for specific range
Plug 'junegunn/gv.vim'
" Vim plugin that provides additional text objects
Plug 'wellle/targets.vim'
" common used mappings [q,]q fro :cnext, :cprevious
Plug 'tpope/vim-unimpaired'
" quick rename var: crs(snake_case), crm(MixedCase),crc(camelCase),cru(UPPER_CASE),cr-(dash-case),cr.(dot.case),cr<space>(space case),crt(Title Case)
Plug 'tpope/vim-abolish'
" zoom window using <c-w>o
Plug 'troydm/zoomwintab.vim'

" familiar
Plug 'christoomey/vim-tmux-navigator'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
" comment stuff out
Plug 'tpope/vim-commentary'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'JoosepAlviste/nvim-ts-context-commentstring'
Plug 'w0rp/ale'
Plug 'itchyny/lightline.vim'
Plug 'flazz/vim-colorschemes'
Plug 'jiangmiao/auto-pairs'
Plug 'mattn/emmet-vim'
" Plug 'andymass/vim-matchup'
Plug 'Chiel92/vim-autoformat'
Plug 'henrik/vim-indexed-search'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'
Plug 'kana/vim-textobj-line'
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-lastpat'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-surround'
Plug 'nelstrom/vim-visual-star-search'
Plug 'wesQ3/vim-windowswap'
" gist -- start
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
" gist -- end
" syntax -- start
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'othree/html5.vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'stephpy/vim-yaml'
Plug 'tpope/vim-dotenv'
" syntax -- end
" seldom used -- start
" open items in quickfix window wherever you wish, <leader><enter> vertical split, <leader><space> horizontal split
Plug 'yssl/QFEnter'
" gf jump to file
Plug 'moll/vim-node'
" seldom used -- end
call plug#end()
" }}}

" Plugin configurations {{{
" color scheme
set termguicolors
set background=dark
colorscheme evening
autocmd BufEnter,SourcePre * highlight Search guibg=none guifg=#50FA7B gui=underline
" autocmd FilterWritePre * if &diff | colorscheme apprentice | endif

" multi
let g:VM_manual_infoline = 1
let g:VM_maps = {}
let g:VM_maps["Add Cursor Down"] = '<M-j>'      " start selecting down
let g:VM_maps["Add Cursor Up"]   = '<M-k>'        " start selecting up
let g:VM_maps["Undo"] = 'u'
let g:VM_maps["Redo"] = '<C-r>'
let g:VM_highlight_matches = 'underline'
let g:VM_theme = 'iceblue'
let g:VM_leader = ',,'
" fzf
nmap <leader>f :Files<CR>
let $FZF_DEFAULT_COMMAND = 'fd -i --type f'
let g:fzf_preview_window = []
" search all files, including hidden files and vsc ignored files
nmap <leader>gf :call fzf#run(fzf#wrap({'source': 'fd -i --type f --hidden -I'}))<CR>

" CTRL-A CTRL-Q to select all and build quickfix list
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_action = {
      \ 'ctrl-q': function('s:build_quickfix_list'),
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'split',
      \ 'ctrl-v': 'vsplit' }

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'
" Ack
if executable('rg')
  let g:ackprg = 'rg --vimgrep'
endif
nmap <leader>a :Ack -i 
" nmap <leader>a :Rg -i

" expand region shortcut
vmap v <Plug>(expand_region_expand)
vmap V <Plug>(expand_region_shrink)
" lightline
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['fugitive', 'readonly', 'relativepath', 'modified', 'filetype'] ],
      \   'right': [ [ 'lineinfo' ], ['percent'] ]
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
      \   'fugitive': '%{exists("*fugitive#head")?fugitive#head():""}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*fugitive#head") && ""!=fugitive#head())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': ' ' }
      \ }
" autoformat
let g:formatters_jsonc=['jsbeautify_json']
let g:formatters_javascript=['jsbeautify_javascript']

map <leader>af :Autoformat<CR>
" gv.vim
nnoremap <leader>gv :GV!<CR>
vnoremap <leader>gv :GV!<CR>

" ALE
let g:ale_linters = {
      \  'javascript': ['eslint'],
      \  'javascript.jsx': ['eslint'],
      \  'typescript': ['eslint'],
      \  'typescript.tsx': ['eslint'],
      \  'sh': ['language_server'],
      \}
let g:ale_fixers = {
      \   'javascript': ['prettier'],
      \   'javascript.jsx': ['prettier'],
      \   'typescript': ['prettier'],
      \   'typescript.tsx': ['prettier'],
      \   'json': ['prettier'],
      \   'jsonc': ['prettier'],
      \   'css': ['prettier'],
      \   'scss': ['prettier'],
      \   'less': ['prettier'],
      \   'sass': ['prettier'],
      \   'sh': ['shfmt'],
      \}

" @see https://prettier.io/docs/en/vim.html
let g:ale_linters_explicit = 1
let g:ale_fix_on_save = 1


"Set this setting in vimrc if you want to fix files automatically on save.
"This is off by default.
" let g:ale_fix_on_save = 1
nmap <leader>af :ALEFix<CR>

" tmux navigator: Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1

" xkbswitch
let g:XkbSwitchEnabled = 1

" bufexplorer
let g:bufExplorerShowRelativePath=1

" vim-indexed-search
let g:indexed_search_max_hits = 1.0e6
let g:indexed_search_max_lines = 1.0e6

" emmet
imap <expr> <tab> emmet#expandAbbrIntelligent("\<c-i>")
" useless
let g:user_emmet_leader_key='<C-\>'
" enable emmet for ts/tsx
let g:user_emmet_settings = {
      \ 'typescript' : {
      \     'extends' : 'jsx',
      \ },
      \}

" WindowSwap.vim
let g:windowswap_map_keys = 0 "prevent default bindings
nnoremap <silent> <leader>ss :call WindowSwap#EasyWindowSwap()<CR>
" floaterm
nnoremap <C-g> :FloatermToggle<CR>

" netrw
" 修复<ctrl-l>被netrw覆盖的问题
augroup netrw_mapping
  autocmd!
  autocmd filetype netrw call NetrwMapping()
augroup END

function! NetrwMapping()
  nnoremap <silent> <buffer> <c-l> :TmuxNavigateRight<CR>
endfunction
" 禁止netrw保存history or bookmarks
let g:netrw_dirhistmax = 0

" vim-javascript
let g:javascript_plugin_jsdoc = 1

" dirvish
let g:dirvish_mode = ':sort ,^.*[\/],'
" integrage lazygit into vim
nnoremap <C-a> :tabnew<CR>:-tabmove<CR>:term lazygit<CR>a
augroup terminal_settings
  autocmd!
  " Ignore various filetypes as those will close terminal automatically
  " Ignore fzf, ranger, coc
  autocmd TermClose term://*
        \ if (expand('<afile>') !~ "fzf") && (expand('<afile>') !~ "ranger") && (expand('<afile>') !~ "coc") |
        \   call nvim_input('<CR>')  |
        \ endif
augroup END

" quickfix easy open
let g:qfenter_keymap = {}
let g:qfenter_keymap.vopen = ['<C-v>']
let g:qfenter_keymap.hopen = ['<C-s>']
" ranger
let g:ranger_map_keys = 0
nnoremap <leader>r :Ranger<CR>
" nvim-treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = {}, -- List of parsers to ignore installing
  highlight = {
    enable = false,              -- false will disable the whole extension
    disable = {},  -- list of language that will be disabled
  },
}
require'nvim-treesitter.configs'.setup {
  context_commentstring = {
    enable = true
  }
}
EOF
" neoscroll
lua require('neoscroll').setup()
" color highlight
lua require'colorizer'.setup()
nnoremap <leader>dn :Bdelete! nameless<CR>
" diffview
nnoremap <leader>dh :DiffviewFileHistory<CR>
cnoreabbrev do DiffviewOpen
cnoreabbrev dfh DiffviewFileHistory
lua <<EOF
-- Lua
local cb = require'diffview.config'.diffview_callback

require'diffview'.setup {
  key_bindings = {
    file_panel = {
      ["j"]             = cb("select_next_entry"),           -- Bring the cursor to the next file entry
      ["<down>"]        = cb("select_next_entry"),
      ["k"]             = cb("select_prev_entry"),           -- Bring the cursor to the previous file entry.
      ["<up>"]          = cb("select_prev_entry"),
    },
  },
}
EOF

" nvim-tree
lua <<EOF
-- Lua
require'nvim-tree'.setup {
  update_to_buf_dir = {
    enable = false
  },
  view = {
    width = 50,
    side = 'right'
  },
}
EOF
nnoremap <leader>ef :NvimTreeFindFile<CR>
nnoremap <leader>ee :NvimTreeToggle<CR>
let g:nvim_tree_quit_on_open = 1
" gitsigns
lua require('gitsigns').setup();
" hop
lua <<EOF
-- Lua
require'hop'.setup();
vim.api.nvim_set_keymap('n', 'f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('n', 'F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('o', 'f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true, inclusive_jump = true })<cr>", {})
vim.api.nvim_set_keymap('o', 'F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true, inclusive_jump = true })<cr>", {})
vim.api.nvim_set_keymap('', 't', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", {})
vim.api.nvim_set_keymap('', 'T', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", {})
EOF
nnoremap s :HopChar1<cr>
nnoremap gl :HopLine<cr>

" lspconfig
lua <<EOF
local nvim_lsp = require 'lspconfig'
local on_attach = function(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>K', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>Q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)
  vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end
-- setup nvim-cmp
local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    -- Accept currently selected item. If none selected, `select` first item.
    -- Set `select` to `false` to only confirm explicitly selected items.
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Enable the following language servers
local servers = { 'tsserver' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities
  }
end
EOF
" }}}
