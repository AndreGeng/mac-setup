" Repository-owned adapter for Yazi's --chooser-file output.
" Yazi 26.1.22 serializes search results as search://domain:ports//absolute/path.
" Keep the upstream vim-floaterm installation untouched.
function! floaterm#wrapper#mac_setup_yazi#(cmd, jobopts, config) abort
  let choice = tempname()
  let directory = expand('%:p:h')
  if !isdirectory(directory)
    let directory = getcwd()
  endif
  let a:jobopts.on_exit = function('s:open_choice', [choice])
  return [v:false, ['yazi', '--chooser-file', choice, directory]]
endfunction

function! s:open_choice(choice, job, status, event, opener) abort
  if !filereadable(a:choice)
    return
  endif
  try
    let filenames = readfile(a:choice)
  finally
    call delete(a:choice)
  endtry
  if a:status != 0
    return
  endif

  let paths = []
  for filename in filenames
    " The domain/ports describe the search view, not a line or column number.
    " Accept both single- and double-slash absolute paths. Do not URL-decode:
    " search:// paths preserve literal percent sequences such as %20.
    let path = substitute(filename, '^search://[^/]*/\+', '/', '')
    if path =~# '^\a[[:alnum:]+.~_-]*://'
      echohl WarningMsg
      echomsg 'Yazi: unsupported chooser URL; open this entry from its local directory'
      echohl None
      return
    endif
    call add(paths, fnamemodify(path, ':p'))
  endfor
  let opener = a:opener
  for path in paths
    execute opener fnameescape(path)
    let opener = 'edit'
  endfor
endfunction
