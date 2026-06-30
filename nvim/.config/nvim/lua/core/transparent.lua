local M = {}

local augroup = vim.api.nvim_create_augroup("UserThemeTransparent", { clear = true })

-- stylua: ignore start
M.opts = {
	groups = {
		'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
		'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
		'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
		'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
		'EndOfBuffer', 'NormalFloat', 'FloatBorder', 'FloatTitle', 'WinSeparator',
		'Pmenu', 'PmenuSel', 'PmenuMatchSel', 'PmenuSbar', 'PmenuThumb', 'FoldColumn', 'Folded',
	},
	extra_groups = {},
	exclude_groups = {},
	on_clear = function() end,
}
-- stylua: ignore end

local function transparent_groups()
	local groups = vim.list_extend(vim.deepcopy(M.opts.groups), M.opts.extra_groups)
	local excluded = {}

	for _, group in ipairs(M.opts.exclude_groups) do
		excluded[group] = true
	end

	return vim.tbl_filter(function(group)
		return not excluded[group]
	end, groups)
end

local function clear_group_bg(group)
	local ok, group_hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
	if not ok then
		return
	end

	group_hl.bg = nil
	group_hl.ctermbg = nil

	vim.api.nvim_set_hl(0, group, group_hl)
end

function M.clear()
	for _, group in ipairs(transparent_groups()) do
		clear_group_bg(group)
	end

	M.opts.on_clear()
end

--- Configure transparent background
--- @param opts? table
function M.setup(opts)
	if opts ~= nil then
		vim.validate({
			opts = { opts, "t" },
			groups = { opts.groups, "t", true },
			extra_groups = { opts.extra_groups, "t", true },
			exclude_groups = { opts.exclude_groups, "t", true },
			on_clear = { opts.on_clear, "f", true },
		})

		M.opts = vim.tbl_extend("force", M.opts, opts)
	end

	vim.api.nvim_clear_autocmds({ group = augroup })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = M.clear,
	})

	M.clear()
end

return M
