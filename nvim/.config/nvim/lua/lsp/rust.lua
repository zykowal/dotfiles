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
