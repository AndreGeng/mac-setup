require("global-var")
require("options")
require("keymaps")
require("functions.quickfix")
require("functions.navigate")
require("autocmd")

-- 设置文件描述符限制以防止EMFILE错误 - 版本兼容
local function set_file_descriptor_limit()
  local target_cur = 8192
  local target_max = 65536
  
  -- 方法1: 使用vim.uv (Neovim v0.10+)
  if vim.uv and vim.uv.setrlimit then
    local success, err = pcall(function()
      return vim.uv.setrlimit('RLIMIT_NOFILE', { cur = target_cur, max = target_max })
    end)
    
    if success then
      vim.notify("File descriptor limit set via vim.uv: " .. target_cur, vim.log.levels.INFO)
      return true
    else
      vim.notify("Failed to set limit via vim.uv: " .. tostring(err), vim.log.levels.WARN)
    end
  end
  
  -- 方法2: Shell命令fallback
  local shell_cmd = string.format("ulimit -n %d", target_cur)
  local result = vim.fn.system(shell_cmd)
  
  if vim.v.shell_error == 0 then
    vim.notify("File descriptor limit set via shell: " .. target_cur, vim.log.levels.INFO)
    return true
  else
    vim.notify("Failed to set file descriptor limit", vim.log.levels.ERROR)
    return false
  end
end

-- 尝试设置文件描述符限制
set_file_descriptor_limit()

require("config.lazy")
