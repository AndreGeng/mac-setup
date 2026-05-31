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
  local mise = vim.fn.exepath("mise")
  if mise ~= "" then
    local go_root = vim.trim(vim.fn.system({ mise, "where", "go" }))
    if vim.v.shell_error == 0 and go_root ~= "" then
      local go_bin = go_root .. "/bin"
      if vim.fn.isdirectory(go_bin) == 1 then
        vim.env.PATH = go_bin .. ":" .. vim.env.PATH
      end
    end
  end

  -- disable matchparen plugin
  vim.g.loaded_matchparen = 1

  -- 关闭 marscode 内置自动补全
  vim.g.marscode_disable_autocompletion = true
  -- 关闭 marscode 内置 tab 映射
  vim.g.marscode_no_map_tab = true
  -- 关闭 marscode 内置补全映射
  vim.g.marscode_disable_bindings = true
end
