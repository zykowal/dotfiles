vim.g.nvim_surround_no_insert_mappings = true

require("nvim-surround").setup({
  surrounds = {
    w = {
      add = function()
        return nil
      end,
      find = "[%a_][%w_:]*%b<>",
      delete = "^(.-<)().-(>)()$",
    },
  },
})
