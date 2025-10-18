vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "L", "$")
vim.keymap.set("x", "H", "^")
vim.keymap.set("x", "L", "$")

vim.keymap.set("i", "<C-f>", "<Right>", { desc = "Move cursor right" })
vim.keymap.set("i", "<C-b>", "<Left>", { desc = "Move cursor left" })
vim.keymap.set("i", "<C-a>", "<C-o>^", { desc = "Move to beginning of line" })
vim.keymap.set("i", "<C-e>", "<C-o>$", { desc = "Move to end of line" })
vim.keymap.set("i", "<C-d>", "<Delete>", { desc = "Delete character forward" })

vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float()
end, { desc = "Hover diagnostics" })
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move cursor down" })
vim.keymap.set("x", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move cursor down" })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move cursor up" })
vim.keymap.set("x", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move cursor up" })
vim.keymap.set("n", "<Leader>w", "<Cmd>w<CR>", { desc = "Save" })
vim.keymap.set("n", "<Leader>q", "<Cmd>confirm q<CR>", { desc = "Quit Window" })
vim.keymap.set("n", "<Leader>Q", "<Cmd>confirm qall<CR>", { desc = "Exit Window" })
vim.keymap.set("n", "|", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
vim.keymap.set("n", "\\", "<Cmd>split<CR>", { desc = "Horizontal Split" })

vim.keymap.set("n", "<Leader>pi", function()
	require("lazy").install()
end, { desc = "Plugins Install" })
vim.keymap.set("n", "<Leader>pm", "<CMD>Mason<CR>", { desc = "Mason" })

vim.keymap.set("n", "<C-H>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-J>", "<C-w>j", { desc = "Move to below split" })
vim.keymap.set("n", "<C-K>", "<C-w>k", { desc = "Move to above split" })
vim.keymap.set("n", "<C-L>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-Up>", "<Cmd>resize -2<CR>", { desc = "Resize split up" })
vim.keymap.set("n", "<C-Down>", "<Cmd>resize +2<CR>", { desc = "Resize split down" })
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Resize split left" })
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Resize split right" })

vim.keymap.set("n", "gh", function()
	vim.lsp.buf.typehierarchy("subtypes")
end, { desc = "Show subtypes" })
vim.keymap.set("n", "gH", function()
	vim.lsp.buf.typehierarchy("supertypes")
end, { desc = "Show supertypes" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Terminal toggle
vim.keymap.set(
	{ "n", "t" },
	"<C-e>",
	require("local.terminal").toggle_horizontal_terminal,
	{ desc = "Toggle terminal" }
)
vim.keymap.set({ "n", "t" }, "<C-y>", require("local.terminal").toggle_vertical_terminal, { desc = "Toggle terminal" })

-- Window maximize
vim.keymap.set("n", "<C-w>m", require("local.window").toggle_window_maximize, { desc = "Toggle window maximize" })

-- Open lazygit
vim.keymap.set("n", "<leader>gg", require("local.lazygit").toggle_lazygit, { desc = "Open lazygit" })

vim.keymap.set(
	"n",
	"<leader>lh",
	require("local.signature_help").toggle_signature_help,
	{ desc = "Show signature help" }
)
vim.keymap.set("n", "gk", require("local.hover").toggle_hover, { desc = "Show hover information" })

vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })

vim.keymap.del("n", "gra", { silent = true })
vim.keymap.del("n", "gri", { silent = true })
vim.keymap.del("n", "grn", { silent = true })
vim.keymap.del("n", "grr", { silent = true })
vim.keymap.del("n", "grt", { silent = true })
