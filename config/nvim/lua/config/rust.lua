local M = {}

function M.setup()
  local project_root = assert(vim.lsp.config.rust_analyzer.root_dir)
  vim.lsp.config('rust_analyzer', {
    root_dir = function(bufnr, on_dir)
      if vim.fs.root(bufnr, { 'Cargo.toml', 'rust-project.json' }) then
        project_root(bufnr, on_dir)
        return
      end

      -- A directory (or Git root) alone is not a Rust project. Explicitly pass
      -- standalone files to rust-analyzer instead of asking it to discover Cargo.
      local filename = vim.api.nvim_buf_get_name(bufnr)
      if filename == '' then return end
      local config = vim.deepcopy(vim.lsp.config.rust_analyzer)
      config.root_dir = nil
      config.workspace_folders = nil
      config.settings['rust-analyzer'].detachedFiles = { filename }
      -- Detached files have no Cargo manifest. Feed rustc's JSON diagnostics to
      -- rust-analyzer instead; metadata-only checking never runs the program.
      config.settings['rust-analyzer'].checkOnSave = true
      config.settings['rust-analyzer'].check = vim.tbl_deep_extend('force',
        config.settings['rust-analyzer'].check or {}, {
          overrideCommand = {
            'rustc', '--error-format=json', '--emit=metadata', '-o', '/dev/null', filename,
          },
          invocationStrategy = 'once',
        })
      -- Start here rather than calling on_dir: each independent file gets its
      -- own detached-file configuration, even when several share a directory.
      vim.lsp.start(config, {
        bufnr = bufnr,
        reuse_client = function(client)
          return client.name == 'rust_analyzer'
            and vim.tbl_get(client.config, 'settings', 'rust-analyzer', 'detachedFiles', 1) == filename
        end,
      })
    end,
  })
end

return M
