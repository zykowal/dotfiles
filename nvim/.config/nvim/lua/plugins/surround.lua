local function pair_surround(left, right)
  return {
    add = { left, right },
    find = function()
      return require("nvim-surround.config").get_selection({ pattern = string.format("%%b%s%s", left, right) })
    end,
    delete = "^(.)().-(.)()$",
  }
end

local function quote_surround(char)
  local escaped = vim.pesc(char)
  local pattern = escaped .. "[^\n" .. escaped .. "]-" .. escaped

  return {
    add = { char, char },
    -- Avoid `a"`/`a'`/`a`` textobjects here because mini.ai owns them and
    -- notifies while nvim-surround probes the `s` alias.
    find = function()
      return require("nvim-surround.config").get_selection({ pattern = pattern })
    end,
    delete = "^(.)().-(.)()$",
  }
end

return {
  "kylechui/nvim-surround",
  version = "^4.0.0",
  event = "BufRead",
  init = function()
    vim.g.nvim_surround_no_insert_mappings = true
  end,
  opts = {
    surrounds = {
      [")"] = pair_surround("(", ")"),
      ["}"] = pair_surround("{", "}"),
      ["]"] = pair_surround("[", "]"),
      [">"] = pair_surround("<", ">"),
      ['"'] = quote_surround('"'),
      ["'"] = quote_surround("'"),
      ["`"] = quote_surround("`"),
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
