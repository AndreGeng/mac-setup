-- Python3 仅在有 venv 时启用（setup_python_env）；否则关闭 provider，避免指向不存在的路径
if vim then
  vim.g.loaded_python_provider = 0
  local py3 = vim.env.HOME .. "/.local/share/neovim/neovim3/bin/python"
  if vim.fn.executable(py3) == 1 then
    vim.g.python3_host_prog = py3
  else
    vim.g.loaded_python3_provider = 0
  end
  if vim.fn.isdirectory(vim.env.HOME .. "/.local/share/mise/shims") == 1 then
    vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
  end
  -- mac-setup 把 tree-sitter、Go、gopls 等受管工具发布到这里。即使 Neovim
  -- 从尚未重新加载 .zshrc 的旧终端启动，也应优先使用仓库声明的版本。
  vim.env.PATH = vim.env.HOME .. "/.local/bin:" .. vim.env.PATH

  -- disable matchparen plugin
  vim.g.loaded_matchparen = 1

  -- 关闭 marscode 内置自动补全
  vim.g.marscode_disable_autocompletion = true
  -- 关闭 marscode 内置 tab 映射
  vim.g.marscode_no_map_tab = true
  -- 关闭 marscode 内置补全映射
  vim.g.marscode_disable_bindings = true
end
