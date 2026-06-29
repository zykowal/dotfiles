return {
  "mason-org/mason.nvim",
  event = "BufReadPre",
  opts = {
    ui = {
      border = "none",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  },
  keys = {
    {"<leader>pm", "<cmd>Mason<CR>", desc = "Mason"}
  }
}
