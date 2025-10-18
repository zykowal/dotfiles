-- Custom toggle window maximize function
-- Store current window size and maximize the window
-- Restore original window size when the window is restored
-- Not using other plugins because I don't want to add a dependency

local M = {}

function M.toggle_window_maximize()
	local maximize = vim.w.maximized or false

	if maximize then
		-- Restore original size
		vim.cmd("resize " .. vim.w.old_lines)
		vim.cmd("vertical resize " .. vim.w.old_columns)
		vim.w.maximized = false
	else
		-- Store current size
		vim.w.old_lines = vim.fn.winheight(0)
		vim.w.old_columns = vim.fn.winwidth(0)

		-- Maximize window
		vim.cmd("resize")
		vim.cmd("vertical resize")
		vim.w.maximized = true
	end
end

return M
