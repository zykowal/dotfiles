-- Customize comments tags highlight
-- Not using other plugins because I don't want to add a dependency

local function setup_highlights()
	vim.api.nvim_set_hl(0, "TodoTodo", { fg = "#1e1e2e", bg = "#f9e2af", bold = true })
	vim.api.nvim_set_hl(0, "TodoHack", { fg = "#1e1e2e", bg = "#f38ba8", bold = true })
	vim.api.nvim_set_hl(0, "TodoOptimize", { fg = "#1e1e2e", bg = "#a6e3a1", bold = true })
	vim.api.nvim_set_hl(0, "TodoNote", { fg = "#1e1e2e", bg = "#89b4fa", bold = true })
	vim.api.nvim_set_hl(0, "TodoFix", { fg = "#1e1e2e", bg = "#fab387", bold = true })
end

local function setup_matches()
	vim.fn.matchadd("TodoTodo", "\\<\\(TODO\\|todo\\):")
	vim.fn.matchadd("TodoHack", "\\<\\(HACK\\|hack\\):")
	vim.fn.matchadd("TodoOptimize", "\\<\\(OPTIMIZE\\|optimize\\|PERF\\|perf\\):")
	vim.fn.matchadd("TodoNote", "\\<\\(NOTE\\|note\\|INFO\\|info\\):")
	vim.fn.matchadd("TodoFix", "\\<\\(FIX\\|fix\\|FIXME\\|fixme\\|BUG\\|bug\\):")
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = "*",
	callback = setup_matches,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = setup_highlights,
})

setup_highlights()
