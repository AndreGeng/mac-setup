return {
  {
    'hrsh7th/cmp-nvim-lsp',
    dependencies = {
      "hrsh7th/nvim-cmp",
    }
  },
  {
    'hrsh7th/cmp-buffer',
    dependencies = {
      "hrsh7th/nvim-cmp",
    }
  },
  {
    'hrsh7th/cmp-path',
    dependencies = {
      "hrsh7th/nvim-cmp",
    }
  },
  {
    'hrsh7th/nvim-cmp',
    version = false,
    event = "InsertEnter",
    opts = function()
      local cmp = require("cmp")

      return {
        mapping = {
          ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
          ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
          ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
          ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
          ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          }),
          -- Accept currently selected item. If none selected, `select` first item.
          -- Set `select` to `false` to only confirm explicitly selected items.
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ["<C-n>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_next_item()
            else
              cmp.complete()
            end
          end, { 'i', 'c' }),
          ["<C-p>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_prev_item()
            else
              cmp.complete()
            end
          end, { 'i', 'c' }),
        },
        sources = cmp.config.sources({
          { name = "supermaven", group_index = 1, priority = 100 }, -- AI completion with high priority
          {
            name = 'nvim_lsp',
            entry_filter = function(entry)
              return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
            end
          },
          { name = 'buffer' },
        }),
        experimental = {
          ghost_text = true
        }
      }
    end,
    dependencies = {
      "tailwind-tools",
      "supermaven-inc/supermaven-nvim",
    }
  },
}
