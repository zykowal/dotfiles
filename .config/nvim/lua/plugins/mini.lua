return { -- Collection of various small independent plugins/modules
	"echasnovski/mini.nvim",
	lazy = true,
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

		-- File explorer
		require("mini.files").setup({
			mappings = {
				go_in = "",
				go_in_plus = "l",
				go_out = "",
				go_out_plus = "h",
				synchronize = "<CR>",
			},
		})

		-- Autopairs
		require("mini.pairs").setup()

		-- Buffer remove
		require("mini.bufremove").setup()

		-- Icons
		require("mini.icons").setup()
	end,
	init = function()
		-- Starter
		require("mini.starter").setup({
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
			items = {
				{ name = "", action = "", section = "" },
			},
			footer = "",
			query_updaters = "",
		})
	end,
	keys = {
		{
			"<leader>e",
			function()
				if not require("mini.files").close() then
					require("mini.files").open()
				end
			end,
			desc = "Explorer",
		},
		{
			"<leader>c",
			function()
				require("mini.bufremove").delete()
			end,
			desc = "Close current buffer",
		},
	},
}
