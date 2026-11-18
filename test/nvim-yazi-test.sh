#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
export TEST_ROOT="$ROOT_DIR" TEST_TMP="$TEMP_ROOT"
mkdir -p "$TEMP_ROOT/home" "$TEMP_ROOT/data" "$TEMP_ROOT/state"

cat >"$TEMP_ROOT/test.vim" <<'EOF'
execute 'set runtimepath^=' . fnameescape($TEST_ROOT . '/config/nvim')
let s:dir = $TEST_TMP . '/space 中文'
call mkdir(s:dir, 'p')
let s:paths = [s:dir . '/first.rs', s:dir . '/percent%20 # quote'' |name.rs']
for s:path in s:paths
  call writefile(['fn workbench_command() {}'], s:path)
endfor
execute 'edit ' . fnameescape(s:paths[0])

function! TestChoice(choices, expected) abort
  let opts = {}
  let cwd = getcwd()
  let [shell, argv] = floaterm#wrapper#mac_setup_yazi#('mac_setup_yazi', opts, {})
  call assert_equal(v:false, shell)
  call assert_equal(['yazi', '--chooser-file'], argv[:1])
  call assert_equal(fnamemodify(expand('%:p'), ':h'), argv[3])
  call assert_equal(cwd, getcwd())
  call writefile(a:choices, argv[2])
  call opts.on_exit(0, 0, 'exit', 'edit')
  call assert_equal(a:expected, expand('%:p'))
  call assert_equal(0, filereadable(argv[2]))
  call assert_equal(['fn workbench_command() {}'], getline(1, '$'))
endfunction

call TestChoice(['search://workbench_command:3:3/' . s:paths[0]], s:paths[0])
call TestChoice(['search://workbench_command:5:5' . s:paths[1]], s:paths[1])
call TestChoice([s:paths[0], 'search://a%2Fb%3Ac::1/' . s:paths[1]], s:paths[1])
call TestChoice([], s:paths[1])

" Each chooser owns its callback; opening a second one must not steal the first result.
let s:a = {}
let s:b = {}
let [s:unused, s:argv_a] = floaterm#wrapper#mac_setup_yazi#('', s:a, {})
let [s:unused, s:argv_b] = floaterm#wrapper#mac_setup_yazi#('', s:b, {})
call writefile([s:paths[0]], s:argv_a[2])
call writefile([s:paths[1]], s:argv_b[2])
call s:a.on_exit(0, 0, 'exit', 'edit')
call assert_equal(s:paths[0], expand('%:p'))
call s:b.on_exit(0, 0, 'exit', 'edit')
call assert_equal(s:paths[1], expand('%:p'))

" Failed/cancelled jobs and unsupported virtual files must not open bogus buffers.
for s:status in [0, 1]
  let s:opts = {}
  let [s:unused, s:argv] = floaterm#wrapper#mac_setup_yazi#('', s:opts, {})
  call writefile(['sftp://host/path.rs'], s:argv[2])
  call s:opts.on_exit(0, s:status, 'exit', 'edit')
  call assert_equal(s:paths[1], expand('%:p'))
  call assert_equal(0, filereadable(s:argv[2]))
endfor
call assert_equal('', v:errmsg)

if !empty(v:errors)
  call writefile(v:errors, $TEST_TMP . '/errors')
  cquit 1
endif
qa!
EOF

if ! HOME="$TEMP_ROOT/home" XDG_DATA_HOME="$TEMP_ROOT/data" \
  XDG_STATE_HOME="$TEMP_ROOT/state" nvim --headless -u NONE -i NONE \
  -S "$TEMP_ROOT/test.vim" >"$TEMP_ROOT/output" 2>&1; then
  cat "$TEMP_ROOT/output"
  [[ ! -f "$TEMP_ROOT/errors" ]] || cat "$TEMP_ROOT/errors"
  exit 1
fi
printf 'PASS Neovim Yazi chooser opens real paths and preserves special filenames\n'
