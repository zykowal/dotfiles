if true then
	return {}
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		explorer = { enabled = false },
		bigfile = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		toggle = {
			which_key = false,
		},
		notifier = {
			enabled = true,
			timeout = 3000,
			style = "minimal",
			top_down = false,
		},
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		styles = {
			scratch = {
				width = 0.75,
				height = 0.75,
			},
		},
		zen = {
			toggles = {
				dim = false,
				git_signs = false,
				mini_diff_signs = false,
				diagnostics = true,
				inlay_hints = true,
			},
			win = {
				min_width = 140,
				wo = {
					relativenumber = true,
					number = true,
					spell = false,
					signcolumn = "yes",
				},
			},
		},
		picker = {
			enabled = true,
			hidden = true,
			ignored = true,
			layout = "custom_bottom",
			matcher = {
				frecency = true,
			},
			win = {
				input = {
					keys = {
						["o"] = { "confirm", mode = { "n" } },
						["J"] = { "preview_scroll_down", mode = { "n" } },
						["K"] = { "preview_scroll_up", mode = { "n" } },
						["H"] = { "preview_scroll_left", mode = { "n" } },
						["L"] = { "preview_scroll_right", mode = { "n" } },
					},
				},
			},
			layouts = {
				custom_bottom = {
					layout = {
						box = "vertical",
						backdrop = false,
						row = -1,
						width = 0,
						height = 0.5,
						border = "none",
						title = " {title} {live} {flags}",
						title_pos = "left",
						{
							box = "horizontal",
							{ win = "list", border = "rounded" },
							{ win = "preview", title = "{preview}", border = "rounded", width = 0.618 },
						},
						{ win = "input", height = 1, border = "none" },
					},
				},

				default = {
					layout = {
						box = "horizontal",
						width = 0.85,
						min_width = 120,
						height = 0.85,
						{
							box = "vertical",
							border = "rounded",
							title = "{title} {live} {flags}",
							{ win = "input", height = 1, border = "bottom" },
							{ win = "list", border = "none" },
						},
						{ win = "preview", title = "{preview}", border = "rounded", width = 0.618 },
					},
				},

				vertical = {
					layout = {
						backdrop = false,
						width = 0.6,
						min_width = 100,
						height = 0.8,
						min_height = 30,
						box = "vertical",
						border = "rounded",
						title = "{title} {live} {flags}",
						title_pos = "center",
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
						{ win = "preview", title = "{preview}", height = 0.495, border = "top" },
					},
				},

				vscode = {
					preview = false,
					layout = {
						backdrop = false,
						width = 0.4,
						min_width = 80,
						height = 0.647,
						border = "none",
						box = "vertical",
						{
							box = "vertical",
							border = "rounded",
							title = "{title} {live} {flags}",
							title_pos = "left",
							{ win = "list", border = "none" },
							{ win = "input", height = 1, border = "top" },
						},
						{ win = "preview", title = "{preview}", border = "rounded" },
					},
				},

				ivy = {
					layout = {
						box = "vertical",
						backdrop = false,
						row = -1,
						width = 0,
						height = 0.5,
						border = "top",
						title = " {title} {live} {flags}",
						title_pos = "left",
						{ win = "input", height = 1, border = "bottom" },
						{
							box = "horizontal",
							{ win = "list", border = "none" },
							{ win = "preview", title = "{preview}", width = 0.618, border = "left" },
						},
					},
				},
			},
		},
		dashboard = {
			preset = {
				header = table.concat({
					"                                                                                  ",
					"                                                                                  ",
					"                      *((##*                                                      ",
					"                  /###%%#%&&&%,                           .%((//(/.               ",
					"                  #%%&&&&@@@@@@@*                        #%#&%@&%%##%%            ",
					"                 &&&@@@@@@@@@@@@@   .**(/(,*,/,*,       &@@@@@@@@@&&%%%*          ",
					"                 @@@@@@@@@@&@*                         %@@@@@@@@@@@@&&&&          ",
					"                  @@@@%/,               ,                 /@&%@@@@@@@&&&*         ",
					"                   &@,                 .                      /%@@@@@@@&.         ",
					"                .(..                  ,                         *#@@@@@#          ",
					"              .(                                                 .@@@@*           ",
					"              #                                                    (              ",
					"             ,             *%@%             .@@@@&*                 ,             ",
					"          *            /@@@@@@&            @@@@@@@@&                .*            ",
					"          ,            @@@@@@@@,   ...  .   .@@@@@@@@@                 /          ",
					"          /           @@@@@@/                  *&@@@@@&                           ",
					"         /           ,@&@@@.    %@@@@@@@@@,     .#@@@&&                 ,         ",
					"         #            (%%%/    *@@@@@@@@@%*      *&%#(*                 /         ",
					"         *        .     .           /                   , .,.                     ",
					"          .                /                     *                      *         ",
					"          *                #.    ./%,%/.      ,%                       /..        ",
					"          .,                                                        ,,*  *        ",
					"            %*                                 (%%#%%(,          *&*..    ,       ",
					"           ,/**#@%,**         ........ ...    #&&&@&&&%%%&(,#@@@@@&##%(%%#,,.     ",
					"          .%@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@(@@@@@@&&@@%&%%&&&#@@@@@@@@&&&%(,    ",
					"          (%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@@@@@@@@@@@&&%&@%&@@@@@@@@@%#,   ",
					"        *&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@&%&&*&@@@@@@&&#.  ",
					"        &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@&@@@&&(@@@@@@&%* ",
					"      .#@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@%@@@(@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@##@@@@#.",
					"      /@@@@@@@@@@@%%&%@&##%&#%/(@(&#%%###%&%@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/",
					"     @@@@@@@@@@%((/((**,.,,,,*,,.,*.*.,*,,,,.. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/",
					"    .@@@@@@@@@/.*   .                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(",
				}, "\n"),
			},
			sections = {
				{ section = "header", padding = 5 },
				{ section = "startup" },
			},
		},
	},
	keys = {
		-- Top Pickers & Explorer
		{
			"<leader>fs",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>fw",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>fn",
			function()
				Snacks.picker.notifications()
			end,
			desc = "Notification History",
		},
		-- find
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fa",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find Config File",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.git_files()
			end,
			desc = "Find Git Files",
		},
		{
			"<leader>fp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent",
		},
		-- git
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Git Branches",
		},
		{
			"<leader>gc",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git Log (repo)",
		},
		{
			"<leader>gC",
			function()
				Snacks.picker.git_log_file()
			end,
			desc = "Git Log File",
		},
		{
			"<leader>gf",
			function()
				Snacks.picker.git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>gt",
			function()
				Snacks.picker.git_stash()
			end,
			desc = "Git Stash",
		},
		-- Grep
		{
			"<leader>fl",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer Lines",
		},
		{
			"<leader>fB",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep Open Buffers",
		},
		{
			"<leader>fw",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Visual selection or word",
			mode = { "n", "x" },
		},
		-- search
		{
			'<leader>f"',
			function()
				Snacks.picker.registers()
			end,
			desc = "Registers",
		},
		{
			"<leader>f/",
			function()
				Snacks.picker.search_history()
			end,
			desc = "Search History",
		},
		{
			"<leader>fA",
			function()
				Snacks.picker.autocmds()
			end,
			desc = "Autocmds",
		},
		{
			"<leader>fC",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>fD",
			function()
				Snacks.picker.diagnostics({ layout = "vertical" })
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>fd",
			function()
				Snacks.picker.diagnostics_buffer({ layout = "vertical" })
			end,
			desc = "Buffer Diagnostics",
		},
		{
			"<leader>fh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>fH",
			function()
				Snacks.picker.highlights()
			end,
			desc = "Highlights",
		},
		{
			"<leader>fi",
			function()
				Snacks.picker.icons()
			end,
			desc = "Icons",
		},
		{
			"<leader>fj",
			function()
				Snacks.picker.jumps()
			end,
			desc = "Jumps",
		},
		{
			"<leader>fk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<leader>fL",
			function()
				Snacks.picker.loclist()
			end,
			desc = "Location List",
		},
		{
			"<leader>fm",
			function()
				Snacks.picker.marks()
			end,
			desc = "Marks",
		},
		{
			"<leader>f'",
			function()
				Snacks.picker.marks()
			end,
			desc = "Marks",
		},
		{
			"<leader>fM",
			function()
				Snacks.picker.man()
			end,
			desc = "Man Pages",
		},
		{
			"<leader>fq",
			function()
				Snacks.picker.qflist()
			end,
			desc = "Quickfix List",
		},
		{
			"<leader>f<CR>",
			function()
				Snacks.picker.resume()
			end,
			desc = "Resume",
		},
		{
			"<leader>fu",
			function()
				Snacks.picker.undo()
			end,
			desc = "Undo History",
		},
		{
			"<leader>uC",
			function()
				Snacks.picker.colorschemes()
			end,
			desc = "Colorschemes",
		},
		-- LSP
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions({ layout = "ivy" })
			end,
			desc = "Goto Definition",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_declarations({ layout = "ivy" })
			end,
			desc = "Goto Declaration",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references({ layout = "ivy" })
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations({ layout = "ivy" })
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions({ layout = "ivy" })
			end,
			desc = "Goto T[y]pe Definition",
		},
		{
			"<leader>ls",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>lS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "LSP Workspace Symbols",
		},
		-- Other
		{
			"<leader>uz",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>uZ",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>f.",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>fn",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>c",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>lR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
		{
			"<leader>go",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end

				-- Override print to use snacks for `:=` command
				if vim.fn.has("nvim-0.11") == 1 then
					vim._print = function(_, ...)
						dd(...)
					end
				else
					vim.print = _G.dd
				end

				-- Create some toggle mappings
				Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
				Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
				Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
				Snacks.toggle.diagnostics():map("<leader>ud")
				Snacks.toggle.line_number():map("<leader>ul")
				Snacks.toggle
					.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
					:map("<leader>uc")
				Snacks.toggle.treesitter():map("<leader>uT")
				Snacks.toggle
					.option("background", { off = "light", on = "dark", name = "Dark Background" })
					:map("<leader>ub")
				Snacks.toggle.inlay_hints():map("<leader>uh")
				Snacks.toggle.indent():map("<leader>ug")
				Snacks.toggle.dim():map("<leader>uD")
			end,
		})
	end,
}
