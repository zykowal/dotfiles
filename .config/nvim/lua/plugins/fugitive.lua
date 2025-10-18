return {
	"tpope/vim-fugitive",
	event = "BufRead",
	dependencies = {
		"linrongbin16/gitlinker.nvim",
		event = "BufRead",
		keys = {
			{ "<leader>gy", "<Cmd>GitLink<CR>", mode = { "n", "v" }, desc = "Git link copy" },
			{ "<leader>go", "<Cmd>GitLink!<CR>", mode = { "n", "v" }, desc = "Git link open" },
		},
		opts = {},
	},
	config = function()
		vim.api.nvim_create_user_command("GBrowse", function()
			vim.cmd("GitLink!")
		end, {})
	end,
	keys = {
		{ "<leader>gf", "<cmd>Git<cr>", desc = "View full Git blame" },
		{ "<leader>gL", "<cmd>Git blame<cr>", desc = "View full Git blame" },
	},
}
