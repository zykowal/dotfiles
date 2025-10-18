return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		notify_on_error = false,
		formatters_by_ft = {
			lua = { "stylua" },

			-- python
			-- python = { "ruff_organize_imports", "ruff_format", "ruff", lsp_format = "fallback" },
			-- toml = { "taplo", "taplo_format", lsp_format = "fallback" },

			-- golang
			-- go = { "goimports", "gofumpt", lsp_format = "last" },

			-- c/cpp
			-- c = { "clang-format" },
			-- cpp = { "clang-format" },

			-- js/ts
			-- javascript = { "prettierd", lsp_format = "fallback" },
			-- typescript = { "prettierd", lsp_format = "fallback" },
			-- javascriptreact = { "prettierd", lsp_format = "fallback" },
			-- typescriptreact = { "prettierd", lsp_format = "fallback" },
			-- json = { "prettierd", lsp_format = "fallback" },
		},
		format_on_save = function(bufnr)
			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			local disable_filetypes = {} -- { c = true, cpp = true  }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
	},
}
