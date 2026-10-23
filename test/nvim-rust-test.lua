local root = assert(vim.env.MAC_SETUP_TEST_ROOT)
package.preload.cmp_nvim_lsp = function()
  return { default_capabilities = function(c) return c end }
end
local configs, enabled = {}, {}
vim.lsp.config = function(name, config) configs[name] = config end
vim.lsp.enable = function(name) enabled[name] = true end
local spec = dofile(root .. '/config/nvim/lua/plugins/lsp.lua')
spec[1].init()
assert(enabled.rust_analyzer, 'Rust LSP must be enabled')
assert(configs.rust_analyzer.settings['rust-analyzer'].files.watcher == 'server',
  'Rust must use its server watcher to avoid Neovim EMFILE failures')
configs.rust_analyzer.on_attach({}, 0)
assert(vim.fn.maparg('gd', 'n'):find('vim.lsp.buf.definition', 1, true), 'gd must use LSP')
local conform = dofile(root .. '/config/nvim/lua/plugins/conform.lua')
assert(conform.opts.formatters_by_ft.rust[1] == 'rustfmt', 'Rust must use rustfmt')
package.preload['nvim-treesitter'] = function()
  return { install = function(parsers)
    assert(vim.list_contains(parsers, 'rust'), 'Rust Treesitter parser must be installed')
    return { wait = function() end }
  end }
end
dofile(root .. '/config/nvim/lua/plugins/treesitter.lua')[2].config()
print('PASS Rust LSP, gd, formatting, and Treesitter configuration')
