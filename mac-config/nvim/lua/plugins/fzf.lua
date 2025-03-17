return {
  'junegunn/fzf',
  -- dir = '~/.fzf',
  build = './install --all',
  init = function()
    vim.keymap.set('n', '<leader>fo', ':Files<cr>', { noremap = true })
    vim.env.FZF_DEFAULT_COMMAND = 'fd -i --type f'
    vim.g.fzf_preview_window = {}
  end,
  keys = {
    { '<leader>fi', ':call fzf#run(fzf#wrap({"source": "fd -i --type f --hidden -I"}))<cr>', noremap = true }
  }
}
