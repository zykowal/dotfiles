if true then
	return {}
end

return {
	"linux-cultist/venv-selector.nvim",
	keys = {
		{ "<Leader>lv", "<Cmd>VenvSelect<CR>", desc = "Select VirtualEnv" },
	},
	opts = {},
	cmd = "VenvSelect",
}
