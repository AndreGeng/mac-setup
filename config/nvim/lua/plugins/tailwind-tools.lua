return {
  "luckasRanarison/tailwind-tools.nvim",
  name = "tailwind-tools",
  build = ":UpdateRemotePlugins",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional
    "neovim/nvim-lspconfig",         -- optional
  },
  opts = {
    server = {
      override = false, -- Disable lspconfig override to avoid deprecation warning
    },
    document_color = {
      enabled = false, -- Disable to avoid client.request deprecation warning
    }
  }
}
