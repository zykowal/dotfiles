return {
	"MeanderingProgrammer/render-markdown.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
	cmd = "RenderMarkdown",
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		completions = { lsp = { enabled = true } },
		file_types = { "markdown", "md", "codecompanion" },
		latex = { enabled = false },
	},
}
