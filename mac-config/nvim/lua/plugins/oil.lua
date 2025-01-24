return {
  -- A vim-vinegar like file explorer that lets you edit your filesystem like a normal Neovim buffer
  'stevearc/oil.nvim',
  opts = {
    default_file_explorer = false,
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-x>"] = "actions.select_split",
      ["<C-s>"] = "actions.select_split",
      ["<ESC>"] = "actions.close",
      ["<C-r>"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["<C-[>"] = "actions.parent",
      ["<C-]>"] = "actions.cd",
      ["tc"] = "actions.tcd",
      ["gs"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["g\\"] = "actions.toggle_trash",
    },
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = false,
  },
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" }
  }
}
