return {
  'mfussenegger/nvim-lint',
  config = function()
    local lint = require("lint")

    -- 查找项目本地的 eslint 或 eslint_d
    local function find_eslint_cmd(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      if filepath == "" then
        return "eslint_d"
      end

      local dir = vim.fn.fnamemodify(filepath, ":h")
      local function find_in_dir(d)
        -- 查找 node_modules/.bin/eslint_d 或 eslint
        local eslint_d_path = d .. "/node_modules/.bin/eslint_d"
        local eslint_path = d .. "/node_modules/.bin/eslint"
        
        if vim.fn.executable(eslint_d_path) == 1 then
          return eslint_d_path
        elseif vim.fn.executable(eslint_path) == 1 then
          return eslint_path
        end
        
        -- 向上查找
        local parent = vim.fn.fnamemodify(d, ":h")
        if parent == d then
          return nil
        end
        return find_in_dir(parent)
      end
      
      local local_cmd = find_in_dir(dir)
      if local_cmd then
        return local_cmd
      end
      
      -- 回退到全局命令
      if vim.fn.executable("eslint_d") == 1 then
        return "eslint_d"
      elseif vim.fn.executable("eslint") == 1 then
        return "eslint"
      end
      
      return "eslint_d"
    end

    -- 自定义 eslint_d 配置，确保在 monorepo 中能正确找到配置文件
    lint.linters.eslint_d = {
      cmd = "eslint_d",
      stdin = true,
      args = { "--stdin", "--stdin-filename", "%filepath", "--format", "json" },
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output, bufnr)
        if not output or output == "" then
          return {}
        end
        
        local ok, decoded = pcall(vim.json.decode, output)
        if not ok then
          return {}
        end
        
        if not decoded or type(decoded) ~= "table" or not decoded[1] or not decoded[1].messages then
          return {}
        end

        local diagnostics = {}
        for _, message in ipairs(decoded[1].messages) do
          table.insert(diagnostics, {
            lnum = (message.line or 1) - 1,
            col = (message.column or 1) - 1,
            end_lnum = (message.endLine or message.line or 1) - 1,
            end_col = (message.endColumn or message.column or 1) - 1,
            severity = message.severity == 2 and vim.diagnostic.severity.ERROR
                or message.severity == 1 and vim.diagnostic.severity.WARN
                or vim.diagnostic.severity.INFO,
            message = message.message or "",
            source = "eslint",
            code = message.ruleId,
          })
        end
        
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "pylint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- 包装 try_lint 以确保 cmd 在调用前被设置
    local function safe_try_lint()
      local bufnr = vim.api.nvim_get_current_buf()
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local ft = vim.bo[bufnr].filetype
      
      -- 只对 JS/TS 文件进行 lint
      if filepath ~= "" and (ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact") then
        local cmd = find_eslint_cmd(bufnr)
        if vim.fn.executable(cmd) == 1 then
          -- 重新创建 linter 配置以确保使用正确的 cmd
          lint.linters.eslint_d = {
            cmd = cmd,
            stdin = true,
            args = { "--stdin", "--stdin-filename", filepath, "--format", "json" },
            stream = "stdout",
            ignore_exitcode = true,
            parser = function(output, bufnr)
              if not output or output == "" then
                return {}
              end
              
              local ok, decoded = pcall(vim.json.decode, output)
              if not ok then
                return {}
              end
              
              if not decoded or type(decoded) ~= "table" or not decoded[1] or not decoded[1].messages then
                return {}
              end

              local diagnostics = {}
              for _, message in ipairs(decoded[1].messages) do
                -- 处理行号：如果没有行号或行号为 0，使用第 1 行（索引 0）以便显示
                local line = message.line
                if line and line > 0 then
                  line = line - 1  -- 转换为 0-based
                else
                  line = 0  -- 文件级别的错误显示在第 1 行
                end
                
                -- 处理列号：如果没有列号，使用 0
                local col = message.column
                if col and col > 0 then
                  col = col - 1  -- 转换为 0-based
                else
                  col = 0
                end
                
                -- 处理结束位置
                local end_line = message.endLine or message.line
                if end_line and end_line > 0 then
                  end_line = end_line - 1
                else
                  end_line = line
                end
                
                local end_col = message.endColumn or message.column
                if end_col and end_col > 0 then
                  end_col = end_col - 1
                else
                  end_col = col
                end
                
                table.insert(diagnostics, {
                  lnum = line,
                  col = col,
                  end_lnum = end_line,
                  end_col = end_col,
                  severity = message.severity == 2 and vim.diagnostic.severity.ERROR
                      or message.severity == 1 and vim.diagnostic.severity.WARN
                      or vim.diagnostic.severity.INFO,
                  message = message.message or "",
                  source = "eslint",
                  code = message.ruleId,
                })
              end
              
              return diagnostics
            end,
          }
        else
          vim.notify("ESLint not found: " .. cmd, vim.log.levels.WARN)
          return
        end
      end
      
      lint.try_lint()
    end

    -- 确保诊断显示已启用（全局配置）
    -- 使用 VimEnter 事件确保在其他配置加载后执行
    vim.api.nvim_create_autocmd("VimEnter", {
      group = lint_augroup,
      once = true,
      callback = function()
        -- 全局诊断配置
        vim.diagnostic.config({
          virtual_text = {
            source = "always",
            prefix = "●",
            spacing = 4,
            format = function(diagnostic)
              local msg = diagnostic.message
              -- 移除换行符，只取第一行
              msg = msg:match("^[^\n]+") or msg
              -- 截断过长的消息（限制在 80 字符）
              if #msg > 80 then
                msg = msg:sub(1, 77) .. "..."
              end
              -- 对于 TypeScript 类型错误，尝试提取关键信息
              if msg:match("is not assignable to type") then
                -- 提取类型名称，而不是显示整个联合类型
                local type_match = msg:match("to type '([^']+)'")
                if type_match and #type_match > 50 then
                  -- 如果是很长的联合类型，只显示前几个类型
                  local types = {}
                  for t in type_match:gmatch("([^|]+)") do
                    t = t:match("^%s*(.-)%s*$") -- 去除首尾空格
                    if t and t ~= "" then
                      table.insert(types, t)
                      if #types >= 3 then
                        break
                      end
                    end
                  end
                  if #types > 0 then
                    local short_type = table.concat(types, " | ")
                    if #short_type > 50 then
                      short_type = short_type:sub(1, 47) .. "..."
                    end
                    msg = msg:gsub("to type '[^']+'", "to type '" .. short_type .. "...'")
                  end
                end
              end
              return string.format("%s %s", "●", msg)
            end,
          },
          float = {
            source = "always",
            border = "rounded",
            focusable = false, -- 浮动窗口不可聚焦，使用 Trouble 或 location list 查看完整诊断
            format = function(diagnostic)
              -- 浮动窗口显示完整信息，但格式化长类型
              local msg = diagnostic.message
              -- 对于 TypeScript 类型错误，尝试格式化显示
              if msg:match("is not assignable to type") then
                -- 将长类型分成多行显示
                msg = msg:gsub(" | ", " |\n  ")
                -- 如果类型太长，添加换行
                msg = msg:gsub("to type '([^']+)'", function(type_str)
                  if #type_str > 100 then
                    -- 将长类型分成多行
                    type_str = type_str:gsub(" | ", " |\n    ")
                    return "to type:\n    " .. type_str .. "'"
                  end
                  return "to type '" .. type_str .. "'"
                end)
              end
              return msg
            end,
            max_width = math.floor(vim.o.columns * 0.8), -- 浮动窗口最大宽度为屏幕的 80%
            max_height = math.floor(vim.o.lines * 0.5),  -- 浮动窗口最大高度为屏幕的 50%
          },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = "●",
              [vim.diagnostic.severity.WARN] = "●",
              [vim.diagnostic.severity.INFO] = "●",
              [vim.diagnostic.severity.HINT] = "●",
            },
          },
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = safe_try_lint,
    })

    vim.keymap.set("n", "<leader>lf", safe_try_lint, { desc = "Trigger linting for current file" })
    
    -- 添加测试命令：显示所有诊断
    vim.api.nvim_create_user_command("LintShowDiagnostics", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local diags = vim.diagnostic.get(bufnr)
      if #diags == 0 then
        vim.notify("No diagnostics found", vim.log.levels.INFO)
        return
      end
      
      vim.notify("Found " .. #diags .. " diagnostics", vim.log.levels.INFO)
      for i, diag in ipairs(diags) do
        vim.notify(string.format("Diagnostic %d: line=%d, col=%d, severity=%d, source=%s", 
          i, diag.lnum, diag.col, diag.severity, diag.source or "unknown"), vim.log.levels.INFO)
      end
      
      -- 尝试打开第一个诊断的浮动窗口
      if diags[1] then
        vim.diagnostic.open_float(bufnr, {
          scope = "cursor",
          source = "always",
        })
      end
    end, { desc = "Show all diagnostics and open float window" })
  end,
}
