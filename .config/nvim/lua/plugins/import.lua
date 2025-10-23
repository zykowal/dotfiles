return {
	"piersolenski/import.nvim",
	event = "BufRead",
	dependencies = {
		"ibhagwan/fzf-lua",
	},
	opts = {
		picker = "fzf-lua",
	},
	keys = {
		{
			"<leader>fi",
			function()
				require("import").pick()
			end,
			desc = "Import",
		},
	},
}
