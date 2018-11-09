" Basic configurations {{{
" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
" copy to system clipboard
set clipboard+=unnamedplus

" jump between unsaved buffers without the E37
set hidden

" set lazyredraw, makes nvim smooth in tmux
set lazyredraw

" show number column
set number
set relativenumber

" color scheme
set termguicolors
colorscheme evening 
autocmd BufEnter,SourcePre * highlight Search guibg=none guifg=#50FA7B gui=underline
autocmd FilterWritePre * if &diff | colorscheme apprentice | endif

" indent
set autoindent
" use whitespace insteadof tab
set expandtab
" set shiftround
set shiftround

" set tab width
set softtabstop=2
set shiftwidth=2
set tabstop=2

" search
set ignorecase
set smartcase

" fold method
set foldmethod=syntax
nnoremap <Space> za

" diff ignore whitespace
set diffopt+=iwhite

" check one time after 4s of inactivity in normal mode
set autoread
autocmd FocusGained,BufEnter,CursorHold * checktime

" setup nvim with python support
let g:python_host_prog = $HOME.'/.pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME.'/.pyenv/versions/neovim3/bin/python'

" complete setting
set complete+=i

" }}}

" FileType specific setting {{{
" map extension to filetype
autocmd BufEnter *.less.module :setlocal filetype=less
autocmd BufEnter *.wxml :setlocal filetype=html
autocmd BufEnter *.wxss :setlocal filetype=css

" vimscript file setting
augroup filetype_vim
  autocmd!
  autocmd FileType,SourcePre *.vim :setlocal foldmethod=marker
augroup END

" set include path for javascript files, enable <c-x><c-i>
autocmd FileType javascript,javascript.jsx call <SID>JavaScriptInclude()
function! s:JavaScriptInclude()
  let &l:include='\v%(require\(|from)\s*(["''])\zs[^\1]+\ze\1'
endfunction
" fold style
""""""""""""""""""""""""""""""
" => JavaScript section
"""""""""""""""""""""""""""""""
autocmd FileType javascript,javascript.jsx call JavaScriptFold()
autocmd FileType javascript setl fen
autocmd FileType javascript setl nocindent

autocmd FileType javascript imap <c-t> $log();<esc>hi
autocmd FileType javascript imap <c-a> alert();<esc>hi

autocmd FileType javascript inoremap <buffer> $r return 
autocmd FileType javascript inoremap <buffer> $f // --- PH<esc>FP2xi

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

" git shortcut
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>dt :windo diffthis<CR>
nnoremap <leader>dc :windo diffoff<CR>
nnoremap <leader>du :diffupdate<CR>
nnoremap <leader>dg :diffget<CR>
nnoremap <leader>du :diffput<CR>

" buffer explorer
nnoremap <leader>be :Buffers<CR>

" cmdline mapping
cnoremap <C-A> <Home>

" Move a line of text using ALT+[jk]
nmap <m-i> mz:m+<cr>`z
nmap <m-o> mz:m-2<cr>`z
vmap <m-i> :m'>+<cr>`<my`>mzgv`yo`z
vmap <m-o> :m'<-2<cr>`>my`<mzgv`yo`z

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove 
map <leader>t<leader> :tabnext 

"toggle quickfixlist/locationlist -- start
  function! GetBufferList()
    redir =>buflist
    silent! ls!
    redir END
    return buflist
  endfunction

  function! ToggleList(bufname, pfx)
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

" }}}

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'mg979/vim-visual-multi'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'christoomey/vim-tmux-navigator'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-commentary'
Plug 'w0rp/ale'
Plug 'terryma/vim-expand-region'
Plug 'itchyny/lightline.vim'
Plug 'flazz/vim-colorschemes'
Plug 'jiangmiao/auto-pairs'
Plug 'mattn/emmet-vim'
Plug 'Valloric/MatchTagAlways'
Plug 'Chiel92/vim-autoformat'
Plug 'henrik/vim-indexed-search'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'
Plug 'kana/vim-textobj-line'
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-lastpat'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-surround'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'wellle/targets.vim'
Plug 'moll/vim-node'
Plug 'tpope/vim-unimpaired'
Plug 'nelstrom/vim-visual-star-search'
Plug 'tpope/vim-abolish'
Plug 'troydm/zoomwintab.vim'
Plug 'tpope/vim-dispatch'
" fix: can't use vim command under chinese input source
Plug 'lyokha/vim-xkbswitch'
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
" snippet -- start
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'
" snippet --end
" gist -- start
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
" gist -- end
Plug 'sjl/gundo.vim'
" syntax -- start
Plug 'pangloss/vim-javascript'
Plug 'othree/html5.vim'
Plug 'mxw/vim-jsx'
" syntax -- end
call plug#end()
" }}}

" Plugin configurations {{{
" nerdtree mapping
let g:NERDTreeWinPos = "right"
map <leader>nn :NERDTreeToggle<cr>
map <leader>nf :NERDTreeFind<cr>
" enable ctrl+j/k to switch panel in nerdtree
let g:NERDTreeMapJumpNextSibling = '<Nop>'
let g:NERDTreeMapJumpPrevSibling = '<Nop>'
" fzf
nmap <leader>f :Files<CR>
" Ack
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
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'javascript.jsx': ['eslint'],
\}

"Set this setting in vimrc if you want to fix files automatically on save.
"This is off by default.
" let g:ale_fix_on_save = 1
nmap <leader>lf :ALEFix<CR>

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
    \ }
nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>

" xkbswitch
let g:XkbSwitchEnabled = 1

" bufexplorer
let g:bufExplorerShowRelativePath=1

" bookmarks, avoid conflicts with nerdtree
let g:bookmark_no_default_key_mappings = 1
function! BookmarkMapKeys()
    nmap mm :BookmarkToggle<CR>
    nmap mi :BookmarkAnnotate<CR>
    nmap mn :BookmarkNext<CR>
    nmap mp :BookmarkPrev<CR>
    nmap ma :BookmarkShowAll<CR>
    nmap mc :BookmarkClear<CR>
    nmap mx :BookmarkClearAll<CR>
    nmap mkk :BookmarkMoveUp
    nmap mjj :BookmarkMoveDown
endfunction
function! BookmarkUnmapKeys()
    unmap mm
    unmap mi
    unmap mn
    unmap mp
    unmap ma
    unmap mc
    unmap mx
    unmap mkk
    unmap mjj
endfunction
autocmd FocusGained,BufEnter * :call BookmarkMapKeys()
autocmd FocusGained,BufEnter NERD_tree_* :call BookmarkUnmapKeys()

" }}}

