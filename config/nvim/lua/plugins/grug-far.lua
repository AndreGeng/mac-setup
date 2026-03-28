-- Grug-far.nvim: 强大的搜索和替换插件
-- 统一使用 <leader>sr 前缀的快捷键
-- mode 说明: 'n' = Normal模式, 'x' = Visual模式, 相同键位在不同模式下不冲突
-- 快捷键总览:
-- <leader>srr (n,x) - 全局搜索替换
-- <leader>srf (n)   - 搜索光标下的单词
-- <leader>src (n)   - 当前文件内搜索
-- <leader>src (x)   - 可视选择搜索（当前文件）
-- <leader>srf (x)   - 可视选择搜索（全局）
-- <leader>sra (n,x) - 使用 ast-grep 引擎


return {
  'MagicDuck/grug-far.nvim',
  cmd = { 'GrugFar', 'GrugFarWithin' },
  keys = {
    -- 全局搜索替换
    {
      '<leader>srr',
      function()
        require('grug-far').open({
          transient = true,
        })
      end,
      mode = { 'n', 'x' },
      desc = 'Grug Far - Search and Replace (global)',
    },
    -- 搜索光标下的单词
    {
      '<leader>srf',
      function()
        require('grug-far').open({
          transient = true,
          prefills = {
            search = vim.fn.expand('<cword>'),
          },
        })
      end,
      mode = 'n',
      desc = 'Grug Far - Search word under cursor',
    },
    -- 当前文件内搜索
    {
      '<leader>src',
      function()
        require('grug-far').open({
          transient = true,
          prefills = {
            paths = vim.fn.expand('%'),
          },
        })
      end,
      mode = { 'n' },
      desc = 'Grug Far - Search in current file',
    },
    -- 可视选择搜索（当前文件）
    {
      '<leader>src',
      function()
        require('grug-far').with_visual_selection({
          transient = true,
          prefills = {
            paths = vim.fn.expand('%'),
          },
        })
      end,
      mode = 'x',
      desc = 'Grug Far - Search selection in current file',
    },
    -- 可视选择搜索（全局）
    {
      '<leader>srf',
      function()
        require('grug-far').with_visual_selection({
          transient = true,
        })
      end,
      mode = 'x',
      desc = 'Grug Far - Search selection globally',
    },
    -- 使用 ast-grep 引擎
    {
      '<leader>sra',
      function()
        require('grug-far').open({
          transient = true,
          engine = 'astgrep',
        })
      end,
      mode = { 'n', 'x' },
      desc = 'Grug Far - Search with ast-grep engine',
    },
  },
  config = function()
    require('grug-far').setup({
      -- 简化配置，使用默认值
      -- transient = true 在快捷键中已启用
    })
  end
}
