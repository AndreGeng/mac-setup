execute 'source ' . fnameescape($REX_NAVIGATION_SCRIPT)
for [key, direction] in items({'h': 'left', 'j': 'down', 'k': 'up', 'l': 'right'})
  only
  let before = len(readfile($REX_NAVIGATION_TEST_LOG))
  call RexNavigate(key)
  let actual = readfile($REX_NAVIGATION_TEST_LOG)[before:]
  call assert_equal(['-S', $REX_SERVER, 'focus', '-s', $REX_SESSION, direction], actual)
endfor

only
vsplit
wincmd h
let left = win_getid()
wincmd l
let right = win_getid()
let before = len(readfile($REX_NAVIGATION_TEST_LOG))
call RexNavigate('h')
call assert_equal(left, win_getid())
call RexNavigate('l')
call assert_equal(right, win_getid())
call assert_equal(before, len(readfile($REX_NAVIGATION_TEST_LOG)))

only
split
wincmd k
let top = win_getid()
wincmd j
let bottom = win_getid()
call RexNavigate('k')
call assert_equal(top, win_getid())
call RexNavigate('j')
call assert_equal(bottom, win_getid())
call assert_equal(before, len(readfile($REX_NAVIGATION_TEST_LOG)))
for key in ['h', 'j', 'k', 'l']
  call assert_match('RexNavigate', maparg('<C-' . key . '>', 'n'))
endfor

" Reject unsupported directions without executing a command.
call RexNavigate('x')
call assert_equal(before, len(readfile($REX_NAVIGATION_TEST_LOG)))

" Sourcing the integration outside Rex must not change existing mappings.
let $REX_SESSION = ''
for key in ['h', 'j', 'k', 'l']
  execute 'nnoremap <C-' . key . '> :echo "original"<CR>'
endfor
execute 'source ' . fnameescape($REX_NAVIGATION_SCRIPT)
for key in ['h', 'j', 'k', 'l']
  call assert_match('original', maparg('<C-' . key . '>', 'n'))
endfor

if !empty(v:errors)
  call writefile(v:errors, $REX_NAVIGATION_TEST_ERRORS)
  cquit
endif
qa!
