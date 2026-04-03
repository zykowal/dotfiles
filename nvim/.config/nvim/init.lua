vim.g.mapleader = " "
vim.g.maplocalleader = " "

local gh = function(repo)
	return "https://github.com/" .. repo
end

vim.pack.add({
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("ibhagwan/fzf-lua") },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("lewis6991/gitsigns.nvim") },
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("j-hui/fidget.nvim") },
	{ src = gh("christoomey/vim-tmux-navigator") },
	{ src = gh("catppuccin/nvim") },
	{ src = gh("supermaven-inc/supermaven-nvim") },
}, { confirm = false })

require("core")
require("plugins")
