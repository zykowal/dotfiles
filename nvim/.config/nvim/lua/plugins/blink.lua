require("blink.cmp").setup({
  keymap = {
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<C-N>"] = { "select_next", "show" },
    ["<C-P>"] = { "select_prev", "show" },
    ["<C-J>"] = { "select_next", "fallback" },
    ["<C-K>"] = { "select_prev", "fallback" },
    ["<C-U>"] = { function(cmp) return cmp.select_prev({ count = 5 }) end, "fallback" },
    ["<C-D>"] = { function(cmp) return cmp.select_next({ count = 5 }) end, "fallback" },
    ["<C-B>"] = { "scroll_documentation_up", "fallback" },
    ["<C-F>"] = { "scroll_documentation_down", "fallback" },
    ["<C-E>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<C-l>"] = { "accept", "fallback" },
  },

  cmdline = {
    keymap = {
      ["<Tab>"] = { "show", "accept" },
      ["<S-Tab>"] = { "show_and_insert", "select_prev" },

      ["<C-N>"] = { "select_next", "show" },
      ["<C-P>"] = { "select_prev", "show" },
      ["<C-J>"] = { "select_next", "fallback" },
      ["<C-K>"] = { "select_prev", "fallback" },
      ["<C-L>"] = { "accept", "fallback" },

      ["<C-Y>"] = { "select_and_accept" },
      ["<C-E>"] = { "cancel" },
    },
    completion = { menu = { auto_show = true }, ghost_text = { enabled = false } },
  },

  appearance = {
    nerd_font_variant = "normal",
    kind_icons = require("plugins.icons").symbol_icons,
  },

  completion = {
    accept = {
      auto_brackets = { enabled = true },
    },
    list = { selection = { preselect = false, auto_insert = true } },
    menu = {
      border = "none",
      scrollbar = false,
      draw = {
        treesitter = { "lsp" },
        columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 50,
      window = {
        border = "rounded",
        scrollbar = false,
      },
    },
  },
  signature = {
    enabled = false,
    window = {
      border = "none",
      show_documentation = true,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = { implementation = "prefer_rust" },
})
