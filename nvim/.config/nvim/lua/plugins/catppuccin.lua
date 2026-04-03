require("catppuccin").setup({
	transparent_background = true,
	term_colors = true,
	no_italic = true,
	no_bold = true,
	no_underline = true,
	float = {
		transparent = true,
		solid = false,
	},
	auto_integrations = true,
})

vim.cmd.colorscheme("catppuccin-nvim")
