require("mason").setup({
	ui = {
		border = "none",
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

vim.keymap.set("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason" })

local map = vim.keymap.set
local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
	capabilities = capabilities,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		map("n", "K", vim.lsp.buf.hover, opts)
		map("n", "<leader>lr", vim.lsp.buf.rename, opts)
		map("n", "<leader>rr", vim.lsp.codelens.run, opts)
		map("n", "<leader>rR", vim.lsp.codelens.refresh, opts )
	end,
})

-- Lua
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			hint = {
				enable = true,
				arrayIndex = "Disable",
			},
			diagnostics = {
				globals = { "vim" },
			},
			telemetry = {
				enable = false,
			},
			workspace = {
				checkThirdParty = false,
			},
		},
	},
})
