-- Reuse Yazi's built-in fzf selection/navigation, changing only its file source.
local fzf = require("fzf")
local show_hidden = ya.sync(function()
	return cx.active.pref.show_hidden
end)

return {
	entry = function()
		local hidden = show_hidden()
		fzf.run_with = function(cwd, selected)
			local source = "fd --type f --exclude .git"
			if hidden then
				source = source .. " --hidden"
			end
			local child, err = Command("fzf")
				:arg("-m")
				:env("FZF_DEFAULT_COMMAND", source)
				:cwd(tostring(cwd))
				:stdin(#selected > 0 and Command.PIPED or Command.INHERIT)
				:stdout(Command.PIPED)
				:spawn()
			if not child then
				return nil, "Failed to start fzf: " .. tostring(err)
			end
			for _, url in ipairs(selected) do
				child:write_all(tostring(url) .. "\n")
			end
			if #selected > 0 then
				child:flush()
			end
			local output, wait_err = child:wait_with_output()
			if not output then
				return nil, "Cannot read fzf output: " .. tostring(wait_err)
			elseif not output.status.success and output.status.code ~= 130 then
				return nil, "fzf exited with code " .. tostring(output.status.code)
			end
			return output.stdout
		end
		fzf:entry()
	end,
}
