return {
	"folke/sidekick.nvim",
	opts = {
		-- add any options here
		cli = {
			mux = {
				backend = "tmux",
				enabled = true,
			},
			tools = {},
		},
	},
	keys = {
		{
			"<tab>",
			function()
				-- if there is a next edit, jump to it, otherwise apply it if any
				if not require("sidekick").nes_jump_or_apply() then
					return "<Tab>" -- fallback to normal tab
				end
			end,
			expr = true,
			desc = "Goto/Apply Next Edit Suggestion",
		},
		{
			"<leader>tt",
			function()
				require("sidekick.cli").toggle({})
			end,
			desc = "Sidekick Toggle CLI",
		},
		{
			"<leader>ts",
			function()
				require("sidekick.cli").send({ msg = "{this}", focus = true })
			end,
			mode = { "x", "n" },
			desc = "Send This",
		},
		{
			"<leader>tf",
			function()
				require("sidekick.cli").send({ msg = "{file}", focus = true })
			end,
			desc = "Send File",
		},
		{
			"<leader>tp",
			function()
				require("sidekick.cli").prompt({ focus = true })
			end,
			mode = { "n", "x" },
			desc = "Sidekick Select Prompt",
		},
		{
			"<leader>tn",
			function()
				require("sidekick.cli").select()
			end,
			-- Or to select only installed tools:
			-- require("sidekick.cli").select({ filter = { installed = true } })
			desc = "Select CLI",
		},
		{
			"<leader>tx",
			function()
				require("sidekick.cli").close()
			end,
			desc = "Detach a CLI Session",
		},
	},
}
