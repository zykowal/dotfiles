return {
  "dlyongemallo/diffview-plus.nvim",
  version = "*",
  main = "diffview",
  cmd = {
    "DiffviewOpen",
    "DiffviewToggle",
    "DiffviewFileHistory",
    "DiffviewDiffFiles",
    "DiffviewMergeFiles",
    "DiffviewDiffDirs",
    "DiffviewClose",
    "DiffviewWorktreeOverview",
    "DiffviewFocusFiles",
    "DiffviewToggleFiles",
    "DiffviewRefresh",
    "DiffviewLog",
  },
  keys = {
    { "<leader>dd", "<cmd>DiffviewToggle<cr>", desc = "Toggle Diffview" },
    { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
    { "<leader>dH", "<cmd>DiffviewFileHistory<cr>", desc = "Repository history" },
    { "<leader>dr", "<cmd>DiffviewRefresh<cr>", desc = "Refresh Diffview" },
    { "<leader>db", "<cmd>DiffviewToggleFiles<cr>", desc = "Toggle Diffview files" },
    { "<leader>df", "<cmd>DiffviewFocusFiles<cr>", desc = "Focus Diffview files" },
  },
  opts = {
    use_icons = false,
    enhanced_diff_hl = true,
    view = {
      default = { winbar_info = true },
      file_history = { winbar_info = true },
    },
    hooks = { diff_buf_read = function(bufnr) vim.b[bufnr].view_activated = false end },
  }
}
