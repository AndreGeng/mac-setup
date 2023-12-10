local cb = require'diffview.config'.diffview_callback

require'diffview'.setup {
  key_bindings = {
    file_panel = {
      ["j"]             = cb("select_next_entry"),           -- Bring the cursor to the next file entry
      ["<down>"]        = cb("select_next_entry"),
      ["k"]             = cb("select_prev_entry"),           -- Bring the cursor to the previous file entry.
      ["<up>"]          = cb("select_prev_entry"),
    },
  },
}

vim.keymap.set('n', '<leader>dh', ':DiffviewFileHistory<cr>', { noremap = true })
vim.cmd([[
  cnoreabbrev do DiffviewOpen
  cnoreabbrev dfh DiffviewFileHistory
]])

