-- Open signature help for the current cursor position
-- Not using other plugins because I don't want to add a dependency

local M = {}

local help_buf = nil
local help_win = nil

function M.toggle_signature_help()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		print("No LSP client available")
		return
	end

	local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)

	vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function(err, result)
		if err or not result or not result.signatures or #result.signatures == 0 then
			print("No signature help available")
			return
		end

		-- Extract the signature help content
		local lines = {}
		for _, sig in ipairs(result.signatures) do
			table.insert(lines, sig.label)
			if sig.documentation then
				local doc = type(sig.documentation) == "string" and sig.documentation or sig.documentation.value
				for line in doc:gmatch("[^\n]+") do
					table.insert(lines, line)
				end
			end
		end

		-- Check if the buffer and window already exist
		if help_buf and vim.api.nvim_buf_is_valid(help_buf) and help_win and vim.api.nvim_win_is_valid(help_win) then
			-- Update the existing buffer
			vim.api.nvim_buf_set_option(help_buf, "modifiable", true)
			vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(help_buf, "modifiable", false)
			vim.api.nvim_win_set_height(help_win, math.min(10, vim.o.lines * 0.5))
		else
			-- Create a new buffer and window
			help_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(help_buf, "readonly", true)
			vim.api.nvim_buf_set_option(help_buf, "modifiable", false)
			vim.api.nvim_buf_set_option(help_buf, "filetype", "markdown")

			local current_win = vim.api.nvim_get_current_win()
			vim.cmd("botright split")
			help_win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(help_win, help_buf)
			vim.api.nvim_win_set_height(help_win, math.min(10, vim.o.lines * 0.5))

			-- Window options
			vim.api.nvim_win_set_option(help_win, "number", false)
			vim.api.nvim_win_set_option(help_win, "relativenumber", false)
			vim.api.nvim_win_set_option(0, "wrap", true)

			-- Jump back to the original window
			vim.api.nvim_set_current_win(current_win)

			-- Close the window when q is pressed
			vim.keymap.set("n", "q", function()
				if help_win and vim.api.nvim_win_is_valid(help_win) then
					vim.api.nvim_win_close(help_win, true)
					help_buf, help_win = nil, nil
				end
			end, { buffer = help_buf })
		end
	end)
end

return M
