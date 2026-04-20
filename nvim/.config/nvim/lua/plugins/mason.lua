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
-- map("n", "<leader>le", ":<C-u>lsp enable ", { desc = "Enable LSP" })

-- Enable LSP
local lsp_mappings = {
    ['lua-language-server'] = 'lua_ls',
}

vim.keymap.set('n', '<leader>le', function()
  local mason_registry = require('mason-registry')

  if not mason_registry then
    vim.notify("Mason not loaded yet", vim.log.levels.WARN)
    return
  end

  local installed_lsp_servers = mason_registry.get_installed_package_names()

  if vim.fn.executable("rust-analyzer") == 1 then
    installed_lsp_servers[#installed_lsp_servers + 1] = "rust_analyzer"
  end

  if vim.tbl_isempty(installed_lsp_servers) then
    vim.notify("No LSP servers installed via Mason", vim.log.levels.WARN)
    return
  end

  vim.ui.select(installed_lsp_servers, {
    prompt = "LSP server to start: ",
  }, function(choice)
    if not choice then
      return
    end

    choice = lsp_mappings[choice] or choice

    local clients = vim.lsp.get_clients({ name = choice })
    if #clients > 0 then
      vim.notify(choice .. " is already running", vim.log.levels.INFO)
      return
    end

    vim.notify("Starting " .. choice .. " server", vim.log.levels.INFO)
    vim.cmd("lsp enable " .. choice)
  end)
end, { desc = "Enable LSP" })

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

-- Golang
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      analyses = {
        ST1003 = true,
        fieldalignment = false,
        fillreturns = true,
        nilness = true,
        nonewvars = true,
        shadow = true,
        undeclaredname = true,
        unreachable = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = {
        generate = true,
        regenerate_cgo = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      buildFlags = { "-tags", "integration" },
      completeUnimported = true,
      diagnosticsDelay = "500ms",
      gofumpt = true,
      matcher = "Fuzzy",
      semanticTokens = true,
      staticcheck = true,
      symbolMatcher = "fuzzy",
      usePlaceholders = true,
    },
  },
})
