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

" Plugins {{{
call plug#begin('~/.vim/plugged')
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'w0rp/ale'
Plug 'Chiel92/vim-autoformat'
Plug 'nelstrom/vim-visual-star-search'

Plug 'kevinhwang91/rnvimr'
" resize window
Plug 'simeji/winresizer'
" swap window
Plug 'wesQ3/vim-windowswap'
" lua functions utils
Plug 'sindrets/diffview.nvim'
call plug#end()
" }}}

" Plugin configurations {{{
" color scheme
colorscheme evening
autocmd BufEnter,SourcePre * highlight Search guibg=none guifg=#50FA7B gui=underline
" autocmd FilterWritePre * if &diff | colorscheme apprentice | endif

" fzf
nmap <leader>fo :Files<CR>
let $FZF_DEFAULT_COMMAND = 'fd -i --type f'
let g:fzf_preview_window = []
" search all files, including hidden files and vsc ignored files
nmap <leader>fa :call fzf#run(fzf#wrap({'source': 'fd -i --type f --hidden -I'}))<CR>

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

" Telescope
lua <<EOF
require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
    -- please take a look at the readme of the extension you want to configure
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')
EOF
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
" expand region shortcut
vmap v <Plug>(expand_region_expand)
vmap V <Plug>(expand_region_shrink)

" autoformat
let g:formatters_jsonc=['jsbeautify_json']
let g:formatters_javascript=['jsbeautify_javascript']

map <leader>af :Autoformat<CR>

" ALE
let g:ale_linters = {
      \  'javascript': ['eslint'],
      \  'javascript.jsx': ['eslint'],
      \  'typescript': ['eslint'],
      \  'typescriptreact': ['eslint'],
      \  'sh': ['language_server'],
      \}
let g:ale_fixers = {
      \   'javascript': ['eslint', 'prettier'],
      \   'javascript.jsx': ['eslint', 'prettier'],
      \   'typescript': ['eslint', 'prettier'],
      \   'typescriptreact': ['eslint', 'prettier'],
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
let g:ale_echo_cursor = 0
let g:ale_floating_preview = 1
let g:ale_cursor_detail = 1
nmap <leader>af :ALEFix<CR>

" emmet
imap <tab> <plug>(emmet-expand-abbr)
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

augroup terminal_settings
  autocmd!
  " Ignore various filetypes as those will close terminal automatically
  " Ignore fzf, ranger, coc
  autocmd TermClose term://*
        \ if (expand('<afile>') !~ "fzf") && (expand('<afile>') !~ "ranger") && (expand('<afile>') !~ "coc") |
        \   call nvim_input('<CR>')  |
        \ endif
augroup END

" ranger
nnoremap <silent> <leader>r :RnvimrToggle<CR>
tnoremap <silent> <leader>r <C-\><C-n>:RnvimrToggle<CR>
tnoremap <silent> <C-i> <C-\><C-n>:RnvimrResize<CR>
tnoremap <A-f> fzf_select
" Make Ranger replace Netrw and be the file explorer
" let g:rnvimr_enable_ex = 1

" Make Ranger to be hidden after picking a file
let g:rnvimr_enable_picker = 1

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

"}}}
