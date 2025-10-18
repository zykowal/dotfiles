return {
	"vimwiki/vimwiki",
	lazy = true,
	cmd = {
		"VimwikiIndex",
		"VimwikiMakeDiaryNote",
		"VimwikiDeleteFile",
		"VimwikiRenameFile",
		"VimwikiFollowLink",
		"VimwikiGoBackLink",
	},
	keys = {
		{ "<leader>ni", "<cmd>VimwikiIndex<CR>", desc = "Open wiki index" },
		{ "<leader>nd", "<cmd>VimwikiMakeDiaryNote<CR>", desc = "Make diary note" },
		{ "<leader>nx", "<cmd>VimwikiDeleteFile<CR>", desc = "Delete wiki file" },
		{ "<leader>nr", "<cmd>VimwikiRenameFile<CR>", desc = "Rename wiki file" },
		{ "<leader>nl", "<cmd>VimwikiFollowLink<CR>", desc = "Follow link" },
		{ "<leader>nh", "<cmd>VimwikiGoBackLink<CR>", desc = "Go back" },
	},
	init = function()
		vim.g.vimwiki_list = {
			{
				path = "~/notes",
				syntax = "markdown",
				ext = ".md",
			},
		}
		vim.g.vimwiki_key_mappings = { all_maps = 0 }
		vim.g.vimwiki_markdown_link_ext = 1
	end,
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "vimwiki",
			callback = function()
				vim.bo.filetype = "markdown"
			end,
		})
	end,
}
