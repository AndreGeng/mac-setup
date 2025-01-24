-- setup nvim with python support
vim.g.python_host_prog = os.getenv("HOME") .. '/.pyenv/versions/neovim2/bin/python'
vim.g.python3_host_prog = os.getenv("HOME") .. '/.pyenv/versions/neovim3/bin/python'


-- disable matchparen plugin
vim.g.loaded_matchparen = 1

-- 关闭 marscode 内置自动补全
vim.g.marscode_disable_autocompletion = true
-- 关闭 marscode 内置 tab 映射
vim.g.marscode_no_map_tab = true
-- 关闭 marscode 内置补全映射
vim.g.marscode_disable_bindings = true
