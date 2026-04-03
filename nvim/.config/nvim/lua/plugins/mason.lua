require("mason").setup({
  ui = {
    border = "none",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

local map = vim.keymap.set

map("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>le", ":<C-u>lsp enable ", { desc = "Enable LSP" })

local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    map("n", "K", vim.lsp.buf.hover, opts)
    map("n", "<leader>lr", vim.lsp.buf.rename, opts)
    map("n", "<leader>rr", vim.lsp.codelens.run, opts)
    map("n", "<leader>rR", vim.lsp.codelens.refresh, opts)
  end,
})

-- Lua
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
      diagnostics = {
        globals = { "vim" },
      },
      telemetry = {
        enable = false,
      },
      workspace = {
        checkThirdParty = false,
      },
    },
  },
})

-- Rust
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      files = {
        excludeDirs = {
          ".direnv",
          ".git",
          "target",
        },
      },
      check = {
        command = "clippy",
        extraArgs = {
          "--no-deps",
        },
      },
    },
  },
})
