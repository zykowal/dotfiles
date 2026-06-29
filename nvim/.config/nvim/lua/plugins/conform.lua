return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
      mode = {"n", "v"},
			desc = "Format buffer",
		},
	},
	opts = {
		notify_on_error = false,
		formatters_by_ft = {
			lua = { "stylua" },
		},
		format_on_save = nil,
	},
}
