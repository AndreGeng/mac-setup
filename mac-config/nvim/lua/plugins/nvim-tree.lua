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
      -- open the tree
      require("nvim-tree.api").tree.open()
    end
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

    vim.g.nvim_tree_quit_on_open = 1
  end,
  keys = {
    { '<leader>ef', ':NvimTreeFindFile<cr>', noremap = true },
    { '<leader>ee', ':NvimTreeToggle<cr>', noremap = true },
  },
}
