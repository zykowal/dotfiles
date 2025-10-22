return {
	"mikavilpas/yazi.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = {
		{ "nvim-lua/plenary.nvim", lazy = true },
	},
	opts = {
		open_for_directories = true,
		open_multiple_tabs = true,
		floating_window_scaling_factor = 0.85,
		keymaps = {
			show_help = "<f1>",
			open_file_in_vertical_split = "<c-v>",
			open_file_in_horizontal_split = "<c-s>",
			change_working_directory = "<c-e>",
		},
	},
	keys = {
		{ "<Leader>e", "<cmd>Yazi<cr>", desc = "Explorer" },
		{ "<Leader>o", "<cmd>Yazi cwd<cr>", desc = "Explorer (Cwd)" },
	},
	init = function()
		vim.g.loaded_netrwPlugin = 1
	end,
}
