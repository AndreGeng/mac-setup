return {
  {
    'numToStr/Comment.nvim',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      local ok, ts = pcall(require, 'ts_context_commentstring')
      local pre_hook = nil
      if ok and ts and ts.integrations and ts.integrations.comment_nvim then
        pre_hook = ts.integrations.comment_nvim.create_pre_hook()
      end

      require('Comment').setup {
        pre_hook = pre_hook,
        padding = true,
        sticky = true,
        ignore = nil,
        toggler = {
          ---Line-comment toggle keymap
          line = 'gcc',
          ---Block-comment toggle keymap
          block = 'gbc',
        },
        ---LHS of operator-pending mappings in NORMAL and VISUAL mode
        opleader = {
          ---Line-comment keymap
          line = 'gc',
          ---Block-comment keymap
          block = 'gb',
        },
        ---LHS of extra mappings
        extra = {
          ---Add comment on the line above
          above = 'gcO',
          ---Add comment on the line below
          below = 'gco',
          ---Add comment at the end of line
          eol = 'gcA',
        },
        ---Enable keybindings
        mappings = {
          basic = true,
          extra = true,
          extended = false,
        },
      }
    end
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
        languages = {
          typescriptreact = { __default = '{/* %s */}', __multiline = '/* %s */' },
          jsx = { __default = '{/* %s */}', __multiline = '/* %s */' },
        },
      }
    end
  }
}
