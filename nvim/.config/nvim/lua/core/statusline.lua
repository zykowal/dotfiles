local M = {}

local NONE = "NONE"
local fn = vim.fn
local api = vim.api

local palette = {
  light_green = "#a9b665",
  green = "#89b482",
  pink = "#d3869b",
  diag_error = "#f38ba8",
  diag_hint = "#94e2d5",
  diag_info = "#89dceb",
  diag_warn = "#f9e2af",
  git_add = "#a6e3a1",
  git_change = "#f9e2af",
  git_delete = "#f38ba8",
  git_branch = "#c099ff",
}

local mode_icons = {
  n = " NORMAL",
  no = " O-PENDING",
  nov = " O-PENDING",
  noV = " O-PENDING",
  ["no\22"] = " O-PENDING",
  niI = " NORMAL",
  niR = " NORMAL",
  niV = " NORMAL",
  nt = " NORMAL",
  v = " VISUAL",
  V = " V-LINE",
  ["\22"] = " V-BLOCK",
  ["\22s"] = " V-BLOCK",
  s = " SELECT",
  S = " S-LINE",
  ["\19"] = " S-BLOCK",
  i = " INSERT",
  ic = " INSERT",
  ix = " INSERT",
  R = " REPLACE",
  Rc = " REPLACE",
  Rx = " REPLACE",
  Rv = " V-REPLACE",
  c = " COMMAND",
  cv = " VIM EX",
  ce = " EX",
  r = " PROMPT",
  rm = " MORE",
  ["r?"] = " CONFIRM",
  ["!"] = " SHELL",
  t = " TERMINAL",
}

local function hi(group, opts)
  api.nvim_set_hl(0, group, opts)
end

local function set_highlights()
  hi("StatusLine", { bg = NONE, fg = NONE })
  hi("StatusLineNC", { bg = NONE, fg = NONE })
  hi("StatusMode", { bg = NONE, fg = palette.light_green, bold = true })
  hi("StatusModeSep", { bg = NONE, fg = palette.green })

  hi("StatusGit", { bg = NONE, fg = palette.git_branch, bold = true })
  hi("StatusGitSep", { bg = NONE, fg = palette.pink })
  hi("StatusDiffAdd", { bg = NONE, fg = palette.git_add, bold = true })
  hi("StatusDiffChange", { bg = NONE, fg = palette.git_change, bold = true })
  hi("StatusDiffDelete", { bg = NONE, fg = palette.git_delete, bold = true })

  hi("StatusFile", { bg = NONE, fg = NONE })
  hi("StatusFileSep", { bg = NONE, fg = NONE })
  hi("StatusDiag", { bg = NONE, fg = NONE, bold = true })
  hi("StatusDiagSep", { bg = NONE, fg = NONE })
  hi("StatusError", { bg = NONE, fg = palette.diag_error, bold = true })
  hi("StatusWarn", { bg = NONE, fg = palette.diag_warn, bold = true })
  hi("StatusInfo", { bg = NONE, fg = palette.diag_info, bold = true })
  hi("StatusHint", { bg = NONE, fg = palette.diag_hint })

  hi("StatusMeta", { bg = NONE, fg = NONE })
  hi("StatusLocation", { bg = NONE, fg = NONE })
  hi("StatusPercent", { bg = NONE, fg = NONE })
end

local function section(group, text)
  if text == nil or text == "" then
    return ""
  end
  return "%#" .. group .. "# " .. text .. " "
end

local function separator(group)
  return "%#" .. group .. "#"
end

local function set_buf_cache(bufnr, key, value)
  if api.nvim_buf_is_valid(bufnr) then
    vim.b[bufnr][key] = value
  end
end

local function get_buf_cache(bufnr, key)
  if not api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  return vim.b[bufnr][key] or ""
end

