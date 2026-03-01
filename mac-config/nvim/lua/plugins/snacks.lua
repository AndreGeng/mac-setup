return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      indent = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = true },
      scroll = { enabled = true },
      lazygit = { enabled = true },
      words = { enabled = true },
      picker = {
        enabled = true,
      },
      styles = {
        notification = {
          wo = { wrap = true }
        }
      }
    },
    keys = {
      -- Top Pickers & Explorer
      { "<leader><space>", function() require("snacks").picker.smart() end,              desc = "Smart Find Files" },
      { "<leader>/",       function() require("snacks").picker.grep() end,               desc = "Grep" },
      { "<leader>:",       function() require("snacks").picker.command_history() end,    desc = "Command History" },
      { "<leader>n",       function() require("snacks").picker.notifications() end,      desc = "Notification History" },
      -- find
      { "<leader>fb",      function() require("snacks").picker.buffers() end,            desc = "Buffers" },
      { "<leader>ff",      function() require("snacks").picker.files() end,              desc = "Find Files" },
      { "<leader>fi",      function() require("snacks").picker.files({ find_command = {"fd", "-i", "--type", "f", "--hidden", "-I"}, hidden = true, ignored = true }) end, desc = "Find Ignored Files (with fd)" },
      -- Grep
      { "<leader>sb",      function() require("snacks").picker.lines() end,              desc = "Buffer Lines" },
      -- search
      { '<leader>s"',      function() require("snacks").picker.registers() end,          desc = "Registers" },
      { '<leader>s/',      function() require("snacks").picker.search_history() end,     desc = "Search History" },
      { "<leader>sd",      function() require("snacks").picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sa",      function() require("snacks").picker.diagnostics() end,        desc = "All Diagnostics" },
      { "<leader>sk",      function() require("snacks").picker.keymaps() end,            desc = "Keymaps" },
      { "<leader>sl",      function() require("snacks").picker.loclist() end,            desc = "Location List" },
      { "<leader>sq",      function() require("snacks").picker.qflist() end,             desc = "Quickfix List" },
      -- LSP
      { "<leader>cs",      function() require("snacks").picker.lsp_symbols() end,        desc = "Symbols" },
      { "<leader>cl",      function() require("snacks").picker.lsp_definitions() end,    desc = "LSP Definitions" },
      { "<leader>cr",      function() require("snacks").picker.lsp_references() end,     desc = "LSP References" },
      { "<leader>ci",      function() require("snacks").picker.lsp_implementations() end, desc = "LSP Implementations" },
      { "<leader>ct",      function() require("snacks").picker.lsp_type_definitions() end, desc = "LSP Type Definitions" },
      { "<leader>cg",      function() require("snacks").picker.lsp_incoming_calls() end, desc = "LSP Incoming Calls" },
      { "<leader>co",      function() require("snacks").picker.lsp_outgoing_calls() end, desc = "LSP Outgoing Calls" },
      -- Other
      { "<leader>gg",      function() require("snacks").lazygit() end,                     desc = "Lazygit" },
      { "<leader>bd",      function() require("snacks").bufdelete() end,                 desc = "Delete Buffer" },
      { "]]",              function() require("snacks").words.jump(vim.v.count1) end,    desc = "Next Reference",      mode = { "n", "t" } },
      { "[[",              function() require("snacks").words.jump(-vim.v.count1) end,   desc = "Prev Reference",      mode = { "n", "t" } },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          local snacks = require("snacks")

          -- Create some toggle mappings
          snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        end,
      })
    end,
  },
}
