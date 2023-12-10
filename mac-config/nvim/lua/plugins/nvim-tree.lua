require'nvim-tree'.setup {
  hijack_directories = {
    enable = false
  },
  view = {
    width = 50,
    side = 'right',
  },
}

local function open_nvim_tree()
  -- open the tree
  require("nvim-tree.api").tree.open()
end
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

vim.g.nvim_tree_quit_on_open = 1
vim.keymap.set('n', '<leader>ef', ':NvimTreeFindFile<cr>', { noremap = true })
vim.keymap.set('n', '<leader>ee', ':NvimTreeToggle<cr>', { noremap = true })
