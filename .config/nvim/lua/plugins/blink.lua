local function has_words_before()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

return {
	"saghen/blink.cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	opts_extend = { "sources.default", "cmdline.sources", "term.sources" },
	-- optional: provides snippets for the snippet source
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			version = "2.*",
			build = (function()
				-- Build Step is needed for regex support in snippets.
				-- This step is not supported in many windows environments.
				-- Remove the below condition to re-enable on windows.
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				-- `friendly-snippets` contains a variety of premade snippets.
				--    See the README about individual language/framework/plugin snippets:
				--    https://github.com/rafamadriz/friendly-snippets
				{
					"rafamadriz/friendly-snippets",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
				},
			},
			opts = {},
		},
	},

	-- use a release tag to download pre-built binaries
	version = "1.*",
	-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	-- If you use nix, you can build from source using latest nightly rust with:
	-- build = 'nix run .#build-plugin',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
		-- 'super-tab' for mappings similar to vscode (tab to accept)
		-- 'enter' for enter to accept
		-- 'none' for no mappings
		--
		-- All presets have the following mappings:
		-- C-space: Open menu or open docs if already open
		-- C-n/C-p or Up/Down: Select next/previous item
		-- C-e: Hide menu
		-- C-k: Toggle signature help (if signature.enabled = true)
		--
		-- See :h blink-cmp-config-keymap for defining your own keymap
		keymap = {
			["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-N>"] = { "select_next", "show" },
			["<C-P>"] = { "select_prev", "show" },
			["<C-J>"] = { "select_next", "fallback" },
			["<C-K>"] = { "select_prev", "fallback" },
			["<C-U>"] = { "scroll_documentation_up", "fallback" },
			["<C-D>"] = { "scroll_documentation_down", "fallback" },
			["<C-e>"] = { "hide", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<C-l>"] = { "accept", "fallback" },
			["<Tab>"] = {
				"select_next",
				"snippet_forward",
				function(cmp)
					if has_words_before() or vim.api.nvim_get_mode().mode == "c" then
						return cmp.show()
					end
				end,
				"fallback",
			},
			["<S-Tab>"] = {
				"select_prev",
				"snippet_backward",
				function(cmp)
					if vim.api.nvim_get_mode().mode == "c" then
						return cmp.show()
					end
				end,
				"fallback",
			},
		},

		cmdline = {
			keymap = {
				["<Tab>"] = { "show", "accept" },
				["<S-Tab>"] = { "show_and_insert", "select_prev" },

				["<C-N>"] = { "select_next", "show" },
				["<C-P>"] = { "select_prev", "show" },
				["<C-J>"] = { "select_next", "fallback" },
				["<C-K>"] = { "select_prev", "fallback" },

				["<C-Y>"] = { "select_and_accept" },
				["<C-E>"] = { "cancel" },
			},
			completion = { menu = { auto_show = true }, ghost_text = { enabled = false } },
		},

		appearance = {
			-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
			-- Adjusts spacing to ensure icons are aligned
			nerd_font_variant = "normal",
		},

		-- (Default) Only show the documentation popup when manually triggered
		completion = {
			list = { selection = { preselect = false, auto_insert = true } },
			menu = {
				border = "none",
				scrollbar = false,
				draw = {
					treesitter = { "lsp" },
					columns = { { "label", "label_description", gap = 1 }, { "kind", gap = 1 } },
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 0,
				window = {
					border = "rounded",
					scrollbar = false,
				},
			},
		},
		signature = {
			enabled = true,
			window = {
				border = "none",
				show_documentation = false,
			},
		},

		-- Default list of enabled providers defined so that you can extend it
		-- elsewhere in your config, without redefining it, due to `opts_extend`
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		snippets = { preset = "luasnip" },

		-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
		-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
		-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
		--
		-- See the fuzzy documentation for more information
		fuzzy = { implementation = "prefer_rust" },
	},
}
