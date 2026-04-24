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

local lsp_attach_group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true })
local lsp_highlight_group = vim.api.nvim_create_augroup("UserLspDocumentHighlight", { clear = true })

map("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason" })

local function has_other_client(bufnr, method, client_id)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = method })) do
    if client.id ~= client_id then
      return true
    end
  end

  return false
end

local function current_client_names(bufnr)
  local names = {}
  local seen = {}

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.name and not seen[client.name] then
      seen[client.name] = true
      names[#names + 1] = client.name
    end
  end

  table.sort(names)
  return names
end

local lsp_mappings = {
    ['lua-language-server'] = 'lua_ls',
}

map("n", "<leader>le", function()
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
    if vim.lsp.is_enabled(choice) then
      vim.notify(choice .. " is already enabled", vim.log.levels.INFO)
      return
    end

    vim.lsp.enable(choice)
    vim.notify("Enabled LSP: " .. choice, vim.log.levels.INFO)
  end)
end, { desc = "Enable LSP" })

map("n", "<leader>lE", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = vim.lsp.get_configs({ enabled = true, filetype = vim.bo[bufnr].filetype })

  if vim.tbl_isempty(enabled) then
    vim.notify("No enabled LSP configs for this buffer", vim.log.levels.WARN)
    return
  end

  local config_names = {}
  for _, config in ipairs(enabled) do
    config_names[#config_names + 1] = config.name
  end
  table.sort(config_names)

  vim.ui.select(config_names, {
    prompt = "Disable LSP config: ",
  }, function(choice)
    if not choice then
      return
    end

    vim.lsp.enable(choice, false)
    vim.notify("Disabled LSP config: " .. choice, vim.log.levels.INFO)
  end)
end, { desc = "Disable LSP" })

map("n", "<leader>li", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local configs = require('mason-registry').get_installed_package_names()
  local clients = current_client_names(bufnr)
  local filetype = vim.bo[bufnr].filetype

  if vim.tbl_isempty(configs) then
    vim.notify("No LSP configs for filetype: " .. filetype, vim.log.levels.WARN)
    return
  end

  local enabled = {}
  local disabled = {}
  for _, name in ipairs(configs) do
    if vim.lsp.is_enabled(name) then
      enabled[#enabled + 1] = name
    else
      disabled[#disabled + 1] = name
    end
  end

  local lines = {
    "filetype: " .. filetype,
    "enabled configs: " .. (#enabled > 0 and table.concat(enabled, ", ") or "none"),
    "attached clients: " .. (#clients > 0 and table.concat(clients, ", ") or "none"),
  }

  if #disabled > 0 then
    lines[#lines + 1] = "available configs: " .. table.concat(disabled, ", ")
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Status" })
end, { desc = "LSP status" })

local capabilities = require("blink.cmp").get_lsp_capabilities()

if capabilities.workspace and capabilities.workspace.didChangeWatchedFiles then
  capabilities.workspace.didChangeWatchedFiles = nil
end

vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_attach_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local opts = { buffer = args.buf }
    map("n", "K", vim.lsp.buf.hover, opts)
    map("n", "<leader>lr", vim.lsp.buf.rename, opts)

    map("n", "[e", function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, vim.tbl_extend("force", opts, { desc = "Previous error" }))

    map("n", "]e", function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, vim.tbl_extend("force", opts, { desc = "Next error" }))

    map("n", "<leader>lh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
    end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))

    map("n", "<leader>lT", function()
      vim.lsp.semantic_tokens.enable(not vim.lsp.semantic_tokens.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
    end, vim.tbl_extend("force", opts, { desc = "Toggle semantic tokens" }))

    -- if client and client:supports_method("textDocument/documentHighlight", args.buf) then
    --   vim.api.nvim_clear_autocmds({ group = lsp_highlight_group, buffer = args.buf })
    --
    --   vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    --     group = lsp_highlight_group,
    --     buffer = args.buf,
    --     callback = vim.lsp.buf.document_highlight,
    --   })
    --
    --   vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    --     group = lsp_highlight_group,
    --     buffer = args.buf,
    --     callback = vim.lsp.buf.clear_references,
    --   })
    -- end
  end,
})

-- vim.api.nvim_create_autocmd("LspDetach", {
--   group = lsp_attach_group,
--   callback = function(args)
--     if not args.data or not args.data.client_id then
--       return
--     end
--
--     if not has_other_client(args.buf, "textDocument/documentHighlight", args.data.client_id) then
--       vim.api.nvim_clear_autocmds({ group = lsp_highlight_group, buffer = args.buf })
--       pcall(vim.api.nvim_buf_call, args.buf, vim.lsp.buf.clear_references)
--     end
--   end,
-- })

-- C/C++
vim.lsp.config("clangd", {
  root_markers = {
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac",
    "Makefile",
    "configure.in",
    "config.h.in",
    "meson.build",
    "meson_options.txt",
    "build.ninja",
    ".git",
  },
  capabilities = vim.tbl_deep_extend("force", {}, capabilities, {
    offsetEncoding = { "utf-8" },
  }),
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
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
