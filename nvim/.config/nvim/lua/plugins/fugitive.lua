return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G", "GBrowse" },
	keys = {
		{ "<C-g>s", "<cmd>Git<cr>", desc = "Git status" },
		{ "<C-g>l", "<cmd>Git log --oneline --decorate --graph<cr>", desc = "Git log" },
		{ "<C-g>P", "<cmd>Git push<cr>", desc = "Git push" },
		{ "<C-g>p", "<cmd>Git pull<cr>", desc = "Git pull" },
		{ "<C-g>c", "<cmd>Git commit<cr>", desc = "Git commit" },
		{ "<C-g>w", "<cmd>Gwrite<cr>", desc = "Git add current file" },
    { "<C-g>a", "<cmd>Git add --all<cr>", desc = "Git add all" },
    { "<C-g>f", "<cmd>Git fetch --all --prune<cr>", desc = "Git fetch" },
	},
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"fugitive", "git"},
      callback = function()
        vim.keymap.set("n", "o", "<CR>", {
          buffer = true,
          remap = true,
          desc = "Fugitive open",
        })
      end,
    })
  end,
}
