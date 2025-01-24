return {
  -- show git history for specific range
  'junegunn/gv.vim',
  dependencies = {
    -- git
    'tpope/vim-fugitive',
  },
  keys = {
    { '<leader>gv', ':GV!<cr>', mode = { 'n', 'v' }, noremap = true }
  }
}
