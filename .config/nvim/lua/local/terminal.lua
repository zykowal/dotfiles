-- Custom toggle terminal function
-- Create a new terminal window if it doesn't exist
-- otherwise, toggle between the existing terminal window and the current buffer
-- Not using other plugins because I don't want to add a dependency

local M = {}

local term_buf1 = nil
local term_win1 = nil

local term_buf2 = nil
local term_win2 = nil

function M.toggle_horizontal_terminal()
	if term_win1 and vim.api.nvim_win_is_valid(term_win1) then
		vim.api.nvim_win_close(term_win1, true)
		term_win1 = nil
	else
		vim.cmd("topleft split")
		term_win1 = vim.api.nvim_get_current_win()

		if term_buf1 and vim.api.nvim_buf_is_valid(term_buf1) then
			vim.api.nvim_win_set_buf(term_win1, term_buf1)
		else
			vim.cmd("terminal")
			term_buf1 = vim.api.nvim_get_current_buf()
		end

		vim.api.nvim_win_set_height(term_win1, math.floor(vim.o.lines * 0.5))
		vim.cmd("startinsert")
	end
end

function M.toggle_vertical_terminal()
	if term_win2 and vim.api.nvim_win_is_valid(term_win2) then
		vim.api.nvim_win_close(term_win2, true)
		term_win2 = nil
	else
		vim.cmd("vsplit")
		term_win2 = vim.api.nvim_get_current_win()

		if term_buf2 and vim.api.nvim_buf_is_valid(term_buf2) then
			vim.api.nvim_win_set_buf(term_win2, term_buf2)
		else
			vim.cmd("terminal")
			term_buf2 = vim.api.nvim_get_current_buf()
		end

		vim.api.nvim_win_set_width(term_win2, math.floor(vim.o.columns * 0.5))
		vim.cmd("startinsert")
	end
end

return M
