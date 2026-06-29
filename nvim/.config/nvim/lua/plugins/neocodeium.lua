return {
  "monkoose/neocodeium",
  event = "VeryLazy",
  config = function() 
    local neocodeium = require("neocodeium")
    neocodeium.setup()
    vim.keymap.set({"i", "c"}, "<C-l>", function() return require("neocodeium").accept() end)
    vim.keymap.set("i", "<S-Tab>", function() require("neocodeium").cycle_or_complete(-1) end)
    vim.keymap.set("i", "<Tab>", function() require("neocodeium").cycle_or_complete() end)
  end
}
