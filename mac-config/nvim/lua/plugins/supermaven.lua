-- Supermaven AI code completion
return {
  "supermaven-inc/supermaven-nvim",
  event = "InsertEnter",
  cmd = {
    "SupermavenUseFree",
    "SupermavenUsePro",
    "SupermavenLogout",
    "SupermavenShowLog",
    "SupermavenClearLog",
  },
  opts = {
    -- Disable inline completion since we're using nvim-cmp
    disable_inline_completion = true,
    -- Let nvim-cmp handle suggestion acceptance
    keymaps = {
      accept_suggestion = nil, -- handled by nvim-cmp
      clear_suggestion = "<C-]>",
      accept_word = "<C-l>",
    },
    -- Ignore certain filetypes
    ignore_filetypes = {
      bigfile = true,
      snacks_input = true,
      snacks_notif = true,
    },
    -- Logging configuration
    log_level = "info", -- "info" | "off"
    -- Disable built-in keymaps for more manual control (optional)
    disable_keymaps = false,
  },
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
}
