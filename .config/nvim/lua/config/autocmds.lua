-- Restore last cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("LastCursorGroup", {}),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight the yanked text for 200ms
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

-- Show cursorline only in active window
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("CursorLine", { clear = true }),
	callback = function()
		vim.opt.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
	group = "CursorLine",
	callback = function()
		vim.opt.cursorline = false
	end,
})

-- Change cursor color in different modes
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
