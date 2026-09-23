local M = {}

-- Apply imports before Conform formats and before the buffer reaches disk.
-- Use the attached client so edits use its negotiated position encoding.
function M.organize_imports(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })[1]
  if not client then
    return
  end

  local function request(method, params)
    local response, err = client:request_sync(method, params, 3000, bufnr)
    if not response or response.err then
      error("Go import organization failed: " .. vim.inspect(err or (response and response.err)))
    end
    return response.result
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = 0, character = 0 },
    },
    context = { only = { "source.organizeImports" }, diagnostics = {} },
  }
  for _, action in ipairs(request("textDocument/codeAction", params) or {}) do
    if not action.disabled then
      if not action.edit and not action.command
        and client:supports_method("codeAction/resolve") then
        action = request("codeAction/resolve", action)
      end
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
      if action.command then
        local command = type(action.command) == "table" and action.command or action
        request("workspace/executeCommand", command)
      end
    end
  end
end

return M
