local map = vim.keymap.set
local fzf = require("fzf-lua")

fzf.setup({
  {
    "fzf-native",
    "border-fused",
    "hide",
  },
  lsp = {
    symbols = {
      symbol_icons = require("plugins.icons").symbol_icons,
    },
  },
  winopts = {
    fullscreen = true,
    height = 1,
    width = 1,
    row = 1,
    col = 0,
    border = "border-top",
    title_pos = "left",
    treesitter = false,
    preview = {
      hidden = true,
      scrollbar = false,
      layout = "horizontal",
      horizontal = "up:62%",
    },
  },
  defaults = {
    git_icons = false,
    file_icons = false,
  },
  git = {
    hunks = {
      fzf_opts = {
        ["--layout"] = "reverse-list",
        ["--multi"] = true,
        ["--delimiter"] = ":",
        ["--nth"] = "3..",
      },
    },
  },
  fzf_opts = {
    ["--layout"] = "default",
  },
  keymap = {
    builtin = {
      true,
      ["<C-n>"] = "preview-page-down",
      ["<C-p>"] = "preview-page-up",
      ["<C-l>"] = "toggle-preview",
    },
    fzf = {
      true,
      ["ctrl-n"] = "preview-page-down",
      ["ctrl-p"] = "preview-page-up",
      ["ctrl-d"] = "half-page-down",
      ["ctrl-u"] = "half-page-up",
      ["ctrl-l"] = "toggle-preview",
      ["ctrl-q"] = "select-all+accept",
    },
  },
  fzf_colors = {
    true,
    bg = "-1",
    gutter = "-1",
  },
})

fzf.register_ui_select()

map("n", "<c-f>", function()
  fzf.files()
end, { desc = "Find files" })

map("n", "<leader>/", function()
  fzf.grep_curbuf()
end, { desc = "Find in current buffer" })

map("n", "<leader>.", function()
  fzf.buffers()
end, { desc = "Buffers" })

map("n", "gd", function()
  fzf.lsp_definitions({ jump1 = true })
end, { desc = "Definitions" })

map("n", "gI", function()
  fzf.lsp_implementations()
end, { desc = "Implementations" })

map("n", "gy", function()
  fzf.lsp_typedefs()
end, { desc = "Type definitions" })

map("n", "gp", function()
  fzf.lsp_finder()
end, { desc = "LSP finder" })

map("n", "gh", function()
  fzf.lsp_type_sub()
end, { desc = "Show subtypes" })

map("n", "gH", function()
  fzf.lsp_type_super()
end, { desc = "Show supertypes" })

map("n", "gr", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/references" })
  if #clients > 0 then
    fzf.lsp_references()
  else
    fzf.grep_cword()
  end
end, { desc = "Search references" })

map("n", "gD", function()
  fzf.lsp_declarations()
end, { desc = "Search declarations" })

map("n", "<leader>gb", function()
  fzf.git_branches()
end, { desc = "Git branches" })

map("n", "<leader>gc", function()
  fzf.git_commits()
end, { desc = "Git commits (repository)" })

map("n", "<leader>gC", function()
  fzf.git_bcommits()
end, { desc = "Git commits (current file)" })

map("n", "<leader>gD", function()
  fzf.git_diff()
end, { desc = "Git diff" })

map("n", "<leader>gh", function()
  fzf.git_hunks()
end, { desc = "Git hunks" })

map("n", "<leader>gt", function()
  fzf.git_status()
end, { desc = "Git status" })

map("n", "<leader>gw", function()
  fzf.git_worktrees()
end, { desc = "Git worktrees" })

map("n", "<leader>gA", function()
  fzf.git_stash()
end, { desc = "Git stash" })

map("n", "<leader>ga", function()
  fzf.git_tags()
end, { desc = "Git tags" })

map("i", "<C-x><C-f>", function()
  fzf.complete_path()
end, { desc = "Fuzzy complete path" })

map("n", "<leader>f<CR>", function()
  fzf.resume()
end, { desc = "Resume previous search" })

