require('hop').setup();

vim.keymap.set('n', 'f', ':HopChar1<cr>', { noremap = true })
vim.keymap.set('n', 'gl', ':HopLine<cr>', { noremap = true })
