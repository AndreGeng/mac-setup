-- Run with: nvim --headless -u NONE -i NONE -l test/hammerspoon-reload-test.lua
local root = vim.fn.fnamemodify(arg[0], ':p:h:h')
package.path = root .. '/config/.hammerspoon/?.lua;' .. package.path

local watchedPath, changed, reloads = nil, nil, 0
local watcher = { start = function(self) return self end }
hs = {
  configdir = '/home/test/.hammerspoon',
  fs = { pathToAbsolute = function(path)
    assert(path == '/home/test/.hammerspoon')
    return '/repo/config/.hammerspoon'
  end },
  pathwatcher = { new = function(path, callback)
    watchedPath, changed = path, callback
    return watcher
  end },
  alert = { show = function() end },
  reload = function() reloads = reloads + 1 end,
}

assert(require('auto-reload-config') == watcher, 'retain the config watcher in package.loaded')
assert(watchedPath == '/repo/config/.hammerspoon', 'watch the symlink target for repository edits')
changed({ '/repo/config/.hammerspoon/README.md' })
assert(reloads == 0, 'ignore non-Lua changes')
changed({ '/repo/config/.hammerspoon/init.lua', '/repo/config/.hammerspoon/keymap.lua' })
assert(reloads == 1, 'reload once per Lua change batch')
print('PASS retained Hammerspoon watcher and symlink target routing')
