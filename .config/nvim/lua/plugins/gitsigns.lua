return {
	"lewis6991/gitsigns.nvim",
	event = "BufRead",
	opts = {
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- Navigation
			map("n", "]g", function()
				gitsigns.nav_hunk("next")
			end, { desc = "Next Git hunk" })

			map("n", "[g", function()
				gitsigns.nav_hunk("prev")
			end, { desc = "Previous Git hunk" })

			map("n", "]G", function()
				gitsigns.nav_hunk("last")
			end, { desc = "Last Git hunk" })

			map("n", "[G", function()
				gitsigns.nav_hunk("first")
			end, { desc = "First Git hunk" })

			-- Stage
			map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage/Unstage Git hunk" })
			map("v", "<leader>gs", function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Stage/Unstage Git hunk" })
			map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage Git buffer" })

			-- Reset
			map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset Git hunk" })
			map("v", "<leader>gr", function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Reset Git hunk" })
			map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset Git buffer" })

			-- Preview
			map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview Git hunk" })
			map("n", "<leader>gi", gitsigns.preview_hunk_inline, { desc = "Preview Git hunk inline" })

			-- Blame
			map("n", "<leader>gl", function()
				gitsigns.blame_line()
			end, { desc = "View Git blame" })

			-- Diff
			map("n", "<leader>gd", gitsigns.diffthis, { desc = "View diff for current file" })

			-- Toggles
			map("n", "<leader>gT", gitsigns.toggle_current_line_blame, { desc = "Toggle Git line blame" })

			-- Text object
			map({ "o", "x" }, "ig", gitsigns.select_hunk, { desc = "Inside Git hunk" })
		end,
	},
}
