return { -- Collection of various small independent plugins/modules
	"echasnovski/mini.nvim",
	lazy = false,
	version = "*",
	config = function()
		-- Better Around/Inside textobjects
		--
		-- Examples:
		--  - va)  - [V]isually select [A]round [)]paren
		--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
		--  - ci'  - [C]hange [I]nside [']quote
		require("mini.ai").setup({ n_lines = 500 })

		-- Add/delete/replace surroundings (brackets, quotes, etc.)
		--
		-- - gsaiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
		-- - gsd'   - [S]urround [D]elete [']quotes
		-- - gsr)'  - [S]urround [R]eplace [)] [']
		require("mini.surround").setup({
			mappings = {
				add = "gsa", -- Add surrounding in Normal and Visual modes
				delete = "gsd", -- Delete surrounding
				replace = "gsr", -- Replace surrounding
				find = "", -- Find surrounding (to the right)
				find_left = "", -- Find surrounding (to the left)
				highlight = "", -- Highlight surrounding
				update_n_lines = "",
			},
			search_method = "cover_or_next",
		})

		-- Split/Join blocks
		require("mini.splitjoin").setup()

		-- Autopairs
		require("mini.pairs").setup()

		-- Buffer remove
		require("mini.bufremove").setup()

		-- Icons
		require("mini.icons").setup()

		-- Pick Extensions
		require("mini.extra").setup()

		require("mini.hipatterns").setup({
			highlighters = {
				todo = require("mini.extra").gen_highlighter.words({ "TODO" }, "MiniHipatternsTodo"),
				fixme = require("mini.extra").gen_highlighter.words({ "FIXME" }, "MiniHipatternsFixme"),
				hack = require("mini.extra").gen_highlighter.words({ "HACK" }, "MiniHipatternsHack"),
				note = require("mini.extra").gen_highlighter.words({ "NOTE" }, "MiniHipatternsNote"),
			},
		})

		-- Pick
		require("mini.pick").setup({
			mappings = {
				caret_left = "<Left>",
				caret_right = "<Right>",

				choose = "<C-l>",
				choose_in_split = "<C-s>",
				choose_in_tabpage = "<C-t>",
				choose_in_vsplit = "<C-v>",

				delete_char = "<C-h>",
				delete_char_right = "<Del>",
				delete_left = "",
				delete_word = "<C-w>",

				move_down = "<C-j>",
				move_start = "<C-g>",
				move_up = "<C-k>",

				paste = "<C-r>",

				refine = "<C-Space>",
				refine_marked = "<M-Space>",

				scroll_down = "<C-d>",
				scroll_left = "<C-b>",
				scroll_right = "<C-f>",
				scroll_up = "<C-u>",

				stop = "<Esc>",

				toggle_info = "<C-p>",
				toggle_preview = "<C-i>",
			},
			options = {
				use_cache = true,
			},
			window = {
				config = function()
					local height = math.floor(0.618 * vim.o.lines)
					local width = math.floor(0.618 * vim.o.columns)
					return {
						anchor = "NW",
						row = math.floor(0.5 * (vim.o.lines - height)),
						col = math.floor(0.5 * (vim.o.columns - width)),
					}
				end,
				prompt_prefix = "   ",
			},
		})

		-- vim.ui.select
		vim.ui.select = MiniPick.ui_select

		-- Starter
		require("mini.starter").setup({
			header = table.concat({
				" ⠀⠀⠀⠀⠀⡀⠀⠀⠀⠨⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠀⠽⠅⠀⠀⠀⠀⠀⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠚⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠠⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣤⠶⠛⠉⠉⠉⠛⠲⢦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣶⣾⣯⣭⡉⠉⠉⠉⢓⡢⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠠⠾⠯⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠙⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⠟⠛⠉⠁⠀⠈⠙⠻⣟⡒⠈⠉⠉⠀⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⡤⠶⠖⠒⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣆⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣦⠶⢄⠀⠀⠀⠀⠀⠀",
				" ⠀⠀⠀⠀⠀⣠⡴⠛⠁⠀⠀⠀⠀⠀⠀⠰⣄⠀⠀⠀⠀⠀⠀⠀⠀⡠⢠⣦⣧⣶⣹⣆⠀⠀⠀⠀⠀⢰⣿⣿⠃⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⢿⠀⠀⠳⡄⠀⠀⠀⠀",
				" ⠀⠀⠀⢀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⠀⣰⢣⣿⡿⣻⣿⣧⣿⠀⠀⠀⠀⣠⣿⡿⠃⠀⠀⠀⣳⡀⠀⠀⠀⠀⠀⠀⠘⠀⠀⠀⠘⡆⠀⠀⠀",
				" ⠀⠀⠀⣼⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠃⣿⣿⣷⣿⣿⣿⢸⣧⣀⡤⠊⠁⠀⠀⠀⡴⠛⠿⠍⠙⠲⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⣀⠀⠀",
				" ⠀⢀⣀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡏⢸⣿⣿⣿⣿⣿⡿⣼⠏⠁⠀⠀⠀⠀⠀⠸⡿⠦⠀⠀⠀⠀⢹⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠬⠛⡆",
				" ⢰⣡⣤⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⣼⣿⣿⣿⣿⣿⢣⡟⠀⠀⠛⠛⠛⠛⠛⠛⠛⠂⠀⠀⠀⠀⢸⡇⠀⠀⠀⢰⡿⣄⠀⠀⠀⢀⣠⡇",
				" ⠘⢿⣿⠟⠙⠳⣤⣀⣀⡀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣼⡔⣿⣿⣿⡿⣛⣵⣿⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠾⣄⣀⣀⣠⡼⠁⠈⠳⢤⣤⡤⠾⠁",
				" ⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠻⢮⣭⠵⠞⠉⠉⠉⠉⠙⠛⠛⠉⠛⠋⠉⠛⠛⠛⠛⠋⠉⠁⠀⠀⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀",

				-- "                      *((##*                                                      ",
				-- "                  /###%%#%&&&%,                           .%((//(/.               ",
				-- "                  #%%&&&&@@@@@@@*                        #%#&%@&%%##%%            ",
				-- "                 &&&@@@@@@@@@@@@@   .**(/(,*,/,*,       &@@@@@@@@@&&%%%*          ",
				-- "                 @@@@@@@@@@&@*                         %@@@@@@@@@@@@&&&&          ",
				-- "                  @@@@%/,               ,                 /@&%@@@@@@@&&&*         ",
				-- "                   &@,                 .                      /%@@@@@@@&.         ",
				-- "                .(..                  ,                         *#@@@@@#          ",
				-- "              .(                                                 .@@@@*           ",
				-- "              #                                                    (              ",
				-- "             ,             *%@%             .@@@@&*                 ,             ",
				-- "          *            /@@@@@@&            @@@@@@@@&                .*            ",
				-- "          ,            @@@@@@@@,   ...  .   .@@@@@@@@@                 /          ",
				-- "          /           @@@@@@/                  *&@@@@@&                           ",
				-- "         /           ,@&@@@.    %@@@@@@@@@,     .#@@@&&                 ,         ",
				-- "         #            (%%%/    *@@@@@@@@@%*      *&%#(*                 /         ",
				-- "         *        .     .           /                   , .,.                     ",
				-- "          .                /                     *                      *         ",
				-- "          *                #.    ./%,%/.      ,%                       /..        ",
				-- "          .,                                                        ,,*  *        ",
				-- "            %*                                 (%%#%%(,          *&*..    ,       ",
				-- "           ,/**#@%,**         ........ ...    #&&&@&&&%%%&(,#@@@@@&##%(%%#,,.     ",
				-- "          .%@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@(@@@@@@&&@@%&%%&&&#@@@@@@@@&&&%(,    ",
				-- "          (%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@@@@@@@@@@@&&%&@%&@@@@@@@@@%#,   ",
				-- "        *&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@&%&&*&@@@@@@&&#.  ",
				-- "        &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@&@@@&&(@@@@@@&%* ",
				-- "      .#@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@%@@@(@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@##@@@@#.",
				-- "      /@@@@@@@@@@@%%&%@&##%&#%/(@(&#%%###%&%@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/",
				-- "     @@@@@@@@@@%((/((**,.,,,,*,,.,*.*.,*,,,,.. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/",
				-- "    .@@@@@@@@@/.*   .                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(",
			}, "\n"),
			items = {
				{ name = "", action = "", section = "" },
			},
			footer = "",
			query_updaters = "",
		})
	end,
	keys = {
		{
			"<leader>c",
			function()
				require("mini.bufremove").delete()
			end,
			desc = "Close current buffer",
		},
		{
			"<leader>:",
			"<CMD>Pick history<CR>",
			desc = "Find command history",
		},
		{
			"gr",
			"<CMD>Pick lsp scope='references'<CR>",
			desc = "Find references",
		},
		{
			"gd",
			"<CMD>Pick lsp scope='definition'<CR>",
			desc = "Find definition",
		},
		{
			"gD",
			"<CMD>Pick lsp scope='declaration'<CR>",
			desc = "Find declaration",
		},
		{
			"gI",
			"<CMD>Pick lsp scope='implementation'<CR>",
			desc = "Find implementation",
		},
		{
			"gy",
			"<CMD>Pick lsp scope='type_definition'<CR>",
			desc = "Find type definition",
		},
		{
			"<leader>fs",
			"<CMD>Pick lsp scope='document_symbol'<CR>",
			desc = "Find document symbol",
		},
		{
			"<leader>fS",
			"<CMD>Pick lsp scope='workspace_symbol'<CR>",
			desc = "Find workspace symbol",
		},
		{
			"<leader>/",
			"<CMD>Pick buf_lines scope='current'<CR>",
			desc = "Find line",
		},
		{
			"<leader>fw",
			"<CMD>Pick grep_live<CR>",
			desc = "Find grep live",
		},
		{
			"<leader>ff",
			"<CMD>Pick files<CR>",
			desc = "Find files",
		},
		{
			"<leader>fd",
			"<CMD>Pick diagnostic scope='current'<CR>",
			desc = "Find current diagnostic",
		},
		{
			"<leader>fD",
			"<CMD>Pick diagnostic<CR>",
			desc = "Find diagnostics",
		},
		{
			"<leader>ft",
			"<CMD>Pick hipatterns<CR>",
			desc = "Find todo",
		},
		{
			"<leader>fh",
			"<CMD>Pick help<CR>",
			desc = "Find help",
		},
		{
			"<leader>fH",
			"<CMD>Pick hl_groups<CR>",
			desc = "Find highlight groups",
		},
		{
			"<leader>fb",
			"<CMD>Pick buffers<CR>",
			desc = "Find buffers",
		},
		{
			"<leader>fk",
			"<CMD>Pick keymaps<CR>",
			desc = "Find keymaps",
		},
		{
			"<leader>fc",
			"<CMD>Pick grep pattern='<cword>'<CR>",
			desc = "Find cursor word",
		},
		{
			"<leader>fC",
			"<CMD>Pick commands<CR>",
			desc = "Find commands",
		},
		{
			"<leader>fo",
			"<CMD>Pick oldfiles<CR>",
			desc = "Find old files",
		},
		{
			"<leader>fO",
			"<CMD>Pick options<CR>",
			desc = "Find options",
		},
		{
			"<leader>fg",
			"<CMD>Pick git_files<CR>",
			desc = "Find git files",
		},
		{
			"<leader>fm",
			"<CMD>Pick marks<CR>",
			desc = "Find marks",
		},
		{
			"<leader>fr",
			"<CMD>Pick registers<CR>",
			desc = "Find registers",
		},
		{
			"<leader>fq",
			"<CMD>Pick list scope='quickfix'<CR>",
			desc = "Find quickfix",
		},
		{
			"<leader>fl",
			"<CMD>Pick grep pattern=''<CR>",
			desc = "Find grep",
		},
		{
			"<leader>f<CR>",
			"<CMD>Pick resume<CR>",
			desc = "Find resume",
		},
		{
			"<leader>gb",
			"<CMD>Pick git_branches<CR>",
			desc = "Find git branches",
		},
		{
			"<leader>gh",
			"<CMD>Pick git_hunks<CR>",
			desc = "Find git hunks",
		},
		{
			"<leader>gc",
			"<CMD>Pick git_commits<CR>",
			desc = "Find git commits",
		},
		{
			"z=",
			"<CMD>Pick spellsuggest<CR>",
			desc = "Spell suggest",
		},
	},
}
