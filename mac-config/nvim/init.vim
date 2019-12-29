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

" fold method
set foldmethod=syntax
nnoremap <Space> za

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

" terminal
tnoremap <C-f> <C-\><C-n>
" }}}

" FileType specific setting {{{
" map extension to filetype
autocmd BufEnter *.less.module :setlocal filetype=less
autocmd BufEnter *.pcss :setlocal filetype=scss
autocmd BufEnter *.wxml :setlocal filetype=html
autocmd BufEnter *.wxss :setlocal filetype=css

" fold style
""""""""""""""""""""""""""""""
" => JavaScript section
"""""""""""""""""""""""""""""""
autocmd FileType javascript,javascript.jsx call JavaScriptFold()

function! JavaScriptFold() 
    setl foldmethod=syntax
    setl foldlevelstart=1
    syn region foldBraces start=/{/ end=/}/ transparent fold keepend extend

    function! FoldText()
        return substitute(getline(v:foldstart), '{.*', '{...}', '')
    endfunction
    setl foldtext=FoldText()
endfunction

" }}}

" Custom mapping {{{
" Fast saving
nmap <leader>w :w!<cr>
" Quick open vimrc
nnoremap <leader>ev :rightbelow vsplit $MYVIMRC<cr>
" smart way to close pane
nnoremap <leader>q :q<CR>
" toggle GundoToggle
nnoremap <leader>u :GundoToggle<CR>

" git shortcut
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gb :Gblame<CR>
nnoremap <leader>gm :GitMessenger<CR>
" show git log patches
nnoremap <leader>sp :call ShowPatch()<cr>
" view changes of current file made by me
" helpful when resolving mege conflicts
nnoremap <leader>cm :call ShowChangesByMe()<cr>
function! ShowChangesByMe()
  let username = system('git config user.name')
  let name = substitute(username, '\%x00', '', 'g')
  execute 'on|vs|Git!log master.. --author="'.name.'" -- %'
  execute 'wincmd l|vs|Git!log master.. --author="'.name.'" -p -- %'
  execute 'wincmd l'
endfunction
function! ShowPatch()
  execute '0Glog --no-merges --'
endfunction
" fold git log patches in order to highlight filenames
autocmd FileType git call FoldAll()
function! FoldAll()
  :setlocal foldlevelstart=0
  execute "normal zM"
endfunction

" buffer explorer
nnoremap <leader>be :Buffers<CR>

" cmdline mapping
cnoremap <C-A> <Home>

" Move a line of text using ALT+[io], @see https://vim.fandom.com/wiki/Moving_lines_up_or_down
nnoremap <A-i> :m .+1<CR>==
nnoremap <A-o> :m .-2<CR>==
inoremap <A-i> <Esc>:m .+1<CR>==gi
inoremap <A-o> <Esc>:m .-2<CR>==gi
vnoremap <A-i> :m '>+1<CR>gv=gv
vnoremap <A-o> :m '<-2<CR>gv=gv

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tl :tabnext<cr>
map <leader>th :tabp<cr> 

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

" nmap <silent> <leader>l :call ToggleList("Location", 'l')<CR>
" nmap <silent> <leader>q :call ToggleList("Quickfix", 'c')<CR>
nmap <silent> <leader>l :call ToggleList("Location", 'l')<CR>
nmap <silent> <leader>k :call ToggleList("Quickfix", 'c')<CR>
"toggle quickfixlist/locationlist -- end

" always open quickfix window at bottom
augroup DragQuickfixWindowDown
  autocmd!
  autocmd FileType qf wincmd J
augroup end

" auto resize window size when container window size changed
autocmd VimResized * wincmd =

" set filetype to javascript if it's empty
autocmd BufEnter * if &filetype == "" | setlocal ft=javascript | endif
"}}}

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'ap/vim-css-color'
Plug 'kassio/neoterm'
Plug 'voldikss/vim-floaterm'
Plug 'rhysd/git-messenger.vim'
Plug 'sjl/gundo.vim'
Plug 'mg979/vim-visual-multi'
Plug 'godlygeek/tabular'
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
Plug 'wellle/targets.vim'
Plug 'moll/vim-node'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-abolish'
Plug 'troydm/zoomwintab.vim'
Plug 'tpope/vim-dispatch'
Plug 'iamcco/mathjax-support-for-mkdp'
Plug 'yssl/QFEnter'

