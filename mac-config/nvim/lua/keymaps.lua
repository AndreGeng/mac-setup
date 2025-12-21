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
vim.keymap.set('n', '<leader>l', ':call ToggleList("Location", "l")<cr>', { noremap = true })

-- <C-t>: go back to previous buffer
vim.keymap.set('n', '<C-t>', ':call GoBackToRecentBuffer()<cr>', { noremap = true })

-- Format with Biome (使用 <leader>ft 避免与 telescope buffers 冲突)
vim.keymap.set('n', '<leader>ft', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == '' then
    vim.notify('当前文件未保存，无法格式化', vim.log.levels.WARN)
    return
  end

  -- 保存文件
  vim.cmd('write')

  -- 执行 biome format
  vim.fn.jobstart({ 'npx', '@biomejs/biome', 'format', '--write', filepath }, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify('Biome 格式化完成', vim.log.levels.INFO, { title = 'Biome' })
        -- 重新加载文件
        vim.cmd('edit')
      else
        vim.notify('Biome 格式化失败 (退出码: ' .. exit_code .. ')', vim.log.levels.ERROR, { title = 'Biome' })
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.notify('Biome 错误: ' .. table.concat(data, ' '), vim.log.levels.ERROR, { title = 'Biome' })
      end
    end,
  })
end, { desc = 'Format file with Biome' })
