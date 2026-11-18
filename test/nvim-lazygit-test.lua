local root = assert(vim.env.TEST_ROOT)
vim.opt.rtp:prepend(root .. "/config/nvim")
local dir = assert(vim.uv.fs_realpath(assert(vim.env.TEST_TMP)))
local file = dir .. "/space 中文 %20 ' |file.txt"
vim.fn.writefile({ "first", "second", "third" }, file)
local lazygit = require("functions.lazygit")
local hidden = 0
package.loaded.snacks = {
	lazygit = function()
		return {
			hide = function()
				hidden = hidden + 1
			end,
		}
	end,
}

vim.cmd.vsplit()
vim.cmd.split()
local origin = vim.api.nvim_get_current_win()
local windows = #vim.api.nvim_list_wins()
local tabs = #vim.api.nvim_list_tabpages()
lazygit.open()
vim.cmd.wincmd("w")
lazygit.edit(file, 2)
assert(vim.api.nvim_get_current_win() == origin, "did not return to original window")
assert(
	vim.api.nvim_buf_get_name(0) == file,
	"special filename was changed: " .. vim.inspect({ vim.api.nvim_buf_get_name(0), file })
)
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "line number was lost")
assert(#vim.api.nvim_list_wins() == windows and #vim.api.nvim_list_tabpages() == tabs)
assert(hidden == 1)

-- A later invocation must remember its own origin, including an already-open file.
vim.cmd.wincmd("w")
local next_origin = vim.api.nvim_get_current_win()
lazygit.open()
lazygit.edit(file)
assert(vim.api.nvim_get_current_win() == next_origin)

-- Use the actual shell command and a second Neovim process to exercise RPC and quoting.
local server = vim.fn.serverstart(dir .. "/nvim.sock")
local config = lazygit.config().config.os
local command = config.editAtLine:gsub("{{filename}}", function()
	return vim.fn.shellescape(file)
end)
command = command:gsub("{{line}}", "3")
local done, status = false, nil
vim.fn.jobstart({ "sh", "-c", command }, {
	env = { NVIM = server },
	on_exit = function(_, code)
		done, status = true, code
	end,
})
assert(
	vim.wait(10000, function()
		return done
	end, 20),
	"RPC helper timed out"
)
assert(status == 0, "RPC helper failed")
assert(vim.api.nvim_get_current_win() == next_origin)
assert(vim.api.nvim_buf_get_name(0) == file)
assert(vim.api.nvim_win_get_cursor(0)[1] == 3)
assert(#vim.api.nvim_list_wins() == windows and #vim.api.nvim_list_tabpages() == tabs)

-- Closing the origin must not redirect an edit into an unrelated window.
vim.api.nvim_win_close(next_origin, true)
local ok = pcall(lazygit.edit, file)
assert(not ok, "closed origin should reject the edit")
print("PASS Lazygit editing preserves original window, layout, filenames and line numbers")
