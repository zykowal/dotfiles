local map = vim.keymap.set

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    -- ["*"] = { "trim_whitespace" },
  },
  notify_on_error = false,
  default_format_opts = {
    lsp_format = "fallback",
  },
})

map({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
