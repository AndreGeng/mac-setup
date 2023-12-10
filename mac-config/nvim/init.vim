lua require("main")

" Basic configurations {{{
language zh_CN.UTF-8

" setup nvim with python support
let g:python_host_prog = $HOME.'/.pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME.'/.pyenv/versions/neovim3/bin/python'

" Disable vim E211: File no longer available @see
" https://stackoverflow.com/questions/52780939/disable-vim-e211-file-no-longer-available
autocmd FileChangedShell * execute

au CursorHold,CursorHoldI,FocusGained * :checktime

" folding
augroup folding
  au!
  au FileType git,javascript,javascript.jsx,typescript,typescriptreact,go setlocal foldmethod=indent
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
autocmd BufEnter *.ts :setlocal filetype=typescript
autocmd BufEnter *.json :setlocal filetype=jsonc

" }}}

" Custom mapping {{{

" auto resize window size when container window size changed
autocmd VimResized * wincmd =

"}}}

" Plugin configurations {{{
" color scheme
colorscheme evening
autocmd BufEnter,SourcePre * highlight Search guibg=none guifg=#50FA7B gui=underline
" autocmd FilterWritePre * if &diff | colorscheme apprentice | endif

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

augroup terminal_settings
  autocmd!
  " Ignore various filetypes as those will close terminal automatically
  " Ignore fzf, ranger, coc
  autocmd TermClose term://*
        \ if (expand('<afile>') !~ "fzf") && (expand('<afile>') !~ "ranger") && (expand('<afile>') !~ "coc") |
        \   call nvim_input('<CR>')  |
        \ endif
augroup END

"}}}
