return {
  -- directory viewer
  'nvim-tree/nvim-tree.lua',
  opts = {
    hijack_directories = {
      enable = false
    },
    view = {
      width = 50,
      side = 'right',
    },
    filesystem_watchers = {
      enable = false,
    }
  },
  init = function()
    local function open_nvim_tree()
      local api = require("nvim-tree.api")
      if vim.fn.argc() == 0 then
        api.tree.open()
        return
      end
      local arg = vim.fn.argv(0)
      local stat = vim.loop.fs_stat(arg)
      if not stat then
        return
      end
      if stat.type == "directory" then
        api.tree.open({ path = arg, find_file = false })
      else
        local dir = vim.fn.fnamemodify(arg, ":h")
        api.tree.open({ path = dir, find_file = true })
      end
    end
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

    vim.g.nvim_tree_quit_on_open = 1
  end,
  keys = {
    { '<leader>ef', ':NvimTreeFindFile<cr>', noremap = true },
    { '<leader>ee', ':NvimTreeToggle<cr>',   noremap = true },
  },
}
