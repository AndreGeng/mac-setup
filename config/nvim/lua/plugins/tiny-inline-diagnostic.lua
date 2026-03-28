return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup({
      options = {
        show_source = false,
        show_code = false,
        -- 仅当光标正好在诊断位置时才显示，减少 normal 下移动光标时的打扰
        show_diags_only_under_cursor = true,
      },
    })
    vim.diagnostic.config({ virtual_text = false })
  end,
}
