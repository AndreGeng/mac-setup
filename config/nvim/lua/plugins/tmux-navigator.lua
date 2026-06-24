return {
  -- When combined with a set of tmux key bindings, the plugin will allow you to navigate seamlessly between vim and tmux splits using a consistent set of hotkeys.
  {
    'christoomey/vim-tmux-navigator',
    init = function()
      vim.cmd([[
    " tmux navigator: Disable tmux navigator when zooming the Vim pane
    let g:tmux_navigator_disable_when_zoomed = 1
    let g:tmux_navigator_no_mappings = 1
  ]])
    end,
    config = function()
      local function navigate(direction, vim_direction, tmux_command)
        local current_window = vim.api.nvim_get_current_win()

        if vim.fn.mode():sub(1, 1) == 't' then
          vim.cmd('stopinsert')
        end

        vim.cmd('wincmd ' .. vim_direction)
        if vim.api.nvim_get_current_win() ~= current_window then
          return
        end

        if vim.env.HERDR_ENV == '1' and vim.fn.executable('herdr') == 1 then
          vim.fn.jobstart({ 'herdr', 'pane', 'focus', '--direction', direction }, { detach = true })
        else
          vim.cmd(tmux_command)
        end
      end

      vim.keymap.set({ 'n', 't' }, '<BS>', function()
        navigate('left', 'h', 'TmuxNavigateLeft')
      end, { silent = true })
      vim.keymap.set({ 'n', 't' }, '<C-h>', function()
        navigate('left', 'h', 'TmuxNavigateLeft')
      end, { silent = true })
      vim.keymap.set({ 'n', 't' }, '<C-j>', function()
        navigate('down', 'j', 'TmuxNavigateDown')
      end, { silent = true })
      vim.keymap.set({ 'n', 't' }, '<C-k>', function()
        navigate('up', 'k', 'TmuxNavigateUp')
      end, { silent = true })
      vim.keymap.set({ 'n', 't' }, '<C-l>', function()
        navigate('right', 'l', 'TmuxNavigateRight')
      end, { silent = true })
    end
  }
}
