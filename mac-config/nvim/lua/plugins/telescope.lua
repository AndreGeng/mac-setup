require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
    -- please take a look at the readme of the extension you want to configure
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')


vim.keymap.set('n', '<leader>ff', '<cmd>lua require("telescope.builtin").find_files()<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fl', '<cmd>lua require("telescope.builtin").live_grep()<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fb', '<cmd>lua require("telescope.builtin").buffers()<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fh', '<cmd>lua require("telescope.builtin").help_tags()<cr>', { noremap = true })

