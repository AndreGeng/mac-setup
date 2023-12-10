-- Disable vim E211: File no longer available @see https://stackoverflow.com/questions/52780939/disable-vim-e211-file-no-longer-available
vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
  pattern = { '*' },
  command = 'execute',
})

-- Check if any buffers were changed outside of Vim.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "FocusGained" }, {
  pattern = { '*' },
  command = 'checktime',
})

-- folding
vim.cmd([[
  augroup folding
    au!
    au FileType git,javascript,javascriptreact,typescript,typescriptreact,go setlocal foldmethod=indent
    au FileType zsh,vim setlocal foldmethod=marker
  augroup END
]])

-- auto resize window size when container window size changed
vim.api.nvim_create_autocmd({ "VimResized" }, {
  pattern = { '*' },
  command = 'wincmd =',
})

-- change search highlight color
vim.api.nvim_create_autocmd({ "BufEnter", "SourcePre" }, {
  pattern = { '*' },
  command = 'highlight Search guibg=none guifg=#50FA7B gui=underline',
})

-- map extension to filetype
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { '*.pcss', '*.wxss' },
  command = 'setlocal filetype=scss',
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { '*.wxml', '*.art', '*.ejs' },
  command = 'setlocal filetype=html',
})

-- 修复<ctrl-l>被netrw覆盖的问题
vim.cmd([[
  augroup netrw_mapping
    autocmd!
    autocmd filetype netrw call NetrwMapping()
  augroup END

  function! NetrwMapping()
    nnoremap <silent> <buffer> <c-l> :TmuxNavigateRight<CR>
  endfunction
  " 禁止netrw保存history or bookmarks
  let g:netrw_dirhistmax = 0
]])

-- disable syntax highlight for large file
vim.cmd([[
  autocmd BufWinEnter * if line2byte(line("$") + 1) > 1000000 | syntax clear | endif
]])
