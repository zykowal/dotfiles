return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"mason-org/mason.nvim",
		"saghen/blink.cmp",
	},
	keys = {
		{ "<leader>le", desc = "Enable Mason LSP" },
		{ "<leader>lE", desc = "Disable Active LSP" },
		{ "<leader>li", desc = "Show Active LSPs" },
	},
	config = function()
		local map = vim.keymap.set

		local function has_value(list, value)
			return vim.tbl_contains(list or {}, value)
		end

		local function lsp_command_available(config)
			local cmd = config and config.cmd
			if type(cmd) == "function" then
				return true
			end
			if type(cmd) == "table" then
				cmd = cmd[1]
			end
			if type(cmd) ~= "string" or cmd == "" then
				return false
			end
			return vim.fn.executable(cmd) == 1
		end

		local function get_installed_mason_lsps()
			local ok, registry = pcall(require, "mason-registry")
			if not ok then
				vim.notify("mason-registry is not available", vim.log.levels.ERROR)
				return {}
			end

			local lsps = {}
			for _, pkg in ipairs(registry.get_installed_packages()) do
				if has_value(pkg.spec.categories, "LSP") then
					local names = pkg:get_aliases()
					if #names == 0 then
						names = { pkg.name }
					end

					for _, name in ipairs(names) do
						lsps[#lsps + 1] = {
							name = name,
							package = pkg.name,
						}
					end
				end
			end

			table.sort(lsps, function(a, b)
				return a.name < b.name
			end)

			return lsps
		end

		local function get_filetype_lsps(filetype)
			local lsps = {}
			local seen = {}

			for _, lsp in ipairs(get_installed_mason_lsps()) do
				local config = vim.lsp.config[lsp.name]
				if config and has_value(config.filetypes, filetype) then
					seen[lsp.name] = true
					lsps[#lsps + 1] = lsp
				end
			end

			for _, path in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
				local name = vim.fn.fnamemodify(path, ":t:r")
				local config = vim.lsp.config[name]
				if not seen[name] and config and has_value(config.filetypes, filetype) and lsp_command_available(config) then
					seen[name] = true
					lsps[#lsps + 1] = { name = name }
				end
			end

			table.sort(lsps, function(a, b)
				return a.name < b.name
			end)

			return lsps
		end

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

		local servers = {
			clangd = {
				root_markers = {
					"compile_commands.json",
					"compile_flags.txt",
					"configure.ac",
					"Makefile",
					"configure.in",
					"config.h.in",
					"meson.build",
					"meson_options.txt",
					"build.ninja",
					".git",
				},
				capabilities = {
					offsetEncoding = { "utf-16" },
				},
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
				},
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
				},
			},
		}

		vim.diagnostic.config({
			update_in_insert = false,
			severity_sort = true,
			virtual_text = false,
			virtual_lines = false,
			float = {
				border = "rounded",
				source = "if_many",
				header = "",
			},
			underline = { severity = vim.diagnostic.severity.ERROR },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = " ",
				},
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client then
					return
				end

				local opts = { buffer = args.buf, silent = true }
				map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
				map(
					"i",
					"<C-s>",
					vim.lsp.buf.signature_help,
					vim.tbl_extend("force", opts, { desc = "Signature help" })
				)
				map("n", "<leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))

				map("n", "[e", function()
					vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
				end, vim.tbl_extend("force", opts, { desc = "Previous error" }))

				map("n", "]e", function()
					vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
				end, vim.tbl_extend("force", opts, { desc = "Next error" }))

				if client:supports_method("textDocument/inlayHint") then
					map("n", "<leader>lh", function()
						vim.lsp.inlay_hint.enable(
							not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
							{ bufnr = args.buf }
						)
					end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
				end

				if client:supports_method("textDocument/semanticTokens/full") then
					map("n", "<leader>lT", function()
						vim.lsp.semantic_tokens.enable(
							not vim.lsp.semantic_tokens.is_enabled({ bufnr = args.buf }),
							{ bufnr = args.buf }
						)
					end, vim.tbl_extend("force", opts, { desc = "Toggle semantic tokens" }))
				end
			end,
		})

		map("n", "gl", vim.diagnostic.open_float, { desc = "Open diagnostic float" })

		for name, config in pairs(servers) do
			vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, config))
		end

		for _, lsp in ipairs(get_installed_mason_lsps()) do
			local config = servers[lsp.name] or {}
			vim.lsp.config(lsp.name, vim.tbl_deep_extend("force", { capabilities = capabilities }, config))
		end

		map("n", "<leader>le", function()
			local filetype = vim.bo.filetype
			if filetype == "" then
				vim.notify("Current buffer has no filetype", vim.log.levels.WARN)
				return
			end

			local lsps = get_filetype_lsps(filetype)
			if #lsps == 0 then
				vim.notify("No available LSP matches filetype: " .. filetype, vim.log.levels.WARN)
				return
			end

			vim.ui.select(lsps, {
				prompt = "Enable LSP for " .. filetype .. ":",
				format_item = function(item)
					return item.name
				end,
			}, function(item)
				if not item then
					return
				end
				local config = servers[item.name] or {}
				vim.lsp.config(item.name, vim.tbl_deep_extend("force", { capabilities = capabilities }, config))
				vim.lsp.enable(item.name)
				vim.notify("Enabled LSP: " .. item.name)
			end)
		end, { desc = "Enable Mason LSP" })

		map("n", "<leader>lE", function()
			local clients = vim.lsp.get_clients()
			if #clients == 0 then
				vim.notify("No active LSP clients", vim.log.levels.WARN)
				return
			end

			table.sort(clients, function(a, b)
				return a.name < b.name
			end)

			vim.ui.select(clients, {
				prompt = "Disable active LSP:",
				format_item = function(client)
					local root = client.root_dir or "no root"
					return string.format("%s [%d] %s", client.name, client.id, root)
				end,
			}, function(client)
				if not client then
					return
				end
				vim.lsp.enable(client.name, false)
				vim.notify("Disabled LSP: " .. client.name)
			end)
		end, { desc = "Disable Active LSP" })

		map("n", "<leader>li", function()
			local clients = vim.lsp.get_clients()
			if #clients == 0 then
				vim.notify("No active LSP clients", vim.log.levels.INFO)
				return
			end

			local lines = {}
			for _, client in ipairs(clients) do
				lines[#lines + 1] = string.format("%s [%d] %s", client.name, client.id, client.root_dir or "no root")
			end
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Active LSP clients" })
		end, { desc = "Show Active LSPs" })
	end,
}
