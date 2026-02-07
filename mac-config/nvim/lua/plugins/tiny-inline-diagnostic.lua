return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup({
      options = {
        -- Workaround for userdata concatenation bug
        show_source = false,
        -- Disable code display to avoid the bug
        show_code = false,
      },
    })
    vim.diagnostic.config({ virtual_text = false })
  end,
}
