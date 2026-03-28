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
    -- Enable inline completion (like Copilot)
    disable_inline_completion = false,
    -- Key mappings matching Copilot for consistency
    keymaps = {
      accept_suggestion = "<C-J>", -- Accept full suggestion (same as Copilot)
      clear_suggestion = "<C-X>", -- Dismiss suggestion (same as Copilot)
      accept_word = "<C-L>", -- Accept word by word (using C-L like Copilot's Next)
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
  -- No longer needs nvim-cmp dependency for inline completion
}
