--- diagnostic settings
local map = vim.keymap.set

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = false,
  virtual_lines = false,
  float = {
    border = "rounded",
    source = "if_many",
    header = "",
    -- prefix = "",
  },

  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },

  linehl = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLine",
    [vim.diagnostic.severity.WARN] = "DiagnosticWarnLine",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfoLine",
    [vim.diagnostic.severity.HINT] = "DiagnosticHintLine",
  },
})

-- diagnostic keymaps
map("n", "gl", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
