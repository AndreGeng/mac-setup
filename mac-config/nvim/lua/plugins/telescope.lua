return {
  -- fuzzy find
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
      },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
    },
    config = function()
      local lga_actions = require("telescope-live-grep-args.actions")

      -- To get fzf loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require('telescope').load_extension('fzf')
      require("telescope").load_extension("live_grep_args")

      vim.keymap.set('n', '<leader>ff',
        '<cmd>lua require("telescope.builtin").find_files({ previewer = false })<cr>',
        { noremap = true })
      vim.keymap.set('n', '<leader>fg', '<cmd>lua require("telescope").extensions.live_grep_args.live_grep_args()<cr>',
        { noremap = true })
      vim.keymap.set('n', '<leader>fb', '<cmd>lua require("telescope.builtin").buffers()<cr>', { noremap = true })
      vim.keymap.set('n', '<leader>fh', '<cmd>lua require("telescope.builtin").help_tags()<cr>', { noremap = true })

      return {
        defaults = {
          -- Default configuration for telescope goes here:
          -- config_key = value,
          -- wrap_results = true,
          mappings = {
            i = {
              -- map actions.which_key to <C-h> (default: <C-/>)
              -- actions.which_key shows the mappings for your picker,
              -- e.g. git_{create, delete, ...}_branch for the git_branches picker
            }
          },
          preview = { hide_on_startup = true },
          path_display = { "truncate" },
          layout_config = {
            width = 0.9,
          },
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
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = {         -- extend mappings
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
              },
            },
            -- ... also accepts theme settings, for example:
            -- theme = "dropdown", -- use dropdown theme
            -- theme = { }, -- use own theme spec
            -- layout_config = { mirror=true }, -- mirror preview pane
          }
        }

      }
    end,
  },

}
