# Rex terminal configuration

`init.lua` contains the migrated terminal shortcuts. `vim-navigation.vim` connects
Vim/Neovim split navigation to Rex pane navigation.

## Installation

Publish the contents of this directory to `~/.config/rex/`. The Neovim loader is
included in `config/nvim/after/plugin/` and is available when the repository's
Neovim configuration is installed. For standalone Vim, publish
`config/vim/after/plugin/rex-navigation.vim` to `~/.vim/after/plugin/` as well.
The loaders resolve the shared script from this checkout, then fall back to the
installed Rex configuration. They do nothing when the shared script is absent.

Reload Config in Rex after installing `init.lua`. Restart Vim/Neovim or run
`:source ~/.config/rex/vim-navigation.vim` in an already-running editor.

## Shortcuts

A `→` means release the prefix before pressing the next key.

| Keys | Action |
| --- | --- |
| Ctrl+Space → Shift+N | New tab |
| Alt+h / Alt+l | Previous / next tab |
| Ctrl+Space → v / s | Split right / down |
| Ctrl+Space → k | Close pane |
| Ctrl+Space → Shift+K | Close tab |
| Ctrl+Space → i | Zoom pane |
| Ctrl+h/j/k/l | Focus left/down/up/right |
| Ctrl+Space → Ctrl+Space | Send Ctrl+Space to the terminal |
| Ctrl+Space → Ctrl+r | Enter repeat resize mode |
| Shift+h/j/k/l inside repeat mode | Resize left/down/up/right |
| Enter or Escape inside repeat mode | Leave repeat mode |
| Cmd+k | Rex session picker |

When Vim, Neovim, or vimdiff is in the foreground, Rex sends Ctrl+h/j/k/l to
that editor. In normal mode the shared Vim script first tries `wincmd`; if the
window did not change, it calls `rex focus` in the corresponding direction using
that terminal's `REX_SERVER` and `REX_SESSION`. Neither layer wraps at an edge.
In other programs Rex switches panes directly. If Rex cannot identify the
foreground program, it preserves terminal input.

Vim integration activates only inside Rex and overrides these four normal-mode
mappings. It does not add insert-mode or terminal-mode mappings. The `rex` CLI
must be available through `REX_BIN_DIR` or PATH. Other Rex defaults remain
available, including Cmd+T for a new tab and Option+Cmd+arrows for pane focus.

## Verification

Run `bash test/rex-navigation-test.sh` from the repository root. The regression
check uses Vim/Neovim with no user configuration and a fake Rex executable; it
checks internal movement in all four directions, calls at all four edges, and
correct server/session arguments without contacting a real Rex server.

Validate the installed Lua configuration with `rex config check`, reload it, and
check that `rex keymap --json` has an empty diagnostics list.
