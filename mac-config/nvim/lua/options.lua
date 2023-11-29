local options = {
  -- 允许vim访问系统剪贴版
  clipboard = 'unnamedplus',
  -- set lazyredraw, makes nvim smooth in tmux
  lazyredraw = true,
  -- show number column, 查看帮忙文档的话要用『:help 'number'』，注意『'』是必须的, 它表明要查找『选项』的帮助文档. 可以通过『:help help-summary』查看使用说明
  number = true,
  -- Show the line number relative to the line with the cursor in front of each line
  relativenumber = true,
  -- use whitespace insteadof tab
  expandtab = true,
  -- 使用>/<缩进时，控制缩进的步长(由shiftwidth指定)
  shiftround = true,
  shiftwidth = 2,
  -- tab width
  softtabstop = 2,
  -- 插入模式下，输入tab相当于2个
  tabstop = 2,
  -- 搜索忽略大小写
  ignorecase = true,
  -- 搜索使用智能大小写
  smartcase = true
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

