-- Custom statusline implementation with dynamic mode, git, diagnostics, and LSP info
local M = {}
local H = {}

local NONE = "NONE"
local fn = vim.fn
local api = vim.api

-- Localized frequently used API for performance and clarity
local nvim_set_hl = api.nvim_set_hl
local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_buf_is_loaded = api.nvim_buf_is_loaded
local nvim_list_bufs = api.nvim_list_bufs
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd

local diagnostic_get = vim.diagnostic.get
local diagnostic_severity = vim.diagnostic.severity
local lsp_get_clients = vim.lsp.get_clients

local tbl_isempty = vim.tbl_isempty
local fn_expand = fn.expand
local fn_fnamemodify = fn.fnamemodify
local table_concat = table.concat
local nvim_get_current_buf = api.nvim_get_current_buf
local nvim_get_mode = api.nvim_get_mode

local palette = {
  light_green = "#a9b665",
  green = "#89b482",
  pink = "#d3869b",
  blue = "#7daea3",
  yellow = "#d8a657",
  orange = "#e78a4e",
  red = "#ea6962",
  aqua = "#7fb4ca",
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
  nvim_set_hl(0, group, opts)
end

local mode_highlight_map = {
  n = "StatusModeNormal",
  no = "StatusModeNormal",
  nov = "StatusModeNormal",
  noV = "StatusModeNormal",
  ["no\22"] = "StatusModeNormal",
  niI = "StatusModeNormal",
  niR = "StatusModeNormal",
  niV = "StatusModeNormal",
  nt = "StatusModeNormal",
  v = "StatusModeVisual",
  V = "StatusModeVisual",
  ["\22"] = "StatusModeVisual",
  ["\22s"] = "StatusModeVisual",
  s = "StatusModeSelect",
  S = "StatusModeSelect",
  ["\19"] = "StatusModeSelect",
  i = "StatusModeInsert",
  ic = "StatusModeInsert",
  ix = "StatusModeInsert",
  R = "StatusModeReplace",
  Rc = "StatusModeReplace",
  Rx = "StatusModeReplace",
  Rv = "StatusModeReplace",
  c = "StatusModeCommand",
  cv = "StatusModeCommand",
  ce = "StatusModeCommand",
  r = "StatusModePrompt",
  rm = "StatusModePrompt",
  ["r?"] = "StatusModePrompt",
  ["!"] = "StatusModeShell",
  t = "StatusModeTerminal",
}

local function mode_highlight(mode)
  return mode_highlight_map[mode] or "StatusModeNormal"
end

-- Create default highlights (kept local hi helper)
H.create_default_hl = function()
  hi("StatusLine", { bg = NONE, fg = NONE })
  hi("StatusLineNC", { bg = NONE, fg = NONE })
  hi("StatusModeNormal", { bg = NONE, fg = palette.light_green, bold = true })
  hi("StatusModeInsert", { bg = NONE, fg = palette.blue, bold = true })
  hi("StatusModeVisual", { bg = NONE, fg = palette.yellow, bold = true })
  hi("StatusModeSelect", { bg = NONE, fg = palette.orange, bold = true })
  hi("StatusModeReplace", { bg = NONE, fg = palette.red, bold = true })
  hi("StatusModeCommand", { bg = NONE, fg = palette.pink, bold = true })
  hi("StatusModePrompt", { bg = NONE, fg = palette.aqua, bold = true })
  hi("StatusModeShell", { bg = NONE, fg = palette.diag_warn, bold = true })
  hi("StatusModeTerminal", { bg = NONE, fg = palette.git_add, bold = true })
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

-- Section helpers
H.section = function(group, text)
  if text == nil or text == "" then
    return ""
  end
  return "%#" .. group .. "# " .. text .. " "
end

H.separator = function(group)
  return "%#" .. group .. "#"
end

-- Buffer-local cache helpers
H.set_buf_cache = function(bufnr, key, value)
  if nvim_buf_is_valid(bufnr) then
    vim.b[bufnr][key] = value
  end
end

H.get_buf_cache = function(bufnr, key)
  if not nvim_buf_is_valid(bufnr) then
    return ""
  end
  return vim.b[bufnr][key] or ""
end

-- Update diagnostics cache for a buffer
H.update_diagnostics = function(bufnr)
  if not nvim_buf_is_valid(bufnr) then
    return
  end

  local diagnostics = diagnostic_get(bufnr)
  if tbl_isempty(diagnostics) then
    H.set_buf_cache(bufnr, "statusline_diagnostics", "")
    return
  end

  local count = {
    [diagnostic_severity.ERROR] = 0,
    [diagnostic_severity.WARN] = 0,
    [diagnostic_severity.INFO] = 0,
    [diagnostic_severity.HINT] = 0,
  }

  for _, item in ipairs(diagnostics) do
    count[item.severity] = (count[item.severity] or 0) + 1
  end

  local parts = {}
  if count[diagnostic_severity.ERROR] > 0 then
    parts[#parts + 1] = "%#StatusError# " .. count[diagnostic_severity.ERROR] .. " "
  end
  if count[diagnostic_severity.WARN] > 0 then
    parts[#parts + 1] = "%#StatusWarn# " .. count[diagnostic_severity.WARN] .. " "
  end
  if count[diagnostic_severity.INFO] > 0 then
    parts[#parts + 1] = "%#StatusInfo# " .. count[diagnostic_severity.INFO] .. " "
  end
  if count[diagnostic_severity.HINT] > 0 then
    parts[#parts + 1] = "%#StatusHint# " .. count[diagnostic_severity.HINT] .. " "
  end

  H.set_buf_cache(bufnr, "statusline_diagnostics", table.concat(parts))
end

-- Update LSP cache for a buffer
H.update_lsp = function(bufnr)
  if not nvim_buf_is_valid(bufnr) then
    return
  end

  local clients = lsp_get_clients({ bufnr = bufnr })
  if tbl_isempty(clients) then
    H.set_buf_cache(bufnr, "statusline_lsp", "")
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

  if tbl_isempty(names) then
    H.set_buf_cache(bufnr, "statusline_lsp", "")
    return
  end

  H.set_buf_cache(bufnr, "statusline_lsp", " " .. table.concat(names, ", "))
end

-- Git info helper
H.get_git_status = function()
  local head = vim.b.gitsigns_head
  if not head or head == "" then
    return "", ""
  end

  local status = vim.b.gitsigns_status_dict or {}
  local root = status.root and fn_fnamemodify(status.root, ":t") or nil
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

  return branch, table_concat(diff)
end

H.get_diagnostics = function()
  return H.get_buf_cache(nvim_get_current_buf(), "statusline_diagnostics")
end

-- File label and metadata helpers
H.file_label = function()
  local filename = fn_expand("%:t")
  if filename == "" then
    return ""
  end

  local parent = fn_expand("%:p:h:t")
  local label = filename
  if parent ~= "" and parent ~= "." then
    label = parent .. "/" .. filename
  end

  if vim.bo.modified then
    return label .. "[+]"
  end
  return label
end

H.file_encoding = function()
  local encoding = vim.bo.fileencoding
  if encoding == nil or encoding == "" then
    encoding = vim.o.encoding
  end
  return encoding
end

H.lsp_label = function()
  return H.get_buf_cache(nvim_get_current_buf(), "statusline_lsp")
end

H.get_filesize = function()
  local size = math.max(fn.line2byte(fn.line('$') + 1) - 1, 0)
  if size < 1024 then
    return string.format('%dB', size)
  end

  local function fmt(val, unit)
    local s = string.format('%.1f', val)
    -- drop trailing .0
    s = s:gsub('%.0$', '')
    return s .. unit
  end

  if size < 1024 * 1024 then
    return fmt(size / 1024, 'KiB')
  end

  return fmt(size / (1024 * 1024), 'MiB')
end

function M.build()
  local parts = {}

  local mode = (nvim_get_mode() or {}).mode or fn.mode(1)
  parts[#parts + 1] = H.section(mode_highlight(mode), mode_icons[mode] or mode)
  parts[#parts + 1] = H.separator("StatusModeSep")

  local file = H.file_label()
  if file ~= "" then
    parts[#parts + 1] = H.section("StatusFile", file)
    parts[#parts + 1] = H.separator("StatusFileSep")
  end

  local branch, diff = H.get_git_status()
  if branch ~= "" then
    parts[#parts + 1] = H.section("StatusGit", " " .. branch)
    parts[#parts + 1] = H.separator("StatusGitSep")
    if diff ~= "" then
      parts[#parts + 1] = diff
      parts[#parts + 1] = H.separator("StatusGitSep")
    end
  end

  local diagnostics = H.get_diagnostics()
  if diagnostics ~= "" then
    parts[#parts + 1] = H.section("StatusDiag", diagnostics)
    parts[#parts + 1] = H.separator("StatusDiagSep")
  end

  parts[#parts + 1] = "%="

  local lsp = H.lsp_label()
  if lsp ~= "" then
    parts[#parts + 1] = H.section("StatusMeta", lsp)
  end

  -- Compose meta: show filetype only when present, otherwise just encoding|format
  local ft = vim.bo.filetype or ""
  local meta = (ft ~= "" and ft .. "|" or "") .. H.file_encoding() .. "|" .. vim.bo.fileformat
  parts[#parts + 1] = H.section("StatusMeta", meta)
  parts[#parts + 1] = H.section("StatusMeta", H.get_filesize())
  parts[#parts + 1] = H.section("StatusLocation", "%l:%c")
  parts[#parts + 1] = H.section("StatusPercent", "%p%%")

  return table_concat(parts)
end

-- Setup autocommands and initialize cache
H.create_autocommands = function()
  local statusline_group = nvim_create_augroup("UserStatuslineCache", { clear = true })

  nvim_create_autocmd("ColorScheme", {
    callback = H.create_default_hl,
  })

  nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = statusline_group,
    callback = function(args)
      H.update_diagnostics(args.buf)
    end,
  })

  nvim_create_autocmd({ "LspAttach", "LspDetach", "BufEnter" }, {
    group = statusline_group,
    callback = function(args)
      H.update_lsp(args.buf)
    end,
  })

  nvim_create_autocmd("BufDelete", {
    group = statusline_group,
    callback = function(args)
      vim.b[args.buf].statusline_diagnostics = nil
      vim.b[args.buf].statusline_lsp = nil
    end,
  })

  for _, bufnr in ipairs(nvim_list_bufs()) do
    if nvim_buf_is_loaded(bufnr) then
      H.update_diagnostics(bufnr)
      H.update_lsp(bufnr)
    end
  end
end


-- Public setup to initialize statusline module
M.setup = function()
  H.create_default_hl()
  H.create_autocommands()
  vim.o.statusline = '%!v:lua.require(\"core.statusline\").build()'
end

M.setup()

return M
