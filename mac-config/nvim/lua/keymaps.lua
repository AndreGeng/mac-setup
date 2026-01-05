-- With a map leader it's possible to do extra key combinations like <leader>w saves the current file
vim.g.mapleader = ","

-- Fold shortcut
vim.keymap.set('n', '<space>', 'za', { noremap = true })

-- Terminal
vim.keymap.set('t', '<C-g>', '<C-\\><C-n>', { noremap = true })

-- Fast saving
vim.keymap.set('n', '<leader>w', ':w!<cr>', { noremap = true })

-- Smart way to close pane
vim.keymap.set('n', '<leader>q', ':q<cr>', { noremap = true })

-- Fast eval
vim.keymap.set('n', '<leader>en', ':w !node<cr>', { noremap = true })
vim.keymap.set('n', '<leader>em',
  ':w !node --experimental-modules --input-type=module --es-module-specifier-resolution=node<cr>', { noremap = true })
vim.keymap.set('n', '<leader>et', ':w !ts-node<cr>', { noremap = true })

-- Git shortcut
vim.keymap.set('n', '<leader>gb', ':Git blame<cr>', { noremap = true })

-- Buffer explorer
vim.keymap.set('n', '<leader>be', ':Buffers<cr>', { noremap = true })

-- Command-line mapping
vim.keymap.set('c', '<C-A>', '<home>', { noremap = true })

-- Move a line of text using ALT+[m,], The == re-indents the line to suit its new position.@see https://vim.fandom.com/wiki/Moving_lines_up_or_down
vim.keymap.set('n', '<A-m>', ':m .+1<CR>==', { noremap = true })
vim.keymap.set('n', '<A-,>', ':m .-2<CR>==', { noremap = true })
vim.keymap.set('i', '<A-m>', '<Esc>:m .+1<CR>==gi', { noremap = true })
vim.keymap.set('i', '<A-,>', '<Esc>:m .-2<CR>==gi', { noremap = true })
vim.keymap.set('v', '<A-m>', ':m \'>+1<CR>gv=gv', { noremap = true })
vim.keymap.set('v', '<A-,>', ':m \'<-2<CR>gv=gv', { noremap = true })

-- Useful mappings for managing tabs
vim.keymap.set('n', '<leader>tt', ':tabnew<cr>', { noremap = true })
vim.keymap.set('n', '<leader>to', ':tabonly<cr>', { noremap = true })
vim.keymap.set('n', '<leader>tc', ':tabclose<cr>', { noremap = true })
vim.keymap.set('n', '<leader>tn', ':tabnext<cr>', { noremap = true })
vim.keymap.set('n', '<leader>tp', ':tabp<cr>', { noremap = true })

-- always use very magic when search
vim.keymap.set('n', '/', '/\\v', { noremap = true })

-- toggle quickfixlist/locationlist
vim.keymap.set('n', '<leader>k', ':call ToggleList("Quickfix", "c")<cr>', { noremap = true })
vim.keymap.set('n', '<leader>ll', ':call ToggleList("Location", "l")<cr>', { noremap = true })

-- <C-t>: go back to previous buffer
vim.keymap.set('n', '<C-t>', ':call GoBackToRecentBuffer()<cr>', { noremap = true })

-- Format with Biome (使用 <leader>ft 避免与 telescope buffers 冲突)
vim.keymap.set('n', '<leader>ft', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == '' then
    vim.notify('当前文件未保存，无法格式化', vim.log.levels.WARN)
    return
  end

  -- 临时禁用 Conform 自动格式化，避免保存时触发格式化失败
  local was_disabled = vim.g.disable_autoformat
  vim.g.disable_autoformat = true

  -- 保存文件
  vim.cmd('write')

  -- 恢复 Conform 自动格式化状态
  vim.g.disable_autoformat = was_disabled

  -- 使用 Prettier 进行临时格式化（不依赖配置文件）
  local file_content = vim.fn.readfile(filepath)
  local file_text = table.concat(file_content, '\n')

  -- 根据文件扩展名确定 Prettier 的 parser
  local file_ext = vim.fn.fnamemodify(filepath, ':e'):lower()
  local parser_map = {
    js = 'babel',
    jsx = 'babel',
    ts = 'typescript',
    tsx = 'typescript',
    json = 'json',
    css = 'css',
    scss = 'scss',
    less = 'less',
    html = 'html',
    htm = 'html',
    xml = 'html',
    md = 'markdown',
    yaml = 'yaml',
    yml = 'yaml',
    graphql = 'graphql',
    vue = 'vue',
    svelte = 'svelte',
  }

  local parser = parser_map[file_ext]

  -- 如果没有找到对应的 parser，尝试根据文件内容自动检测
  if not parser then
    -- 移除首尾空白后检查
    local trimmed = file_text:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed and #trimmed > 0 then
      local first_char = trimmed:sub(1, 1)
      -- 检查是否是 JSON（以 { 或 [ 开头）
      if first_char == '{' or first_char == '[' then
        parser = 'json'
        -- 检查是否是 HTML
      elseif first_char == '<' and (trimmed:match('<!DOCTYPE') or trimmed:match('<html') or trimmed:match('<div')) then
        parser = 'html'
        -- 检查是否是 Markdown（以 # 开头）
      elseif trimmed:match('^#+%s') then
        parser = 'markdown'
        -- 检查是否是 YAML（以 --- 或 key: 开头）
      elseif trimmed:match('^%-%-%-') or trimmed:match('^[%w_]+%s*:') then
        parser = 'yaml'
      else
        -- 默认使用 babel（JavaScript）
        parser = 'babel'
      end
    else
      parser = 'babel'
    end
  end

  local error_output = {}
  local formatted_output = {}

  -- 使用 stdin/stdout 方式，Prettier 不需要配置文件也能工作
  local job_id = vim.fn.jobstart({ 'npx', '--yes', 'prettier', '--stdin-filepath', filepath, '--parser', parser }, {
    stdin = 'pipe',
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= '' then
            table.insert(formatted_output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        -- 将格式化后的内容写回文件
        if #formatted_output > 0 then
          local formatted_text = table.concat(formatted_output, '\n')
          -- Prettier 会自动处理末尾换行符，保持原文件的换行符风格
          vim.fn.writefile(vim.split(formatted_text, '\n'), filepath)
          vim.notify('Prettier 格式化完成', vim.log.levels.INFO, { title = 'Prettier' })
          -- 重新加载文件
          vim.cmd('edit')
        else
          vim.notify('Prettier 格式化完成（无变化）', vim.log.levels.INFO, { title = 'Prettier' })
        end
      else
        local error_msg = #error_output > 0 and table.concat(error_output, '\n') or ('退出码: ' .. exit_code)
        vim.notify('Prettier 格式化失败:\n' .. error_msg, vim.log.levels.ERROR, { title = 'Prettier', timeout = 5000 })
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= '' then
            table.insert(error_output, line)
          end
        end
      end
    end,
  })

  -- 通过管道发送文件内容
  if job_id > 0 then
    vim.fn.chansend(job_id, file_text)
    vim.fn.chanclose(job_id, 'stdin')
  end
end, { desc = 'Format file with Prettier (temporary, no config)' })
