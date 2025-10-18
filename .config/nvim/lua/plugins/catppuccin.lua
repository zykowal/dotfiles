return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = true,
	priority = 1000,
	opts = {
		transparent_background = true,
		term_colors = true,
		float = {
			transparent = true,
			solid = false,
		},
		auto_integrations = true,
		integrations = {
			colorful_winsep = { color = "lavender" },
			snacks = {
				indent_scope_color = "lavender",
			},
		},
	},
}
