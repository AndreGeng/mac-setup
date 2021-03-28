" Basic configurations {{{
" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
" copy to system clipboard
set clipboard+=unnamedplus
language zh_CN.UTF-8

" jump between unsaved buffers without the E37
set hidden
" coc setting -- start
set nobackup
set nowritebackup
" Give more space for displaying messages.
set cmdheight=2
" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif
" coc setting -- end

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

" Disable vim E211: File no longer available @see
" https://stackoverflow.com/questions/52780939/disable-vim-e211-file-no-longer-available
autocmd FileChangedShell * execute

" autoread
set autoread
au FocusGained * :checktime

" default updatetime 4000ms is not good for async update
set updatetime=100

" folding
augroup folding
  au!
  au FileType git,javascript,javascript.jsx,typescript,typescript.tsx setlocal foldmethod=syntax
  au FileType zsh,vim setlocal foldmethod=marker
augroup END

" }}}

" FileType specific setting {{{
" map extension to filetype
autocmd BufEnter *.less.module :setlocal filetype=less
autocmd BufEnter *.pcss :setlocal filetype=scss
autocmd BufEnter *.wxml :setlocal filetype=html
autocmd BufEnter *.ejs :setlocal filetype=html
autocmd BufEnter *.wxss :setlocal filetype=css
autocmd BufEnter *.md,*.mdx :setlocal filetype=markdown
autocmd BufEnter *.js,*.jsx :setlocal filetype=javascript.jsx
autocmd BufEnter *.ts,*.tsx :setlocal filetype=typescript.tsx
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
nmap <leader>et :w !ts-node<cr>

" git shortcut
nnoremap <leader>gs :G<CR>:on<CR>
nnoremap <leader>gb :Gblame<CR>

" buffer explorer
nnoremap <leader>be :Buffers<CR>

" cmdline mapping
cnoremap <C-A> <Home>

" Move a line of text using ALT+[io], @see https://vim.fandom.com/wiki/Moving_lines_up_or_down
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
  if winnr() != winnr
    wincmd p
  endif
endfunction

nmap <silent> <leader>n :call ToggleList("Location", 'l')<CR>
nmap <silent> <leader>k :call ToggleList("Quickfix", 'c')<CR>
"toggle quickfixlist/locationlist -- end

" auto resize window size when container window size changed
autocmd VimResized * wincmd =

" <C-u>: go back to previous buffer
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

nnoremap <silent> <C-U> :call GoBackToRecentBuffer()<Enter>
"}}}

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'yuttie/comfortable-motion.vim'
Plug 'tpope/vim-repeat'
Plug 'gcmt/wildfire.vim'
" language packs for vim
Plug 'justinmk/vim-dirvish'
Plug 'sheerun/vim-polyglot'
Plug 'leafOfTree/vim-vue-plugin'
Plug 'bash-lsp/bash-language-server'
Plug 'jreybert/vimagit'
" markdown preview
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
" allow comments in json
Plug 'neoclide/jsonc.vim'
" preview color
Plug 'gko/vim-coloresque'
" open built-in terminal in floating window
Plug 'voldikss/vim-floaterm'
" multi cursor support, use <tab> to switch mode
Plug 'mg979/vim-visual-multi'
" show a diff using sign column
Plug 'mhinz/vim-signify'
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

" always download fail, install manually @see https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#add-cocnvim-to-your-vims-runtimepath
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'honza/vim-snippets'

" familiar
Plug 'christoomey/vim-tmux-navigator'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
" comment stuff out
Plug 'tomtom/tcomment_vim'
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
Plug 'maxmellon/vim-jsx-pretty'
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

map <leader>af :Autoformat<CR>
" gv.vim
nnoremap <leader>gv :GV!<CR>
vnoremap <leader>gv :GV!<CR>

" ALE
let g:ale_linters = {
      \  'javascript': ['eslint'],
      \  'javascript.jsx': ['eslint'],
      \  'sh': ['language_server'],
      \}
let g:ale_fixers = {
      \   'javascript': ['prettier'],
      \   'json': ['prettier'],
      \   'jsonc': ['prettier'],
      \   'javascript.jsx': ['prettier'],
      \   'typescript': ['prettier'],
      \   'css': ['prettier'],
      \   'scss': ['prettier'],
      \   'less': ['prettier'],
      \   'sass': ['prettier'],
      \   'sh': ['shfmt'],
      \}

" @see https://prettier.io/docs/en/vim.html
let g:ale_linters_explicit = 1
" let g:ale_fix_on_save = 1


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

" vim-commentary jsx comment
autocmd FileType javascript.jsx,typescript.jsx setlocal commentstring={/*\ %s\ */}
" coc.nvim
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)
" coc-explorer
let g:coc_explorer_global_presets = {
      \   'right': {
      \     'position': 'right',
      \   },
      \ }
nmap <leader>ee :CocCommand explorer<CR>
nmap <leader>ef :CocCommand explorer --no-toggle --preset right<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
imap <C-l> <Plug>(coc-snippets-expand)

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

" coc.vim
let g:coc_global_extensions = [
      \'coc-json',
      \'coc-tsserver',
      \'coc-explorer',
      \'coc-git',
      \'coc-sh',
      \'coc-snippets',
      \'coc-css'
      \]
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

" }}}
