-- Java Development Plugin Configuration
-- Requires: jdtls, java-test, java-debug-adapter

local MISE = vim.fn.exepath('mise')
if MISE == '' then
  MISE = vim.fn.expand('~/.local/bin/mise')
end

local function mise_where(spec)
  if vim.fn.executable(MISE) ~= 1 then
    return nil
  end

  local root = vim.trim(vim.fn.system({ MISE, 'where', spec }))
  if vim.v.shell_error ~= 0 or root == '' then
    return nil
  end

  return root
end

return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    config = function()
      local java21_home = mise_where('java@21') or mise_where('java@lts')
      if not java21_home then
        vim.notify('jdtls 需要通过 mise 提供 Java 21+', vim.log.levels.ERROR)
        return
      end

      local java8_home = mise_where('java@corretto-8')
      local root_dir = vim.fs.root(0, {
        'build.gradle',
        'pom.xml',
        'settings.gradle',
        'gradlew',
        'mvnw',
        '.git',
      }) or vim.fn.getcwd()
      local project_name = vim.fs.basename(root_dir)
      local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name

      local config = {
        cmd = {
          'jdtls',
          '--java-executable',
          java21_home .. '/bin/java',
          '-data',
          workspace_dir,
        },
        root_dir = root_dir,
        settings = {
          java = {
            eclipse = {
              downloadSources = true,
            },
            maven = {
              downloadSources = true,
            },
            configuration = {
              runtimes = vim.tbl_filter(function(item)
                return item.path ~= nil
              end, {
                { name = 'JavaSE-1.8', path = java8_home },
                { name = 'JavaSE-21', path = java21_home },
              }),
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
        on_attach = function(_, bufnr)
          vim.keymap.set('n', '<leader>jo', ':JdtOverwrite<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Overwrite' })
          vim.keymap.set('n', '<leader>jc', ':JdtCompile<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Compile' })
          vim.keymap.set('n', '<leader>jr', ':JdtRestart<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Restart' })
          vim.keymap.set('n', '<leader>jd', ':JdtDebug<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Debug' })
          vim.keymap.set('n', '<leader>jt', ':JdtTest<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Test' })
          vim.keymap.set('n', '<leader>jR', ':JdtRefreshConfig<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Refresh Config' })

          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover' })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
        end,
      }

      require('jdtls').start_or_attach(config)
    end,
  },
}
