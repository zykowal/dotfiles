return {
	{
		"linrongbin16/gitlinker.nvim",
		event = "BufRead",
		keys = {
			{ "<leader>gy", "<Cmd>GitLink<CR>", mode = { "n", "v" }, desc = "Git link copy" },
			{ "<leader>go", "<Cmd>GitLink!<CR>", mode = { "n", "v" }, desc = "Git link open" },
		},
		opts = {},
	},
}
