local options = {
  -- 允许vim访问系统剪贴版
  clipboard = 'unnamedplus',
  -- set lazyredraw, makes nvim smooth in tmux
  lazyredraw = true,
  -- show number column, 查看帮忙文档的话要用『:help 'number'』，注意『'』是必须的, 它表明要查找『选项』的帮助文档. 可以通过『:help help-summary』查看使用说明
  number = true,
  -- Show the line number relative to the line with the cursor in front of each line
  relativenumber = true,
  -- Copy indent from current line when starting a new line (typing <CR> in Insert mode or when using the "o" or "O" command)
  autoindent = true,
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
  smartcase = true,
  -- 关闭backup
  backup = false,
  -- 在切换buffer时，持久化undo历史记录。see 『:help undo-persistence』
  undofile = true,
  -- String-encoding used internally and for |RPC| communication. Always UTF-8.
  encoding = 'utf-8',
  -- This is a list of character encodings considered when starting to edit an existing file. 写入文件的编码要通过fileencoding配置，默认是'utf-8'
  fileencodings = { "ucs-bom", "utf-8", "cp936" },
  -- When a file has been detected to have been changed outside of Vim and it has not been changed inside of Vim, automatically read it again.
  autoread = true,
  -- default updatetime 4000ms is not good for async update, e.g. for faster completion
  updatetime = 100,
  -- 在终端内开启『true color』模式，让终端可以使用更丰富的颜色范围
  termguicolors = true,
  background = "dark",
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

-- diff配置，在vim中使用vimdiff或:diffthis启动diff mode时，diff的表现
vim.opt.diffopt:append({"iwhite", "vertical"})
-- CTRL-P/CTRL-N时，complete列表添加『代码所依赖的其他文件中的符号和关键字』。see 『:help 'complete'』
vim.opt.complete:append("i")
