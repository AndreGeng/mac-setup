return {
  "github/copilot.vim",
  event = "InsertEnter",
  config = function()
    -- Configure Copilot
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""
    
    -- Key mappings
    vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      desc = "Accept Copilot suggestion"
    })
    vim.keymap.set('i', '<C-L>', 'copilot#Next()', {
      expr = true,
      desc = "Next Copilot suggestion"
    })
    vim.keymap.set('i', '<C-K>', 'copilot#Previous()', {
      expr = true,
      desc = "Previous Copilot suggestion"
    })
    vim.keymap.set('i', '<C-X>', 'copilot#Dismiss()', {
      expr = true,
      desc = "Dismiss Copilot suggestion"
    })
    
    -- Create LspCopilotSignIn command for compatibility
    vim.api.nvim_create_user_command('LspCopilotSignIn', function()
      vim.cmd('Copilot auth')
    end, { desc = 'Sign in to GitHub Copilot' })
    
    -- Create LspCopilotSignOut command for compatibility
    vim.api.nvim_create_user_command('LspCopilotSignOut', function()
      vim.cmd('Copilot detach')
    end, { desc = 'Sign out from GitHub Copilot' })
  end,
}