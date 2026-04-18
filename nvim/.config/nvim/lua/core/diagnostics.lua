--- diagnostic settings
local map = vim.keymap.set

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
    header = "",
    prefix = "",
  },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  virtual_text = {
    prefix = "●",
    severity = { min = vim.diagnostic.severity.HINT },
  },
  virtual_lines = false,

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
