-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = last_cursor_group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight the yanked text for 200ms
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

local function set_cursor_color()
	vim.opt.guicursor = {
		"n-v-c:block-Cursor/lCursor",
		"i-ci-ve:block-CursorInsert/lCursorInsert",
		"r-cr:block-CursorReplace/lCursorReplace",
		"o:block-CursorOther/lCursorOther",
		"sm:block-CursorSearch/lCursorSearch",
	}

	vim.api.nvim_set_hl(0, "Cursor", { bg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "CursorInsert", { bg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "CursorReplace", { bg = "#E06C75" })
	vim.api.nvim_set_hl(0, "CursorOther", { bg = "#C678DD" })
	vim.api.nvim_set_hl(0, "CursorSearch", { bg = "#FF00FF" })
end

set_cursor_color()

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_cursor_color,
})
