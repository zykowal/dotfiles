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

local lsp_package_mappings = {
  ["lua-language-server"] = "lua_ls",
  ["rust-analyzer"] = "rust_analyzer",
}

local lsp_package_names = {}
for package_name, config_name in pairs(lsp_package_mappings) do
  lsp_package_names[config_name] = package_name
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

local function get_lsp_configs(opts)
  local configs = vim.lsp.get_configs(opts or {})
  local by_name = {}

  for _, config in ipairs(configs) do
    by_name[config.name] = config
  end

  return configs, by_name
end

local function executable_from_cmd(cmd)
  if type(cmd) == "table" then
    return cmd[1]
  end

  if type(cmd) == "string" then
    return vim.split(cmd, "%s+")[1]
  end
end

local function is_config_available(config_name, configs_by_name, mason_registry)
  local package_name = lsp_package_names[config_name] or config_name
  local ok, package = pcall(mason_registry.get_package, package_name)
  if ok and package:is_installed() then
    return true
  end

  local config = configs_by_name[config_name]
  local executable = config and executable_from_cmd(config.cmd)
  return executable ~= nil and vim.fn.executable(executable) == 1
end

local function available_config_names(filetype)
  local ok, mason_registry = pcall(require, "mason-registry")
  if not ok then
    return {}, "Mason not loaded yet"
  end

  local configs, configs_by_name = get_lsp_configs(filetype and { filetype = filetype } or nil)
  local names = {}

  for _, config in ipairs(configs) do
    if is_config_available(config.name, configs_by_name, mason_registry) then
      names[#names + 1] = config.name
    end
  end

  table.sort(names)
  return names
end

map("n", "<leader>le", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local available, err = available_config_names(filetype)

  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if vim.tbl_isempty(available) then
    vim.notify("No available LSP configs for filetype: " .. filetype, vim.log.levels.WARN)
    return
  end

  vim.ui.select(available, {
    prompt = "LSP config to enable: ",
  }, function(choice)
    if not choice then
      return
    end

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
  local clients = current_client_names(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local configs, err = available_config_names(filetype)

  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

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

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    local opts = { buffer = args.buf, silent = true }
    map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
    map("n", "<leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))

    map("n", "[e", function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, vim.tbl_extend("force", opts, { desc = "Previous error" }))

    map("n", "]e", function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
    end, vim.tbl_extend("force", opts, { desc = "Next error" }))

    -- Lsp Document Highlight
    -- if client:supports_method("textDocument/documentHighlight") then
    --   local highlight_group = vim.api.nvim_create_augroup("UserLspDocumentHighlight", { clear = false })
    --
    --   vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    --     group = highlight_group,
    --     buffer = args.buf,
    --     callback = vim.lsp.buf.document_highlight,
    --   })
    --   vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
    --     group = highlight_group,
    --     buffer = args.buf,
    --     callback = vim.lsp.buf.clear_references,
    --   })
    -- end

    if client:supports_method("textDocument/inlayHint") then
      map("n", "<leader>lh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
      end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
    end

    if client:supports_method("textDocument/semanticTokens/full") then
      map("n", "<leader>lT", function()
        vim.lsp.semantic_tokens.enable(not vim.lsp.semantic_tokens.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
      end, vim.tbl_extend("force", opts, { desc = "Toggle semantic tokens" }))
    end
  end,
})

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
  capabilities = {
    offsetEncoding = { "utf-8" },
  },
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
      completion = {
        callSnippet = "Replace",
      },
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
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})

-- Rust
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        buildScripts = {
          enable = true,
        },
      },
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
      procMacro = {
        enable = true,
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
      completeUnimported = true,
      completeFunctionCalls = true,
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
