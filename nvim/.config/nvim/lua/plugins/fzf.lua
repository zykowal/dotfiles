local function fzf_call(method, opts)
  return function()
    require("fzf-lua")[method](opts)
  end
end

local function workspace_symbols_or_grep()
  local fzf = require("fzf-lua")

  if #vim.lsp.get_clients({ bufnr = 0, method = "workspace/symbol" }) > 0 then
    fzf.lsp_live_workspace_symbols()
    return
  end

  fzf.live_grep_native()
end

local function references_or_cword()
  local fzf = require("fzf-lua")

  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/references" }) > 0 then
    fzf.lsp_references()
    return
  end

  fzf.grep_cword()
end

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    { "<C-e>", workspace_symbols_or_grep, desc = "Workspace symbols or grep" },
    { "<C-f>", fzf_call("files"), desc = "Find files" },
    { "<leader>/", fzf_call("grep_curbuf"), desc = "Find in current buffer" },
    { "<leader>.", fzf_call("buffers"), desc = "Buffers" },
    { "gd", fzf_call("lsp_definitions", { jump1 = true }), desc = "Definitions" },
    { "gI", fzf_call("lsp_implementations"), desc = "Implementations" },
    { "gy", fzf_call("lsp_typedefs"), desc = "Type definitions" },
    { "gp", fzf_call("lsp_finder"), desc = "LSP finder" },
    { "gh", fzf_call("lsp_type_sub"), desc = "Show subtypes" },
    { "gH", fzf_call("lsp_type_super"), desc = "Show supertypes" },
    { "gr", references_or_cword, desc = "Search references" },
    { "gD", fzf_call("lsp_declarations"), desc = "Search declarations" },
    { "<leader>gb", fzf_call("git_branches"), desc = "Git branches" },
    { "<leader>gc", fzf_call("git_commits"), desc = "Git commits (repository)" },
    { "<leader>gC", fzf_call("git_bcommits"), desc = "Git commits (current file)" },
    { "<leader>gD", fzf_call("git_diff"), desc = "Git diff" },
    { "<leader>gh", fzf_call("git_hunks"), desc = "Git hunks" },
    { "<leader>gt", fzf_call("git_status"), desc = "Git status" },
    { "<leader>gw", fzf_call("git_worktrees"), desc = "Git worktrees" },
    { "<leader>gA", fzf_call("git_stash"), desc = "Git stash" },
    { "<leader>ga", fzf_call("git_tags"), desc = "Git tags" },
    { "<C-x><C-f>", fzf_call("complete_path"), mode = "i", desc = "Fuzzy complete path" },
    { "<leader>f<CR>", fzf_call("resume"), desc = "Resume previous search" },
    { "<leader>f'", fzf_call("marks"), desc = "Find marks" },
    {
      "<leader>fa",
      function()
        require("fzf-lua").files({ prompt = "Config> ", cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find config files",
    },
    { "<leader>fb", fzf_call("buffers"), desc = "Find buffers" },
    { "<leader>fc", fzf_call("grep_cword"), desc = "Find word under cursor" },
    { "<leader>fC", fzf_call("commands"), desc = "Find commands" },
    { "<leader>ff", fzf_call("files"), desc = "Find files" },
    { "<leader>fh", fzf_call("helptags"), desc = "Find help" },
    {
      "<leader>fk",
      function()
        require("fzf-lua").keymaps({
          winopts = {
            preview = {
              layout = "horizontal",
              horizontal = "right:62%",
            },
          },
        })
      end,
      desc = "Find keymaps",
    },
    { "<leader>fm", fzf_call("marks"), desc = "Find marks" },
    { "<leader>fM", fzf_call("manpages"), desc = "Find man" },
    { "<leader>fo", fzf_call("oldfiles"), desc = "Find history" },
    { "<leader>fr", fzf_call("registers"), desc = "Find registers" },
    { '<leader>f"', fzf_call("registers"), desc = "Find registers" },
    { "<leader>fT", fzf_call("colorschemes"), desc = "Find themes" },
    { "<leader>fw", fzf_call("grep_project"), desc = "Find words" },
    { "<leader>fc", fzf_call("grep_visual"), mode = "v", desc = "Find selection" },
    { "<leader>ls", fzf_call("lsp_document_symbols"), desc = "Search symbols" },
    { "<leader>lS", fzf_call("lsp_live_workspace_symbols"), desc = "Search workspace symbols" },
    { "<leader>:", fzf_call("command_history"), desc = "Command history" },
    { "<leader>,", fzf_call("live_grep_native"), desc = "Find words" },
    { "<leader>fH", fzf_call("highlights"), desc = "Find highlights" },
    { "<leader>fj", fzf_call("jumps"), desc = "Find jumps" },
    { "<leader>fu", fzf_call("changes"), desc = "Find changes" },
    { "<leader>fA", fzf_call("autocmds"), desc = "Find autocmds" },
    { "<leader>fd", fzf_call("diagnostics_document"), desc = "Document diagnostics" },
    { "<leader>fD", fzf_call("diagnostics_workspace"), desc = "Workspace diagnostics" },
    { "<leader>la", fzf_call("lsp_code_actions"), desc = "Code actions" },
    { "<leader>fq", fzf_call("quickfix"), desc = "Find quickfix" },
    { "<leader>fQ", fzf_call("quickfix_stack"), desc = "Find quickfix stack" },
    {
      "<leader>ft",
      function()
        require("fzf-lua").grep({
          search = [[\b(TODO|NOTE|FIX|FIXME|HACK|PERF|OPTIMIZE|BUG|XXX)\b]],
          no_esc = true,
          prompt = "TODO> ",
        })
      end,
      desc = "Find TODO tags",
    },
    { "<leader>fL", fzf_call("tags_live_grep"), desc = "Find tags" },
    { "<leader>fl", fzf_call("grep"), desc = "Grep pattern" },
    { "<leader>fg", fzf_call("vcs_files"), desc = "Search git files" },
    { "<leader>f/", fzf_call("search_history"), desc = "Search history" },
    {
      "z=",
      function()
        require("fzf-lua").spell_suggest({
          winopts = {
            border = "rounded",
            fullscreen = false,
          },
        })
      end,
      desc = "Spell suggest",
    },
    { "<leader>fz", fzf_call("zoxide"), desc = "Find zoxide" },
  },
  opts = {
    {
      "fzf-native",
      "border-fused",
      "hide",
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
        flip_columns = 120,
      },
    },
    defaults = {
      git_icons = false,
      file_icons = false,
    },
    oldfiles = {
      cwd_only = true,
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
      ["--cycle"] = true,
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
  },
  config = function(_, opts)
    local fzf = require("fzf-lua")

    fzf.setup(opts)
    fzf.register_ui_select()
  end,
}
