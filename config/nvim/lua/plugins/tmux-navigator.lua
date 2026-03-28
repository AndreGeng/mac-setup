return {
  -- When combined with a set of tmux key bindings, the plugin will allow you to navigate seamlessly between vim and tmux splits using a consistent set of hotkeys.
  {
    'christoomey/vim-tmux-navigator',
    init = function()
      vim.cmd([[
    " tmux navigator: Disable tmux navigator when zooming the Vim pane
    let g:tmux_navigator_disable_when_zoomed = 1
  ]])
    end
  }
}
