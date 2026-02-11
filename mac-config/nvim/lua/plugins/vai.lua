return {
  {
    "johnpmitsch/vai.nvim",
    event = "VeryLazy",
    config = function()
      require("vai").setup({
        -- your vai config here
        -- see https://github.com/vai/vai.nvim for more info
        trigger = ";"
      })
    end,
  },
}
