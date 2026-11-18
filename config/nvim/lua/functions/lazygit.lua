local M = {}
local origin, terminal

function M.config()
	local source = debug.getinfo(1, "S").source:sub(2)
	local helper = vim.fn.fnamemodify(source, ":h") .. "/lazygit-edit.lua"
	-- LazyGit shell-quotes {{filename}}. Pass it as an argument, never as Lua/Ex code.
	local command = vim.fn.shellescape(vim.v.progpath)
		.. " --headless -u NONE -i NONE -l "
		.. vim.fn.shellescape(helper)
		.. ' "$NVIM" {{filename}}'
	return {
		enabled = true,
		config = {
			os = {
				edit = command,
				editAtLine = command .. " {{line}}",
				editInTerminal = false,
			},
		},
	}
end

function M.open()
	-- Toggling an already-focused floating terminal must not replace the editor origin.
	local win = vim.api.nvim_get_current_win()
	if vim.api.nvim_win_get_config(win).relative == "" then
		origin = win
	end
	terminal = require("snacks").lazygit()
end

function M.edit(file, line)
	if not origin or not vim.api.nvim_win_is_valid(origin) then
		error("The original Lazygit editor window was closed; reopen Lazygit from an editor window")
	end
	if terminal then
		terminal:hide()
	end
	vim.api.nvim_set_current_win(origin)
	-- Use normal :edit semantics to preserve protection for unsaved buffers.
	vim.cmd.edit(vim.fn.fnameescape(file))
	if line then
		local last = vim.api.nvim_buf_line_count(0)
		vim.api.nvim_win_set_cursor(0, { math.max(1, math.min(tonumber(line) or 1, last)), 0 })
		vim.cmd("normal! zvzz")
	end
	return true
end

return M
