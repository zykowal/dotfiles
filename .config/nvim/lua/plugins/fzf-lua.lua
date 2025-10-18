return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"echasnovski/mini.nvim",
	},
	keys = {
		{
			"<Leader>f:",
			function()
				require("fzf-lua").command_history({
					winopts = {
						height = 0.647,
						width = 0.4,
					},
				})
			end,
			desc = "Resume previous search",
		},
		{
			"<Leader>f<CR>",
			function()
				require("fzf-lua").resume()
			end,
			desc = "Resume previous search",
		},
		{
			"<Leader>f'",
			function()
				require("fzf-lua").marks()
			end,
			desc = "Find marks",
		},
		{
			"<Leader>fl",
			function()
				require("fzf-lua").blines({
					winopts = {
						split = "belowright new",
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find words in current buffer",
		},
		{
			"<Leader>fa",
			function()
				require("fzf-lua").files({
					prompt = "Config> ",
					cwd = vim.fn.stdpath("config"),
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find AstroNvim config files",
		},
		{
			"<Leader>fb",
			function()
				require("fzf-lua").buffers({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find buffers",
		},
		{
			"<Leader>fc",
			function()
				require("fzf-lua").grep_cword({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find word under cursor",
		},
		{
			"<Leader>fC",
			function()
				require("fzf-lua").commands({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find commands",
		},
		{
			"<Leader>ff",
			function()
				require("fzf-lua").files({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find files",
		},
		{
			"<Leader>fh",
			function()
				require("fzf-lua").helptags({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find help",
		},
		{
			"<Leader>fk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "Find keymaps",
		},
		{
			"<Leader>fm",
			function()
				require("fzf-lua").manpages({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find man",
		},
		{
			"<Leader>fo",
			function()
				require("fzf-lua").oldfiles({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find history",
		},
		{
			"<Leader>fr",
			function()
				require("fzf-lua").registers({
					winopts = { preview = { hidden = true } },
				})
			end,
			desc = "Find registers",
		},
		{
			"<Leader>ft",
			function()
				require("fzf-lua").colorschemes()
			end,
			desc = "Find themes",
		},
		{
			"<Leader>fw",
			function()
				require("fzf-lua").live_grep_native({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find words",
		},
		{
			"<Leader>fW",
			function()
				require("fzf-lua").grep_project({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find words in project",
		},
		{
			"<Leader>fd",
			function()
				require("fzf-lua").diagnostics_document({
					winopts = { preview = { layout = "vertical", border = "border-top" } },
				})
			end,
			desc = "Document diagnositics",
		},
		{
			"<Leader>fD",
			function()
				require("fzf-lua").diagnostics_workspace({
					winopts = { preview = { layout = "vertical", border = "border-top" } },
				})
			end,
			desc = "Workspace diagnositics",
		},
		{
			"<Leader>ls",
			function()
				require("fzf-lua").lsp_document_symbols({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Search symbols",
		},
		{
			"<Leader>lS",
			function()
				require("fzf-lua").lsp_live_workspace_symbols({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Search workspace symbols",
		},
		{
			"<Leader>la",
			function()
				require("fzf-lua").lsp_code_actions({
					winopts = {
						height = 0.85,
						width = 0.65,
						preview = {
							border = "border-bottom",
							layout = "vertical",
							vertical = "up:68%",
							flip_columns = 120,
							delay = 10,
							winopts = { number = false },
						},
					},
					fzf_opts = {
						["--layout"] = "default",
						["--marker"] = "+",
						["--cycle"] = true,
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
						split = "aboveleft vnew",
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
						split = "aboveleft vnew",
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
						split = "aboveleft vnew",
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
						split = "aboveleft vnew",
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
						split = "aboveleft vnew",
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
				require("fzf-lua").zoxide({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Find commands",
		},

		{
			"z=",
			function()
				require("fzf-lua").spell_suggest()
			end,
			desc = "Find commands",
		},
		{
			"<Leader>gb",
			function()
				require("fzf-lua").git_branches({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Git branches",
		},
		{
			"<Leader>gc",
			function()
				require("fzf-lua").git_commits({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Git commits (repository)",
		},
		{
			"<Leader>gC",
			function()
				require("fzf-lua").git_bcommits({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Git commits (current file)",
		},
		{
			"<Leader>gt",
			function()
				require("fzf-lua").git_status({
					winopts = {
						preview = {
							border = "border-left",
						},
					},
				})
			end,
			desc = "Git status",
		},
	},
	opts = {
		{
			"default-title",
			"max-perf",
			"hide",
		},
		winopts = {
			preview = {
				scrollbar = false,
			},
		},
		keymap = {
			builtin = {
				true,
				["<C-d>"] = "preview-page-down",
				["<C-u>"] = "preview-page-up",
			},
			fzf = {
				true,
				["ctrl-d"] = "preview-page-down",
				["ctrl-u"] = "preview-page-up",
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
