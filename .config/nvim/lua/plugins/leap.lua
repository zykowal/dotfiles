return {
	"ggandor/leap.nvim",
	keys = {
		{
			"s",
			function()
				require("leap").leap({ target_windows = { vim.fn.win_getid() } })
			end,
			mode = "n",
			desc = "Leap",
		},
		{ "S", "<Plug>(leap-from-window)", mode = "n", desc = "Leap from window" },
		{
			"s",
			function()
				require("leap").leap({ target_windows = { vim.fn.win_getid() } })
			end,
			mode = "x",
			desc = "Leap",
		},
		{ "S", "<Plug>(leap-from-window)", mode = "x", desc = "Leap from window" },
		{
			"s",
			function()
				require("leap").leap({ target_windows = { vim.fn.win_getid() } })
			end,
			mode = "o",
			desc = "Leap",
		},
		{ "S", "<Plug>(leap-from-window)", mode = "o", desc = "Leap from window" },
	},
	specs = {
		{
			"catppuccin",
			optional = true,
			opts = { integrations = { leap = true } },
		},
	},
	opts = function()
		require("leap").opts.labels = {
			"a",
			"s",
			"d",
			"f",
			"g",
			"h",
			"j",
			"k",
			"l",
			"q",
			"w",
			"e",
			"r",
			"t",
			"y",
			"u",
			"i",
			"o",
			"p",
			"z",
			"x",
			"c",
			"v",
			"b",
			"n",
			"m",
		}

		require("leap").opts.safe_labels = {}
		-- `on_beacons` hooks into `beacons.light_up_beacons`, the function
		-- responsible for displaying stuff.
		require("leap").opts.on_beacons = function(targets, _, _)
			for _, t in ipairs(targets) do
				-- Overwrite the `offset` value in all beacons.
				-- target.beacon looks like: { <offset>, <extmark_opts> }
				if t.label and t.beacon then
					t.beacon[1] = 0
				end
			end
		end
		do
			-- Returns an argument table for `leap()`, tailored for f/t-motions.
			local function as_ft(key_specific_args)
				local common_args = {
					inputlen = 1,
					inclusive_op = true,
					-- To limit search scope to the current line:
					-- pattern = function (pat) return '\\%.l'..pat end,
					opts = {
						labels = {
							"a",
							"s",
							"d",
							"f",
							"g",
							"h",
							"j",
							"k",
							"l",
							"q",
							"w",
							"e",
							"r",
							"t",
							"y",
							"u",
							"i",
							"o",
							"p",
							"z",
							"x",
							"c",
							"v",
							"b",
							"n",
							"m",
						}, -- force autojump
						safe_labels = vim.fn.mode(1):match("o") and {} or nil,
						case_sensitive = false,
					},
				}
				return vim.tbl_deep_extend("keep", common_args, key_specific_args)
			end

			local clever = require("leap.user").with_traversal_keys -- [3]
			local clever_f = clever("f", "F")
			local clever_t = clever("t", "T")

			for key, args in pairs({
				f = { opts = clever_f },
				F = { backward = true, opts = clever_f },
				t = { offset = -1, opts = clever_t },
				T = { backward = true, offset = 1, opts = clever_t },
			}) do
				vim.keymap.set({ "n", "x", "o" }, key, function()
					require("leap").leap(as_ft(args))
				end)
			end
		end
	end,
}
