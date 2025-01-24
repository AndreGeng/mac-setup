return {
  -- Single tabpage interface for easily cycling through diffs for all modified files for any git rev.
  'sindrets/diffview.nvim',
  opts = function()
    local cb = require 'diffview.config'.diffview_callback
    return {
      key_bindings = {
        file_panel = {
          ["j"]      = cb("select_next_entry"), -- Bring the cursor to the next file entry
          ["<down>"] = cb("select_next_entry"),
          ["k"]      = cb("select_prev_entry"), -- Bring the cursor to the previous file entry.
          ["<up>"]   = cb("select_prev_entry"),
        },
      },
    }
  end,
  keys = {
    { '<leader>dh', ':DiffviewFileHistory<cr>', noremap = true }
  },
  init = function()
    vim.cmd([[
      cnoreabbrev do DiffviewOpen
      cnoreabbrev dfh DiffviewFileHistory
    ]])
  end
}
