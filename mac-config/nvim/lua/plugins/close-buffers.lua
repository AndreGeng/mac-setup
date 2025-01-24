-- <leader>dn delete nameless buffers
return {
  'Asheq/close-buffers.vim',
  keys = {
    { '<leader>dn', ':Bdelete! nameless<cr>', noremap = true }
  },
}
