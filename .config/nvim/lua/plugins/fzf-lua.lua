return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"echasnovski/mini.nvim",
	},
	keys = {
		{
			"<Leader>:",
			function()
				require("fzf-lua").command_history({
					winopts = {
						height = 0.45,
						width = 0.6,
					},
				})
			end,
			desc = "Command history",
		},
		{
			"<Leader>f<CR>",
			function()
				require("fzf-lua").resume()
			end,
			desc = "Resume previous search",
		},
		{
			"<Leader>fm",
			function()
				require("fzf-lua").marks({
					winopts = {
						width = 0.60,
						height = 0.75,
						preview = {
							layout = "vertical",
							vertical = "up:40%",
						},
					},
				})
			end,
			desc = "Find marks",
		},
		{
			"<Leader>f'",
			function()
				require("fzf-lua").marks({
					winopts = {
						width = 0.60,
						height = 0.75,
						preview = {
							layout = "vertical",
							vertical = "up:40%",
						},
					},
				})
			end,
			desc = "Find marks",
		},
		{
			"<Leader>/",
			function()
				require("fzf-lua").blines({
					winopts = {
						preview = {
							hidden = true,
						},
					},
				})
			end,
			desc = "Find words in current buffer",
		},
		{
			"<Leader>fA",
			function()
				require("fzf-lua").autocmds()
			end,
			desc = "Find autocmds",
		},
		{
			"<Leader>fa",
			function()
				require("fzf-lua").files({
					prompt = "Config> ",
					cwd = vim.fn.stdpath("config"),
				})
			end,
			desc = "Find config files",
		},
		{
			"<Leader>.",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "Find buffers",
		},
		{
			"<Leader>fb",
			function()
				require("fzf-lua").buffers()
			end,
			desc = "Find buffers",
		},
		{
			"<Leader>fc",
			function()
				require("fzf-lua").grep_cword()
			end,
			desc = "Find word under cursor",
		},
		{
			"<Leader>fC",
			function()
				require("fzf-lua").commands()
			end,
			desc = "Find commands",
		},
		{
			"<Leader>ff",
			function()
				require("fzf-lua").files()
			end,
			desc = "Find files",
		},
		{
			"<Leader>fh",
			function()
				require("fzf-lua").helptags()
			end,
			desc = "Find help",
		},
		{
			"<Leader>fj",
			function()
				require("fzf-lua").jumps({
					winopts = {
						width = 0.60,
						height = 0.75,
						preview = {
							layout = "vertical",
							vertical = "up:40%",
						},
					},
				})
			end,
			desc = "Find jumps",
		},
		{
			"<Leader>fk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "Find keymaps",
		},
		{
			"<Leader>fM",
			function()
				require("fzf-lua").manpages()
			end,
			desc = "Find man",
		},
		{
			"<Leader>fo",
			function()
				require("fzf-lua").oldfiles()
			end,
			desc = "Find old files",
		},
		{
			"<Leader>fr",
			function()
				require("fzf-lua").registers({
					winopts = {
						preview = { hidden = true },
					},
				})
			end,
			desc = "Find registers",
		},
		{
			"<Leader>ft",
			"<CMD>TodoFzfLua<CR>",
			desc = "Find themes",
		},
		{
			"<Leader>fT",
			function()
				require("fzf-lua").colorschemes()
			end,
			desc = "Find themes",
		},
		{
			"<Leader>fw",
			function()
				require("fzf-lua").live_grep_native()
			end,
			desc = "Fuzzy search words",
		},
		{
			"<Leader>fW",
			function()
				require("fzf-lua").grep_project()
			end,
			desc = "Regex search words",
		},
		{
			"<Leader>fd",
			function()
				require("fzf-lua").diagnostics_document({
					winopts = {
						preview = { layout = "vertical", border = "border-top" },
					},
				})
			end,
			desc = "Document diagnositics",
		},
		{
			"<Leader>fD",
			function()
				require("fzf-lua").diagnostics_workspace({
					winopts = {
						preview = { layout = "vertical", border = "border-top" },
					},
				})
			end,
			desc = "Workspace diagnositics",
		},
		{
			"<Leader>li",
			function()
				require("fzf-lua").lsp_incoming_calls()
			end,
			desc = "Incoming calls",
		},
		{
			"<Leader>lo",
			function()
				require("fzf-lua").lsp_outgoing_calls()
			end,
			desc = "Outgoing calls",
		},
		{
			"<Leader>ls",
			function()
				require("fzf-lua").lsp_document_symbols()
			end,
			desc = "Search symbols",
		},
		{
			"<Leader>lS",
			function()
				require("fzf-lua").lsp_live_workspace_symbols()
			end,
			desc = "Search workspace symbols",
		},
		{
			"<Leader>la",
			function()
				require("fzf-lua").lsp_code_actions({
					winopts = {
						preview = {
							border = "border-bottom",
							layout = "vertical",
							vertical = "up:68%",
							flip_columns = 120,
							delay = 10,
							winopts = { number = false },
						},
					},
				})
			end,
			desc = "Code actions",
		},
		{
			"gr",
			function()
				require("fzf-lua").lsp_references({
					winopts = {
						-- split = "aboveleft vnew",
						preview = {
							layout = "vertical",
							vertical = "down:62%",
							border = "border-top",
						},
					},
				})
			end,
			desc = "Search references",
		},
		{
			"gd",
			function()
				require("fzf-lua").lsp_definitions({
					winopts = {
						-- split = "aboveleft vnew",
						preview = {
							layout = "vertical",
							vertical = "down:62%",
							border = "border-top",
						},
					},
				})
			end,
			desc = "Search definitions",
		},
		{
			"gD",
			function()
				require("fzf-lua").lsp_declarations({
					winopts = {
						-- split = "aboveleft vnew",
						preview = {
							layout = "vertical",
							vertical = "down:62%",
							border = "border-top",
						},
					},
				})
			end,
			desc = "Search declarations",
		},
		{
			"gy",
			function()
				require("fzf-lua").lsp_typedefs({
					winopts = {
						-- split = "aboveleft vnew",
						preview = {
							layout = "vertical",
							vertical = "down:62%",
							border = "border-top",
						},
					},
				})
			end,
			desc = "Search type definitions",
		},
		{
			"gI",
			function()
				require("fzf-lua").lsp_implementations({
					winopts = {
						-- split = "aboveleft vnew",
						preview = {
							layout = "vertical",
							vertical = "down:62%",
							border = "border-top",
						},
					},
				})
			end,
			desc = "Search implementations",
		},
		{
			"<leader>fz",
			function()
				require("fzf-lua").zoxide()
			end,
			desc = "Find zoxide",
		},
		{
			"<Leader>fq",
			function()
				require("fzf-lua").quickfix()
			end,
			desc = "Find quickfix",
		},
		{
			"<Leader>fQ",
			function()
				require("fzf-lua").quickfix_stack()
			end,
			desc = "Find quickfix stack",
		},
		{
			"<Leader>fl",
			function()
				require("fzf-lua").loclist()
			end,
			desc = "Find loclist",
		},
		{
			"<Leader>fL",
			function()
				require("fzf-lua").loclist_stack()
			end,
			desc = "Find loclist stack",
		},
		{
			"<Leader>fg",
			function()
				require("fzf-lua").git_files()
			end,
			desc = "Search git files",
		},
		{
			"<Leader>f/",
			function()
				require("fzf-lua").search_history()
			end,
			desc = "Search history",
		},
		{
			"z=",
			function()
				require("fzf-lua").spell_suggest()
			end,
			desc = "Spell suggest",
		},
		{
			"<Leader>gA",
			function()
				require("fzf-lua").git_stash()
			end,
			desc = "Git stash",
		},
		{
			"<Leader>ga",
			function()
				require("fzf-lua").git_tags()
			end,
			desc = "Git tags",
		},
		{
			"<Leader>gb",
			function()
				require("fzf-lua").git_branches()
			end,
			desc = "Git branches",
		},
		{
			"<Leader>gc",
			function()
				require("fzf-lua").git_commits()
			end,
			desc = "Git commits (repository)",
		},
		{
			"<Leader>gC",
			function()
				require("fzf-lua").git_bcommits()
			end,
			desc = "Git commits (current file)",
		},
		{
			"<Leader>gt",
			function()
				require("fzf-lua").git_status()
			end,
			desc = "Git status",
		},
	},
	config = function(_, opts)
		local fzf_lua = require("fzf-lua")
		fzf_lua.setup(opts or {})
		fzf_lua.register_ui_select(function(_, items)
			local min_h, max_h = 0.15, 0.70
			local h = (#items + 4) / vim.o.lines
			if h < min_h then
				h = min_h
			elseif h > max_h then
				h = max_h
			end
			return { winopts = { height = h, width = 0.60, row = 0.40 } }
		end)
	end,
	opts = {
		{
			"default-title",
			"max-perf",
			"border-fused",
			"hide",
		},
		winopts = {
			height = 0.80, -- window height
			width = 0.75, -- window width
			row = 0.50, -- window row position (0=top, 1=bottom)
			col = 0.50, -- window col position (0=left, 1=right)
			backdrop = 0,
			preview = {
				scrollbar = false,
				horizontal = "right:62%",
			},
		},
		keymap = {
			builtin = {
				true,
				["<C-d>"] = "preview-page-down",
				["<C-u>"] = "preview-page-up",
				["<C-l>"] = "toggle-preview",
			},
			fzf = {
				true,
				["ctrl-d"] = "preview-page-down",
				["ctrl-u"] = "preview-page-up",
				["ctrl-n"] = "half-page-down",
				["ctrl-p"] = "half-page-up",
				["ctrl-l"] = "toggle-preview",
				["ctrl-q"] = "select-all+accept",
			},
		},
		fzf_colors = {
			true, -- auto generate rest of fzf’s highlights?
			bg = "-1",
			gutter = "-1", -- I like this one too, try with and without
		},
	},
}
