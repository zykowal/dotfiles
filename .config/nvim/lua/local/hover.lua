-- Open hover information for the current cursor position
-- Not using other plugins because I don't want to add a dependency

local M = {}

local hover_buf = nil
local hover_win = nil

function M.toggle_hover()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		print("No LSP client available")
		return
	end

	local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)

	vim.lsp.buf_request(0, "textDocument/hover", params, function(err, result)
		if err or not result or not result.contents then
			print("No hover information available")
			return
		end

		-- Extract the hover content
		local lines = {}
		local contents = result.contents

		if type(contents) == "string" then
			for line in contents:gmatch("[^\n]+") do
				table.insert(lines, line)
			end
		elseif contents.kind == "markdown" then
			for line in contents.value:gmatch("[^\n]+") do
				table.insert(lines, line)
			end
		elseif type(contents) == "table" and contents[1] then
			for _, content in ipairs(contents) do
				local value = type(content) == "string" and content or content.value
				for line in value:gmatch("[^\n]+") do
					table.insert(lines, line)
				end
			end
		end

		if #lines == 0 then
			print("No hover information available")
			return
		end

		-- Check if the buffer and window already exist
		if
			hover_buf
			and vim.api.nvim_buf_is_valid(hover_buf)
			and hover_win
			and vim.api.nvim_win_is_valid(hover_win)
		then
			-- Update the existing buffer
			vim.api.nvim_buf_set_option(hover_buf, "modifiable", true)
			vim.api.nvim_buf_set_lines(hover_buf, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(hover_buf, "modifiable", false)
			vim.api.nvim_win_set_height(hover_win, math.min(10, vim.o.lines * 0.5))
		else
			-- Create a new buffer and window
			hover_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(hover_buf, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(hover_buf, "readonly", true)
			vim.api.nvim_buf_set_option(hover_buf, "modifiable", false)
			vim.api.nvim_buf_set_option(hover_buf, "filetype", "markdown")

			local current_win = vim.api.nvim_get_current_win()
			vim.cmd("botright split")
			hover_win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(hover_win, hover_buf)
			vim.api.nvim_win_set_height(hover_win, math.min(10, vim.o.lines * 0.5))

			-- Window options
			vim.api.nvim_win_set_option(hover_win, "number", false)
			vim.api.nvim_win_set_option(hover_win, "relativenumber", false)
			vim.api.nvim_win_set_option(0, "wrap", true)

			-- Jump back to the original window
			vim.api.nvim_set_current_win(current_win)

			-- Close the window when q is pressed
			vim.keymap.set("n", "q", function()
				if hover_win and vim.api.nvim_win_is_valid(hover_win) then
					vim.api.nvim_win_close(hover_win, true)
					hover_buf, hover_win = nil, nil
				end
			end, { buffer = hover_buf })
		end
	end)
end

return M
