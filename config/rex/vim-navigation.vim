" Keep Ctrl+h/j/k/l navigation continuous across Vim splits and Rex panes.
" This file is sourced from Vim/Neovim's after/plugin directory.
if empty($REX_SESSION) || empty($REX_SERVER)
  finish
endif

function! RexNavigate(direction) abort
  let l:directions = {'h': 'left', 'j': 'down', 'k': 'up', 'l': 'right'}
  if !has_key(l:directions, a:direction)
    return
  endif

  let l:previous = win_getid()
  execute 'wincmd ' . a:direction
  if win_getid() != l:previous
    return
  endif

  " Vim stayed in the same window: continue into the adjacent Rex pane.
  let l:rex = empty($REX_BIN_DIR) ? exepath('rex') : $REX_BIN_DIR . '/rex'
  if !executable(l:rex)
    echohl WarningMsg
    echom 'Rex navigation: rex executable not found'
    echohl None
    return
  endif
  let l:argv = [l:rex, '-S', $REX_SERVER, 'focus', '-s', $REX_SESSION,
        \ l:directions[a:direction]]
  let l:output = system(join(map(l:argv, 'shellescape(v:val)'), ' '))
  if v:shell_error
    echohl WarningMsg
    echom 'Rex navigation: ' . substitute(l:output, '\n\+$', '', '')
    echohl None
  endif
endfunction

nnoremap <silent> <C-h> :<C-U>call RexNavigate('h')<CR>
nnoremap <silent> <C-j> :<C-U>call RexNavigate('j')<CR>
nnoremap <silent> <C-k> :<C-U>call RexNavigate('k')<CR>
nnoremap <silent> <C-l> :<C-U>call RexNavigate('l')<CR>
