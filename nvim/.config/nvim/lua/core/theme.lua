local M = {}

--- Accent colors
M.accents = {
	red = "#F38BA8",
	coral = "#FF6B6B",
	rose = "#FF758F",
	pink = "#F5C2E7",
	lavender = "#C9A0FF",
	violet = "#A998F0",
	blue = "#89B4FA",
	cyan = "#64B8B4",
	mint = "#7CE0C2",
	green = "#A6E3A1",
	lime = "#9ACD5A",
	yellow = "#F9E2AF",
	peach = "#FFB07C",
	orange = "#FF8E29",
}

--- @class Colors
M.colors = {
	accent = M.accents.yellow,
	white = "#CDD6F4",
	light_gray = "#A6A6A6",
	gray = "#6C7086",
	ghost = "#4D4D4D",
	dark_gray = "#282828",
	dark = "#141414",
	diff_add = "#273C29",
	diff_change = "#4D4322",
	diff_delete = "#492523",
	diff_text = "#857131",
	visual = "#2E3A46",
}

--- Convenience `vim.api.nvim_set_hl()` wrapper
--- @param name string
--- @param val vim.api.keyset.highlight
local function hl(name, val)
	vim.api.nvim_set_hl(0, name, val)
end

function M.colorscheme()
	vim.o.background = "dark"
	vim.g.colors_name = "silentium"
	vim.cmd.highlight("clear")
	if vim.fn.has("syntax_on") then
		vim.cmd.syntax("reset")
	end

	hl("@constant.html", { fg = M.colors.light_gray })
	hl("@tag", { fg = M.colors.accent })
	hl("@tag.attribute", { link = "Normal" })
	hl("@tag.builtin", { fg = M.colors.accent })
	hl("@tag.delimiter", { link = "Normal" })
	hl("@variable", { link = "Normal" })
	hl("Added", { fg = M.accents.green })
	hl("Changed", { fg = M.accents.yellow })
	hl("ColorColumn", { bg = M.colors.dark_gray })
	hl("Comment", { fg = M.colors.gray })
	hl("Conceal", { fg = M.colors.ghost })
	hl("Constant", { link = "Normal" })
	hl("CursorColumn", { bg = M.colors.dark_gray })
	hl("CursorLine", { bg = M.colors.dark_gray })
	hl("Delimiter", { link = "Normal" })
	hl("DiagnosticError", { fg = M.accents.red })
	hl("DiagnosticHint", { fg = M.accents.blue })
	hl("DiagnosticInfo", { fg = M.accents.cyan })
	hl("DiagnosticOk", { fg = M.accents.green })
	hl("DiagnosticUnderlineError", { underline = true, sp = M.accents.red })
	hl("DiagnosticUnderlineHint", { underline = true, sp = M.accents.blue })
	hl("DiagnosticUnderlineInfo", { underline = true, sp = M.accents.cyan })
	hl("DiagnosticUnderlineOk", { underline = true, sp = M.accents.green })
	hl("DiagnosticUnderlineWarn", { underline = true, sp = M.accents.yellow })
	hl("DiagnosticWarn", { fg = M.accents.yellow })
	hl("DiffAdd", { bg = M.colors.diff_add })
	hl("DiffChange", { bg = M.colors.diff_change })
	hl("DiffDelete", { bg = M.colors.diff_delete })
	hl("DiffText", { bg = M.colors.diff_text })
	hl("Directory", { fg = M.colors.accent })
	hl("Error", { bg = M.accents.red })
	hl("ErrorMsg", { fg = M.accents.red })
	hl("FloatShadow", { bg = M.colors.gray, blend = 80 })
	hl("FloatShadowThrough", { bg = M.colors.gray, blend = 100 })
	hl("Folded", { bg = M.colors.dark_gray, fg = M.colors.gray })
	hl("FzfLuaCursorLine", { bg = M.colors.dark_gray })
	hl("FzfLuaFzfMatch", { fg = M.accents.blue, bold = true })
	hl("FzfLuaFzfQuery", { fg = M.colors.white, bold = true })
	hl("FzfLuaFzfPrompt", { fg = M.accents.blue, bold = true })
	hl("FzfLuaHeaderText", { fg = M.accents.yellow, bold = true })
	hl("FzfLuaSearch", { bg = M.colors.dark_gray, fg = M.colors.accent, bold = true })
	hl("Function", { link = "Normal" })
	hl("Identifier", { link = "Normal" })
	hl("JumpCharDim", { fg = M.colors.gray })
	hl("JumpCharLabel", { fg = M.accents.green })
	hl("Keyword", { fg = M.colors.accent })
	hl("LineNr", { fg = M.colors.light_gray })
	hl("LineNrBelow", { fg = M.colors.gray })
	hl("MatchParen", { bg = M.colors.dark_gray })
	hl("ModeMsg", { fg = M.accents.green })
	hl("MoreMsg", { fg = M.accents.blue })
	hl("NonText", { fg = M.colors.ghost })
	hl("Normal", { bg = M.colors.dark, fg = M.colors.white })
	hl("NormalFloat", { bg = M.colors.dark_gray, fg = M.colors.white })
	hl("OkMsg", { fg = M.accents.green })
	hl("Operator", { link = "Normal" })
	hl("Pmenu", { bg = M.colors.dark_gray })
	hl("PmenuMatch", { fg = M.colors.accent })
	hl("PmenuMatchSel", { fg = M.colors.accent, bold = true })
	hl("PmenuSel", { fg = M.colors.accent, bold = true })
	hl("PmenuThumb", { bg = M.colors.gray })
	hl("PreProc", { link = "Normal" })
	hl("Question", { fg = M.colors.accent })
	hl("QuickFixLine", { bg = M.colors.dark_gray })
	hl("Removed", { fg = M.accents.red })
	hl("SignColumn", { fg = M.colors.light_gray })
	hl("Special", { link = "Normal" })
	hl("SpecialKey", { fg = M.colors.ghost })
	hl("SpellBad", { undercurl = true, sp = M.accents.red })
	hl("SpellCap", { undercurl = true, sp = M.accents.yellow })
	hl("SpellLocal", { undercurl = true, sp = M.accents.green })
	hl("SpellRare", { undercurl = true, sp = M.accents.blue })
	hl("Statement", { fg = M.colors.accent })
	hl("StatusLine", { bg = M.colors.ghost, fg = M.colors.white })
	hl("StatusLineNC", { bg = M.colors.dark_gray, fg = M.colors.white })
	hl("String", { fg = M.accents.green })
	hl("TabLineSel", { fg = M.colors.white })
	hl("Title", { fg = M.colors.white })
	hl("Todo", { link = "Normal" })
	hl("Type", { link = "Normal" })
	hl("Visual", { bg = M.colors.visual })
	hl("WarningMsg", { fg = M.accents.yellow })
	hl("WinBar", { bg = M.colors.accent, fg = M.colors.dark })
	hl("WinBarNC", { bg = M.colors.accent, fg = M.colors.dark })
	hl("WinSeparator", { fg = M.colors.gray })

	vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false, pattern = vim.g.colors_name })
end

--- Configure colorscheme
--- @param opts? Colors|{ colors?: Colors }
function M.setup(opts)
	if opts ~= nil then
		vim.validate({
			opts = { opts, "t" },
			colors = { opts.colors, "t", true },
		})

		if opts.colors ~= nil then
			M.colors = vim.tbl_extend("force", M.colors, opts.colors)
		else
			M.colors = vim.tbl_extend("force", M.colors, opts)
		end
	end

	M.colorscheme()
end

return M
