local map = vim.keymap.set

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
})

map("n", "<leader>lf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
