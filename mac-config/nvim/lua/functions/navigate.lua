vim.cmd([[
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
]])
