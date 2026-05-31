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

local function glob_jars(pattern)
  return vim.fn.glob(pattern, true, true)
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
      local project_hash = vim.fn.sha256(root_dir):sub(1, 8)
      local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name .. '-' .. project_hash
      local mason_path = vim.fn.stdpath('data') .. '/mason/packages'
      local bundles = {}
      vim.list_extend(bundles, glob_jars(mason_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'))
      vim.list_extend(bundles, glob_jars(mason_path .. '/java-test/extension/server/*.jar'))

      local config = {
        cmd = {
          'jdtls',
          '--java-executable',
          java21_home .. '/bin/java',
          '-data',
          workspace_dir,
        },
        root_dir = root_dir,
        init_options = {
          bundles = bundles,
        },
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
          local jdtls = require('jdtls')

          vim.keymap.set('n', '<leader>ji', jdtls.organize_imports, { buffer = bufnr, desc = 'Java Organize Imports' })
          vim.keymap.set('n', '<leader>jv', jdtls.extract_variable, { buffer = bufnr, desc = 'Java Extract Variable' })
          vim.keymap.set('v', '<leader>jv', function()
            jdtls.extract_variable({ visual = true })
          end, { buffer = bufnr, desc = 'Java Extract Variable' })
          vim.keymap.set('n', '<leader>jV', jdtls.extract_variable_all, { buffer = bufnr, desc = 'Java Extract Variable All' })
          vim.keymap.set('n', '<leader>jC', jdtls.extract_constant, { buffer = bufnr, desc = 'Java Extract Constant' })
          vim.keymap.set('v', '<leader>jC', function()
            jdtls.extract_constant({ visual = true })
          end, { buffer = bufnr, desc = 'Java Extract Constant' })
          vim.keymap.set('v', '<leader>jm', function()
            jdtls.extract_method({ visual = true })
          end, { buffer = bufnr, desc = 'Java Extract Method' })
          vim.keymap.set('n', '<leader>js', jdtls.extended_symbols, { buffer = bufnr, desc = 'Java Extended Symbols' })
          vim.keymap.set('n', '<leader>jtc', jdtls.test_class, { buffer = bufnr, desc = 'Java Test Class' })
          vim.keymap.set('n', '<leader>jtn', jdtls.test_nearest_method, { buffer = bufnr, desc = 'Java Test Nearest Method' })
          vim.keymap.set('n', '<leader>jdc', function()
            require('jdtls.dap').setup_dap_main_class_configs({ verbose = true })
          end, { buffer = bufnr, desc = 'Java Discover Main Classes' })
          vim.keymap.set('n', '<leader>jc', ':JdtCompile<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Compile' })
          vim.keymap.set('n', '<leader>jr', ':JdtRestart<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Restart' })
          vim.keymap.set('n', '<leader>jR', ':JdtUpdateConfig<CR>', { buffer = bufnr, silent = true, desc = 'Jdt Update Config' })

          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to definition' })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover' })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
        end,
      }

      require('jdtls').start_or_attach(config)
    end,
  },
}
