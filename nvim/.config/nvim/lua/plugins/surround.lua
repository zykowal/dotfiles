return {
  "kylechui/nvim-surround",
  version = "^4.0.0",
  event = "BufRead",
  init = function(_, opts)
    vim.g.nvim_surround_no_insert_mappings = true
  end,
  opts = {
    surrounds = {
      w = {
        add = function()
          return nil
        end,
        find = "[%a_][%w_:]*%b<>",
        delete = "^(.-<)().-(>)()$",
      },
    },
  },
}
