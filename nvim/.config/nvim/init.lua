vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local gh = function(repo)
	return "https://github.com/" .. repo
end

local cb = function(repo)
  return 'https://codeberg.org/' .. repo
end

vim.pack.add({
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("ibhagwan/fzf-lua") },
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("lewis6991/gitsigns.nvim") },
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("christoomey/vim-tmux-navigator") },
	{ src = gh("catppuccin/nvim") },
	{ src = gh("supermaven-inc/supermaven-nvim") },
	{ src = gh("kylechui/nvim-surround") },
	{ src = gh("nvim-mini/mini.ai") },
	{ src = cb("andyg/leap.nvim") },
}, { confirm = false })

require("core")
require("plugins")

-- Enable UI2
require('vim._core.ui2').enable()
