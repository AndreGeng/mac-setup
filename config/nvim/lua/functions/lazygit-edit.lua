-- Invoked by LazyGit as a clean headless Neovim client. RPC arguments keep filenames
-- separate from executable Lua/Ex code, including quotes and shell metacharacters.
local server, file, line = arg[1], arg[2], tonumber(arg[3])
assert(server and server ~= "", "Lazygit edit requires the parent Neovim server")
assert(file and file ~= "", "Lazygit edit requires a filename")
local channel = vim.fn.sockconnect("pipe", server, { rpc = true })
assert(channel > 0, "Could not connect to the parent Neovim")
local path = vim.fn.fnamemodify(file, ":p")
local args = { path }
if line then
	args[2] = line
end
vim.rpcrequest(channel, "nvim_exec_lua", "return require('functions.lazygit').edit(...)", args)
vim.fn.chanclose(channel)