map("n", "<leader>f'", function()
  fzf.marks()
end, { desc = "Find marks" })

map("n", "<leader>fa", function()
  fzf.files({ prompt = "Config> ", cwd = vim.fn.stdpath("config") })
end, { desc = "Find config files" })

map("n", "<leader>fb", function()
  fzf.buffers()
end, { desc = "Find buffers" })

map("n", "<leader>fc", function()
  fzf.grep_cword()
end, { desc = "Find word under cursor" })

map("n", "<leader>fC", function()
  fzf.commands()
end, { desc = "Find commands" })

map("n", "<leader>ff", function()
  fzf.files()
end, { desc = "Find files" })

map("n", "<leader>fh", function()
  fzf.helptags()
end, { desc = "Find help" })

map("n", "<leader>fk", function()
  fzf.keymaps({
    winopts = {
      preview = {
        layout = "horizontal",
        horizontal = "right:62%",
      },
    },
  })
end, { desc = "Find keymaps" })

map("n", "<leader>fm", function()
  fzf.marks()
end, { desc = "Find marks" })

map("n", "<leader>fM", function()
  fzf.manpages()
end, { desc = "Find man" })

map("n", "<leader>fo", function()
  fzf.oldfiles()
end, { desc = "Find history" })

map("n", "<leader>fr", function()
  fzf.registers()
end, { desc = "Find registers" })

map("n", '<leader>f"', function()
  fzf.registers()
end, { desc = "Find registers" })

map("n", "<leader>fT", function()
  fzf.colorschemes()
end, { desc = "Find themes" })

map("n", "<leader>fw", function()
  fzf.grep_project()
end, { desc = "Find words" })

map("v", "<leader>fc", function()
  fzf.grep_visual()
end, { desc = "Find selection" })

map("n", "<leader>ls", function()
  fzf.lsp_document_symbols()
end, { desc = "Search symbols" })

map("n", "<leader>lS", function()
  fzf.lsp_live_workspace_symbols()
end, { desc = "Search workspace symbols" })

map("n", "<leader>:", function()
  fzf.command_history()
end, { desc = "Command history" })

map("n", "<leader>,", function()
  fzf.live_grep_native()
end, { desc = "Find words" })

map("n", "<leader>fH", function()
  fzf.highlights()
end, { desc = "Find highlights" })

map("n", "<leader>fj", function()
  fzf.jumps()
end, { desc = "Find jumps" })

map("n", "<leader>fu", function()
  fzf.changes()
end, { desc = "Find changes" })

map("n", "<leader>fA", function()
  fzf.autocmds()
end, { desc = "Find autocmds" })

map("n", "<leader>fd", function()
  fzf.diagnostics_document()
end, { desc = "Document diagnostics" })

map("n", "<leader>fD", function()
  fzf.diagnostics_workspace()
end, { desc = "Workspace diagnostics" })

map("n", "<leader>la", function()
  fzf.lsp_code_actions()
end, { desc = "Code actions" })

map("n", "<leader>fq", function()
  fzf.quickfix()
end, { desc = "Find quickfix" })

map("n", "<leader>fQ", function()
  fzf.quickfix_stack()
end, { desc = "Find quickfix stack" })

map("n", "<leader>ft", function()
  fzf.tabs()
end, { desc = "Find tabs" })

map("n", "<leader>fL", function()
  fzf.tags_live_grep()
end, { desc = "Find tags" })

map("n", "<leader>fl", function()
  fzf.grep()
end, { desc = "Grep pattern" })

map("n", "<leader>fg", function()
  fzf.vcs_files()
end, { desc = "Search git files" })

map("n", "<leader>f/", function()
  fzf.search_history()
end, { desc = "Search history" })

map("n", "z=", function()
  fzf.spell_suggest({
    winopts = {
      border = "rounded",
      fullscreen = false,
    },
  })
end, { desc = "Spell suggest" })

map("n", "<leader>fz", function()
  fzf.zoxide()
end, { desc = "Find zoxide" })