local function update_diagnostics(bufnr)
  if not vim.diagnostic or not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local diagnostics = vim.diagnostic.get(bufnr)
  if vim.tbl_isempty(diagnostics) then
    set_buf_cache(bufnr, "statusline_diagnostics", "")
    return
  end

  local count = {
    [vim.diagnostic.severity.ERROR] = 0,
    [vim.diagnostic.severity.WARN] = 0,
    [vim.diagnostic.severity.INFO] = 0,
    [vim.diagnostic.severity.HINT] = 0,
  }

  for _, item in ipairs(diagnostics) do
    count[item.severity] = (count[item.severity] or 0) + 1
  end

  local parts = {}
  if count[vim.diagnostic.severity.ERROR] > 0 then
    parts[#parts + 1] = "%#StatusError# " .. count[vim.diagnostic.severity.ERROR] .. " "
  end
  if count[vim.diagnostic.severity.WARN] > 0 then
    parts[#parts + 1] = "%#StatusWarn# " .. count[vim.diagnostic.severity.WARN] .. " "
  end
  if count[vim.diagnostic.severity.INFO] > 0 then
    parts[#parts + 1] = "%#StatusInfo# " .. count[vim.diagnostic.severity.INFO] .. " "
  end
  if count[vim.diagnostic.severity.HINT] > 0 then
    parts[#parts + 1] = "%#StatusHint# " .. count[vim.diagnostic.severity.HINT] .. " "
  end

  set_buf_cache(bufnr, "statusline_diagnostics", table.concat(parts))
end

local function update_lsp(bufnr)
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  if not get_clients or not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local clients = get_clients({ bufnr = bufnr })
  if vim.tbl_isempty(clients) then
    set_buf_cache(bufnr, "statusline_lsp", "")
    return
  end

  local names = {}
  local seen = {}
  for _, client in ipairs(clients) do
    if client.name and not seen[client.name] then
      seen[client.name] = true
      names[#names + 1] = client.name
    end
  end

  if vim.tbl_isempty(names) then
    set_buf_cache(bufnr, "statusline_lsp", "")
    return
  end

  set_buf_cache(bufnr, "statusline_lsp", " " .. table.concat(names, ", "))
end

local function get_git_status()
  local head = vim.b.gitsigns_head
  if not head or head == "" then
    return "", ""
  end

  local status = vim.b.gitsigns_status_dict or {}
  local root = status.root and fn.fnamemodify(status.root, ":t") or nil
  local branch = root and (root .. "/" .. head) or head

  local diff = {}
  if (status.added or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffAdd#+" .. status.added .. " "
  end
  if (status.changed or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffChange#~" .. status.changed .. " "
  end
  if (status.removed or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffDelete#-" .. status.removed .. " "
  end

  return branch, table.concat(diff)
end

local function get_diagnostics()
  return get_buf_cache(api.nvim_get_current_buf(), "statusline_diagnostics")
end

local function file_label()
  local filename = fn.expand("%:t")
  if filename == "" then
    return ""
  end

  local parent = fn.expand("%:p:h:t")
  local label = filename
  if parent ~= "" and parent ~= "." then
    label = parent .. "/" .. filename
  end

  if vim.bo.modified then
    return label .. "[+]"
  end
  return label
end

local function file_encoding()
  local encoding = vim.bo.fileencoding
  if encoding == nil or encoding == "" then
    encoding = vim.o.encoding
  end
  return encoding
end

local function lsp_label()
  return get_buf_cache(api.nvim_get_current_buf(), "statusline_lsp")
end

function M.build()
  local parts = {}

  local mode = fn.mode(1)
  parts[#parts + 1] = section("StatusMode", mode_icons[mode] or mode)
  parts[#parts + 1] = separator("StatusModeSep")

  local file = file_label()
  if file ~= "" then
    parts[#parts + 1] = section("StatusFile", file)
    parts[#parts + 1] = separator("StatusFileSep")
  end

  local branch, diff = get_git_status()
  if branch ~= "" then
    parts[#parts + 1] = section("StatusGit", " " .. branch)
    parts[#parts + 1] = separator("StatusGitSep")
    if diff ~= "" then
      parts[#parts + 1] = diff
      parts[#parts + 1] = separator("StatusGitSep")
    end
  end

  local diagnostics = get_diagnostics()
  if diagnostics ~= "" then
    parts[#parts + 1] = section("StatusDiag", diagnostics)
    parts[#parts + 1] = separator("StatusDiagSep")
  end

  parts[#parts + 1] = "%="

  local lsp = lsp_label()
  if lsp ~= "" then
    parts[#parts + 1] = section("StatusMeta", lsp)
  end

  local filetype = vim.bo.filetype
  if filetype ~= "" then
    parts[#parts + 1] = section("StatusMeta", filetype)
  end

  parts[#parts + 1] = section("StatusMeta", file_encoding() .. " " .. vim.bo.fileformat)
  parts[#parts + 1] = section("StatusLocation", "%l:%c")
  parts[#parts + 1] = section("StatusPercent", "%p%%")

  return table.concat(parts)
end

set_highlights()

local statusline_group = api.nvim_create_augroup("UserStatuslineCache", { clear = true })

api.nvim_create_autocmd("ColorScheme", {
  callback = set_highlights,
})

api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
  group = statusline_group,
  callback = function(args)
    update_diagnostics(args.buf)
  end,
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach", "BufEnter" }, {
  group = statusline_group,
  callback = function(args)
    update_lsp(args.buf)
  end,
})

api.nvim_create_autocmd("BufDelete", {
  group = statusline_group,
  callback = function(args)
    vim.b[args.buf].statusline_diagnostics = nil
    vim.b[args.buf].statusline_lsp = nil
  end,
})

for _, bufnr in ipairs(api.nvim_list_bufs()) do
  if api.nvim_buf_is_loaded(bufnr) then
    update_diagnostics(bufnr)
    update_lsp(bufnr)
  end
end

_G.StatuslineBuild = function()
  return require("core.statusline").build()
end

vim.o.statusline = "%!v:lua.StatuslineBuild()"

return M
