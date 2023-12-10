-- vim.api.nvim_create_user_command('LAZYGIT',  'FloatermNew --height=0.99 --name=lazygit lazygit', {})

-- vim.keymap.set('n', '<C-a>', ':LAZYGIT<cr>', { noremap = true })

-- @see https://github.com/voldikss/vim-floaterm/issues/243
vim.cmd([[
  function! GetBufnrUnnamed() abort
    let buflist = floaterm#buflist#gather()
    for bufnr in buflist
      let name = getbufvar(bufnr, 'floaterm_name')
      if empty(name)
        return bufnr
      endif
    endfor
    return -1
  endfunction

  function! ToggleTool(tool, count) abort
    " find bufnr according to the tool name
    let bufnr = empty(a:tool) ?
      \ GetBufnrUnnamed() : floaterm#terminal#get_bufnr(a:tool)

    if bufnr == -1
      if empty(a:tool)
        " ToggleTool should only be called from
        " normal mode or terminal mode without bang
        call floaterm#run('new', 0, [visualmode(), 0, 0, 0], '')
      else
        call floaterm#run('new', 0, [visualmode(), 0, 0, 0],
          \ printf('--title=%s($1/$2) --name=%s %s', a:tool, a:tool, a:tool))
      endif
    else
      call floaterm#toggle(0, a:count ? a:count : bufnr, '')
      " workaround to prevent lazygit shift left;
      " another workaround here is to use sidlent!
      " to ignore can't re-enter normal mode error
      execute('silent! normal! 0')
    endif
  endfunction

  command! -nargs=? -count=0 ToggleTool call ToggleTool(<q-args>, <count>)
  nnoremap <silent> <C-a> <Cmd>execute v:count . 'ToggleTool lazygit'<CR>
  tnoremap <silent> <C-a> <Cmd>execute v:count . 'ToggleTool lazygit'<CR>
  ]])
