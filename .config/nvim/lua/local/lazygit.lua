-- Custom toggle lazygit function
-- Open lazygit in a new terminal window
-- Close the terminal window when lazygit is closed
-- Not using other plugins because I don't want to add a dependency

local M = {}

function M.toggle_lazygit()
	vim.cmd("terminal lazygit")
	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("TermClose", {
		buffer = 0,
		callback = function()
			vim.schedule(function()
				vim.cmd("bdelete!")
			end)
		end,
		once = true,
	})
end

return M
