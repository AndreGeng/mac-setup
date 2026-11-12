local root = assert(vim.env.MAC_SETUP_TEST_ROOT)
vim.opt.rtp:prepend(root .. '/config/nvim')
package.preload.cmp_nvim_lsp = function()
  return { default_capabilities = function(c) return c end }
end
local configs, enabled = { rust_analyzer = { root_dir = function(_, callback)
  callback('/cargo-workspace')
end } }, {}
vim.lsp.config = setmetatable(configs, { __call = function(_, name, config)
  configs[name] = vim.tbl_deep_extend('force', configs[name] or {}, config)
end })
vim.lsp.enable = function(name) enabled[name] = true end
local spec = dofile(root .. '/config/nvim/lua/plugins/lsp.lua')
spec[1].init()
assert(enabled.rust_analyzer, 'Rust LSP must be enabled')
assert(configs.rust_analyzer.settings['rust-analyzer'].files.watcher == 'server',
  'Rust must use its server watcher to avoid Neovim EMFILE failures')
configs.rust_analyzer.on_attach({}, 0)
assert(vim.fn.maparg('gd', 'n'):find('vim.lsp.buf.definition', 1, true), 'gd must use LSP')
local project = false
vim.fs.root = function() return project and '/cargo-workspace' or nil end
local started
vim.lsp.start = function(config, opts) started = { config = config, opts = opts } end
vim.api.nvim_buf_set_name(0, '/tmp/rust-standalone-test.rs')
configs.rust_analyzer.root_dir(0, function() error('standalone must not start a directory workspace') end)
assert(started.config.root_dir == nil)
assert(started.config.settings['rust-analyzer'].detachedFiles[1] == vim.api.nvim_buf_get_name(0))
assert(started.config.settings['rust-analyzer'].checkOnSave == true)
assert(vim.deep_equal(started.config.settings['rust-analyzer'].check.overrideCommand, {
  'rustc', '--error-format=json', '--emit=metadata', '-o', '/dev/null', vim.api.nvim_buf_get_name(0),
}))
assert(started.config.settings['rust-analyzer'].check.invocationStrategy == 'once')
assert(started.opts.reuse_client({ name = 'rust_analyzer', config = started.config }))
assert(not started.opts.reuse_client({ name = 'rust_analyzer', config = {} }))
assert(configs.rust_analyzer.settings['rust-analyzer'].detachedFiles == nil,
  'standalone options must not leak into the shared configuration')
project = true
configs.rust_analyzer.root_dir(0, function(dir) assert(dir == '/cargo-workspace') end)
local conform = dofile(root .. '/config/nvim/lua/plugins/conform.lua')
assert(conform.opts.formatters_by_ft.rust[1] == 'rustfmt', 'Rust must use rustfmt')
package.preload['nvim-treesitter'] = function()
  return { install = function(parsers)
    assert(vim.list_contains(parsers, 'rust'), 'Rust Treesitter parser must be installed')
    return { wait = function() end }
  end }
end
dofile(root .. '/config/nvim/lua/plugins/treesitter.lua')[2].config()
-- The familiar ,ft shortcut must not send Rust source to Prettier's Babel parser.
local format_opts
package.loaded.conform = { format = function(opts) format_opts = opts end }
dofile(root .. '/config/nvim/lua/keymaps.lua')
vim.bo.filetype = 'rust'
vim.g.disable_autoformat = true
vim.fn.jobstart = function() error('Rust formatting must not launch Prettier') end
vim.fn.maparg(',ft', 'n', false, true).callback()
assert(format_opts and format_opts.async == false, ',ft must format Rust through Conform')
assert(vim.g.disable_autoformat == true, 'manual formatting must preserve save-format preference')
vim.g.disable_autoformat = nil
dofile(root .. '/config/nvim/lua/autocmd.lua')
vim.cmd('filetype plugin indent on')
vim.bo.filetype = ''
vim.bo.filetype = 'rust'
assert(vim.wo.foldmethod == 'indent', 'Rust must enable indentation folding')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  'fn main() {',
  '    let a = 1;',
  '    let b = 2;',
  '    println!("{}", a + b);',
  '}',
})
vim.cmd('normal! zx')
vim.cmd('normal! zR')
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd('normal! za')
assert(vim.fn.foldclosed(2) == 2, 'za must close a Rust block without E490')
vim.cmd('normal! za')
assert(vim.fn.foldclosed(2) == -1, 'za must reopen the Rust block')
print('PASS Rust LSP, gd, formatting shortcuts, and Treesitter configuration')
