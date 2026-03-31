-- Java Development Plugin Configuration
-- Requires: jdtls, java-test, java-debug-adapter

return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    config = function()
      -- 配置 nvim-jdtls
      local config = {
        cmd = {
          'jdtls',
          -- 配置数据路径
          '-data',
          vim.fn.stdpath('data') .. '/jdtls-workspace',
        },
        root_dir = vim.fs.root_pattern({
          'build.gradle',
          'pom.xml',
          'settings.gradle',
          'gradlew',
          'mvnw',
          '.git',
        }),
        settings = {
            java = {
              eclipse = {
                downloadSources = true,
              },
              maven = {
                downloadSources = true,
              },
              configuration = {
                runtimes = {
                  {
                    name = "JavaSE-1.8",
                    path = "/usr/local/opt/openjdk@8/libexec/openjdk/Contents/Home",
                  },
                },
              },
            implementationCodeLens = {
              enabled = true,
            },
            referencesCodeLens = {
              enabled = true,
            },
            signatureHelp = {
              enabled = true,
            },
            format = {
              enabled = true,
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Java 特定的 keymap
          vim.keymap.set('n', '<leader>jo', ':JdtOverwrite<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Overwrite' })
          vim.keymap.set('n', '<leader>jc', ':JdtCompile<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Compile' })
          vim.keymap.set('n', '<leader>jr', ':JdtRestart<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Restart' })
          vim.keymap.set('n', '<leader>jd', ':JdtDebug<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Debug' })
          vim.keymap.set('n', '<leader>jt', ':JdtTest<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Test' })
          vim.keymap.set('n', '<leader>jR', ':JdtRefreshConfig<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Refresh Config' })
          
          -- 保留 LSP 通用功能
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover' })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
        end,
      }
      require('jdtls').start_or_attach(config)
    end,
  },
}