" completion framework ncm2 -- start
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'
Plug 'ncm2/ncm2-snipmate'
Plug 'tomarrell/vim-npr'
" ncm2 complete source -- start
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
Plug 'wellle/tmux-complete.vim'
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }
" ncm2 complete source --end
" completion framework ncm2 -- end
" snippet -- start
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'
" snippet --end

" familiar
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'christoomey/vim-tmux-navigator'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-commentary'
Plug 'suy/vim-context-commentstring'
Plug 'w0rp/ale'
Plug 'itchyny/lightline.vim'
Plug 'flazz/vim-colorschemes'
Plug 'jiangmiao/auto-pairs'
Plug 'mattn/emmet-vim'
Plug 'andymass/vim-matchup'
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
Plug 'iamcco/markdown-preview.vim'
Plug 'wesQ3/vim-windowswap'
" fix: can't use vim command under chinese input source
Plug 'lyokha/vim-xkbswitch'
" gist -- start
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
" gist -- end
" syntax -- start
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'othree/html5.vim'
Plug 'mxw/vim-jsx'
Plug 'ekalinin/Dockerfile.vim'
Plug 'stephpy/vim-yaml'
Plug 'tpope/vim-dotenv'
" syntax -- end
" seldom used -- start
" Plug 'terryma/vim-expand-region'
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
let g:VM_maps["Select l"]           = '<m-l>'       " start selecting left
let g:VM_maps["Select h"]           = '<m-h>'        " start selecting right
let g:VM_maps["Select Cursor Down"] = '<m-j>'      " start selecting down
let g:VM_maps["Select Cursor Up"]   = '<m-k>'        " start selecting up
" nerdtree mapping
let g:NERDTreeWinPos = "right"
map <leader>nn :NERDTreeToggle<cr>
map <leader>nf :NERDTreeFind<cr>
" enable ctrl+j/k to switch panel in nerdtree
let g:NERDTreeMapJumpNextSibling = '<Nop>'
let g:NERDTreeMapJumpPrevSibling = '<Nop>'
let NERDTreeAutoDeleteBuffer=1
" fzf
nmap <leader>f :Files<CR>
function! ToggleVCSIgnore()
  if $FZF_DEFAULT_COMMAND !~# 'no-ignore-vcs'
    let $FZF_DEFAULT_COMMAND = 'fd --type f --no-ignore-vcs'
    echom 'all'
  else
    let $FZF_DEFAULT_COMMAND = 'fd --type f'
    echom 'ignore'
  endif
endfunction
nnoremap <leader>ts :call ToggleVCSIgnore()<cr>
" Ack
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
nmap <leader>a :Ack -i 

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
map <leader>af :Autoformat<CR>
" gv.vim
nnoremap <leader>gv :GV!<CR>
vnoremap <leader>gv :GV!<CR>

" ALE
let g:ale_linters = {
\  'javascript': ['eslint'],
\  'javascript.jsx': ['eslint'],
\}
let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'json': ['prettier'],
\   'javascript.jsx': ['prettier'],
\   'typescript': ['prettier'],
\   'css': ['prettier'],
\   'scss': ['prettier'],
\   'less': ['prettier'],
\   'sass': ['prettier'],
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

" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()

" IMPORTANTE: :help Ncm2PopupOpen for more information
set completeopt=noinsert,menuone,noselect

" LSP
let g:LanguageClient_serverCommands = {
    \ 'javascript': [expand('`npm get prefix`/bin/javascript-typescript-stdio')],
    \ 'javascript.jsx': [expand('`npm get prefix`/bin/javascript-typescript-stdio')],
    \ 'typescript': [expand('`npm get prefix`/bin/javascript-typescript-stdio')],
    \ }
nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> E :call LanguageClient#explainErrorAtPoint()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
let g:LanguageClient_diagnosticsList = 'Disabled'
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
" snip
" Press enter key to trigger snippet expansion
" The parameters are the same as `:help feedkeys()`
inoremap <silent> <expr> <C-e> ncm2_snipmate#expand_or("\<C-e>", 'n')
" floaterm
nnoremap <C-f> :FloatermToggle<CR>

" neoterm
let g:neoterm_default_mod = 'botright'
nmap <c-c><c-c> :Topen<cr>:TREPLSendFile<cr>
nmap <c-c><c-v> :TtoggleAll<cr>
nmap <c-c><c-x> :Tclear<cr>

" }}}
