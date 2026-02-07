-- CodeCompanion.nvim with OpenCode ACP adapter
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "CodeCompanion",
    "CodeCompanionChat",
    "CodeCompanionCmd",
    "CodeCompanionActions",
  },
  opts = {
    interactions = {
      chat = {
        adapter = {
          name = "opencode",
          -- model is optional, will use OpenCode's default model from config
        },
      },
      inline = {
        adapter = {
          name = "opencode",
        },
      },
    },
  },
  keys = {
    -- Inline assistant - prompt for input
    {
      "<leader>cc",
      function()
        vim.ui.input({ prompt = "CodeCompanion: " }, function(input)
          if input and input ~= "" then
            vim.cmd("CodeCompanion " .. input)
          end
        end)
      end,
      desc = "CodeCompanion Inline Assistant",
    },
    -- Action palette (recommended workflow entry point)
    {
      "<leader>ca",
      "<cmd>CodeCompanionActions<cr>",
      desc = "CodeCompanion Action Palette",
    },
    -- Toggle chat window
    {
      "<leader>ct",
      "<cmd>CodeCompanionChat Toggle<cr>",
      desc = "CodeCompanion Toggle Chat",
    },
    -- Add selection to chat
    {
      "<leader>cv",
      "<cmd>CodeCompanionChat Add<cr>",
      mode = { "v", "x" },
      desc = "CodeCompanion Add Selection to Chat",
    },
  },
}
