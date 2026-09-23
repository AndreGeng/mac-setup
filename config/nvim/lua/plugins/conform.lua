return {
  'stevearc/conform.nvim',
  opts = {
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      svelte = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      graphql = { "prettier" },
      lua = { "stylua" },
      python = { "ruff_format" },
      go = { "gofmt", lsp_format = "prefer" },
    },
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      if vim.bo[bufnr].filetype == "go" then
        require("config.go").organize_imports(bufnr)
      end
      return { timeout_ms = 10000 }
    end
  },
  init = function()
    vim.keymap.set({ "n", "v" }, "<leader>fa", function()
      require("conform").format({
        async = false,
        timeout_ms = 10000, -- 增加到10秒，适合大文件
      })
    end, { desc = "Format file or range (in visual mode)" })

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })
    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end
}
