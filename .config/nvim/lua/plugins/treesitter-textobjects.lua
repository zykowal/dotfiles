return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	init = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			textobjects = {
				select = {
					enable = true,
					-- Automatically jump forward to textobj, similar to targets.vim
					lookahead = true,
					keymaps = {
						["ak"] = { query = "@block.outer", desc = "around block" },
						["ik"] = { query = "@block.inner", desc = "inside block" },
						["ac"] = { query = "@class.outer", desc = "around class" },
						["ic"] = { query = "@class.inner", desc = "inside class" },
						["a?"] = { query = "@conditional.outer", desc = "around conditional" },
						["i?"] = { query = "@conditional.inner", desc = "inside conditional" },
						["af"] = { query = "@function.outer", desc = "around function " },
						["if"] = { query = "@function.inner", desc = "inside function " },
						["ao"] = { query = "@loop.outer", desc = "around loop" },
						["io"] = { query = "@loop.inner", desc = "inside loop" },
						["aa"] = { query = "@parameter.outer", desc = "around argument" },
						["ia"] = { query = "@parameter.inner", desc = "inside argument" },
					},
					-- You can choose the select mode (default is charwise 'v')
					--
					-- Can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * method: eg 'v' or 'o'
					-- and should return the mode ('v', 'V', or '<c-v>') or a table
					-- mapping query_strings to modes.
					selection_modes = {
						["@parameter.outer"] = "v", -- charwise
						["@function.outer"] = "V", -- linewise
						["@class.outer"] = "<c-v>", -- blockwise
					},
					-- If you set this to `true` (default is `false`) then any textobject is
					-- extended to include preceding or succeeding whitespace. Succeeding
					-- whitespace has priority in order to act similarly to eg the built-in
					-- `ap`.
					--
					-- Can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * selection_mode: eg 'v'
					-- and should return true or false
					include_surrounding_whitespace = true,
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]k"] = { query = "@block.outer", desc = "Next block start" },
						["]f"] = { query = "@function.outer", desc = "Next function start" },
						["]a"] = { query = "@parameter.inner", desc = "Next argument start" },
					},
					goto_next_end = {
						["]K"] = { query = "@block.outer", desc = "Next block end" },
						["]F"] = { query = "@function.outer", desc = "Next function end" },
						["]A"] = { query = "@parameter.inner", desc = "Next argument end" },
					},
					goto_previous_start = {
						["[k"] = { query = "@block.outer", desc = "Previous block start" },
						["[f"] = { query = "@function.outer", desc = "Previous function start" },
						["[a"] = { query = "@parameter.inner", desc = "Previous argument start" },
					},
					goto_previous_end = {
						["[K"] = { query = "@block.outer", desc = "Previous block end" },
						["[F"] = { query = "@function.outer", desc = "Previous function end" },
						["[A"] = { query = "@parameter.inner", desc = "Previous argument end" },
					},
				},
				swap = {
					enable = true,
					swap_next = {
						[">K"] = { query = "@block.outer", desc = "Swap next block" },
						[">F"] = { query = "@function.outer", desc = "Swap next function" },
						[">A"] = { query = "@parameter.inner", desc = "Swap next argument" },
					},
					swap_previous = {
						["<K"] = { query = "@block.outer", desc = "Swap previous block" },
						["<F"] = { query = "@function.outer", desc = "Swap previous function" },
						["<A"] = { query = "@parameter.inner", desc = "Swap previous argument" },
					},
				},
			},
		})
	end,
}
