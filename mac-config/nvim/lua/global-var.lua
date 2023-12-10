-- setup nvim with python support
vim.g.python_host_prog = os.getenv("HOME") .. '/.pyenv/versions/neovim2/bin/python'
vim.g.python3_host_prog = os.getenv("HOME") .. '/.pyenv/versions/neovim3/bin/python'


-- disable matchparen plugin
vim.g.loaded_matchparen = 1
