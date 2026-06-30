return {
  {
    "nvim-mini/mini.ai",
    event = "BufRead",
    version = "*",
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
    end,
  },
  {
    "nvim-mini/mini.bufremove",
    event = "BufRead",
    version = "*",
    keys = {
      {
        "<leader>c",
        function()
          require("mini.bufremove").delete()
        end,
        desc = "Close current buffer",
      },
    },
  },
  {
    "nvim-mini/mini.trailspace",
    event = { "BufRead", "BufNewFile" },
    version = "*",
    config = function()
      require("mini.trailspace").setup()

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("UserMiniTrailspace", { clear = true }),
        callback = function()
          MiniTrailspace.trim()
          MiniTrailspace.trim_last_lines()
        end,
      })
    end,
  },
}
