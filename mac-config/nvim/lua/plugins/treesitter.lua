return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ":TSUpdate",
    opts = {
      ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
      ignore_install = {},      -- List of parsers to ignore installing
      highlight = {
        enable = true,          -- false will disable the whole extension
        disable = {},           -- list of language that will be disabled
      },
      indent = {
        enable = true,
        disable = { 'python', 'c', }
      }

    },
    init = function()
      vim.g.skip_ts_context_commentstring_module = true
    end,
  }
}
