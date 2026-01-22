return {
  "mattn/emmet-vim",
  ft = { 
    "html", "css", "scss", "sass", "less", 
    "javascript", "typescript", 
    "javascriptreact", "typescriptreact" 
  },
  config = function()
    -- Emmet 配置
    vim.g.user_emmet_mode = 'i'  -- 只在插入模式下启用
    vim.g.user_emmet_install_global = 0  -- 不全局安装，只在指定文件类型中启用
    vim.g.user_emmet_leader_key = '<C-y>'  -- 使用 C-y 作为触发键
    
    -- 为支持的文件类型启用 Emmet
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 
        "html", "css", "scss", "sass", "less", 
        "javascript", "typescript", 
        "javascriptreact", "typescriptreact" 
      },
      callback = function()
        -- 确保文件类型下启用 Emmet
        vim.b.user_emmet_mode = 'i'
        vim.b.user_emmet_leader_key = '<C-y>'
      end,
    })
  end,
}