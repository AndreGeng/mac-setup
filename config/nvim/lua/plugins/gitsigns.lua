return {
  -- gitgutter
  'lewis6991/gitsigns.nvim',
  opts = {
    -- 优化文件描述符使用
    update_debounce = 1000,  -- 正确的防抖配置名
    watch_gitdir = {
      enable = false,  -- 禁用文件监控以减少文件句柄
      follow_files = false,
    },
    max_file_length = 10000,  -- 限制大文件处理
    
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, { expr = true })
    end
  },
}
