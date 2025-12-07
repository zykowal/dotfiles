if true then
	return {}
end

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
						preview = {
							border = "rounded",
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
						preview = {
							border = "rounded",
						},
					},
				})
			end,
			desc = "Find marks",
		},
		{
			"<Leader>/",
			function()
				require("fzf-lua").blines({ winopts = { preview = { hidden = true } } })
			end,
			desc = "Find words in current buffer",
		},
		{
			"<Leader>fA",
			function()
				require("fzf-lua").autocmds({
					winopts = {
						preview = {
							border = "rounded",
						},
					},
				})
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
			"<Leader>fv",
			function()
				require("fzf-lua").grep_visual()
			end,
			mode = "v",
			desc = "Find visual selection",
		},
		{
			"<Leader>fu",
			function()
				require("fzf-lua").changes({
					winopts = {
						preview = {
							border = "rounded",
						},
					},
				})
			end,
			desc = "Find changes",
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
			"<Leader>fH",
			function()
				require("fzf-lua").highlights({
					winopts = {
						preview = {
							border = "rounded",
						},
					},
				})
			end,
			desc = "Find highlights",
		},
		{
			"<Leader>fj",
			function()
				require("fzf-lua").jumps({
					winopts = {
						preview = {
							border = "rounded",
						},
					},
				})
			end,
			desc = "Find jumps",
		},
		{
			"<Leader>fk",
			function()
				require("fzf-lua").keymaps({
					winopts = {
						preview = {
							border = "rounded",
						},
					},
				})
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
			'<Leader>f"',
			function()
				require("fzf-lua").registers({ winopts = { preview = { hidden = true } } })
			end,
			desc = "Find registers",
		},
		{
			"<Leader>fr",
			function()
				require("fzf-lua").registers({ winopts = { preview = { hidden = true } } })
			end,
			desc = "Find registers",
		},
		{
			"<Leader>ft",
			"<CMD>TodoFzfLua<CR>",
			desc = "Find todos",
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
				require("fzf-lua").diagnostics_document()
			end,
			desc = "Document diagnositics",
		},
		{
			"<Leader>fD",
			function()
				require("fzf-lua").diagnostics_workspace()
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
				require("fzf-lua").lsp_code_actions()
			end,
			desc = "Code actions",
		},
		{
			"gp",
			function()
				require("fzf-lua").lsp_finder()
			end,
			desc = "Lsp finder",
		},
		{
			"gh",
			function()
				require("fzf-lua").lsp_type_sub()
			end,
			desc = "Show subtypes",
		},
		{
			"gH",
			function()
				require("fzf-lua").lsp_type_super()
			end,
			desc = "Show supertypes",
		},
		{
			"gr",
			function()
				require("fzf-lua").lsp_references()
			end,
			desc = "Search references",
		},
		{
			"gd",
			function()
				require("fzf-lua").lsp_definitions()
			end,
			desc = "Search definitions",
		},
		{
			"gD",
			function()
				require("fzf-lua").lsp_declarations()
			end,
			desc = "Search declarations",
		},
		{
			"gy",
			function()
				require("fzf-lua").lsp_typedefs()
			end,
			desc = "Search type definitions",
		},
		{
			"gI",
			function()
				require("fzf-lua").lsp_implementations()
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
			"<Leader>gw",
			function()
				require("fzf-lua").git_worktrees()
			end,
			desc = "Git worktrees",
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
		{
			"<C-x><C-f>",
			function()
				require("fzf-lua").complete_path({
					winopts = {
						height = 0.5,
						width = 0.6,
						relative = "cursor",
					},
				})
			end,
			mode = "i",
			desc = "fuzzy complete path",
		},
	},
	config = function(_, opts)
		local fzf_lua = require("fzf-lua")
		fzf_lua.setup(opts or {})
		fzf_lua.register_ui_select(function(_, _)
			return { winopts = { height = 0.7, width = 0.5 } }
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
			border = "rounded",
			preview = {
				scrollbar = false,
				layout = "vertical",
				horizontal = "right:62%",
				vertical = "down:62%",
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
