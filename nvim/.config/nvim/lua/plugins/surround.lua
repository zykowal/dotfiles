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
