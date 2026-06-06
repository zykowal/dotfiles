-- Custom statusline implementation with dynamic mode, git, diagnostics, and LSP info
local M = {}
local H = {}

local NONE = "NONE"
local fn = vim.fn
local api = vim.api

-- Localized frequently used API for performance and clarity
local nvim_set_hl = api.nvim_set_hl
local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_buf_get_lines = api.nvim_buf_get_lines
local nvim_get_current_win = api.nvim_get_current_win

local diagnostic_get = vim.diagnostic.get
local diagnostic_severity = vim.diagnostic.severity
local lsp_get_clients = vim.lsp.get_clients

local tbl_isempty = vim.tbl_isempty
local fn_expand = fn.expand
local table_concat = table.concat
local nvim_get_current_buf = api.nvim_get_current_buf
local nvim_get_mode = api.nvim_get_mode

local palette = {
  StatusModeNormal = "#89b4fa",
  StatusModeInsert = "#a6e3a1",
  StatusModeVisual = "#cba6f7",
  StatusModeSelect = "#e78a4e",
  StatusModeReplace = "#ea6962",
  StatusModeCommand = "#d3869b",
  StatusModePrompt = "#7fb4ca",
  StatusModeShell = "#f9e2af",
  StatusModeTerminal = "#d8a657",
  StatusGit = "#c099ff",
  StatusMeta = "#7f849c",
  StatusDiffAdd = "#a6e3a1",
  StatusDiffChange = "#f9e2af",
  StatusDiffDelete = "#f38ba8",
  StatusError = "#f38ba8",
  StatusWarn = "#f9e2af",
  StatusInfo = "#89dceb",
  StatusHint = "#94e2d5",
}

local mode_labels = {}
local mode_highlights = {}

for _, spec in ipairs({
  { hl = "StatusModeNormal", label = " ", modes = { "n", "niI", "niR", "niV", "nt" } },
  { hl = "StatusModeNormal", label = " ", modes = { "no", "nov", "noV", "no\22" } },
  { hl = "StatusModeVisual", label = " ", modes = { "v" } },
  { hl = "StatusModeVisual", label = " ", modes = { "V" } },
  { hl = "StatusModeVisual", label = " ", modes = { "\22", "\22s" } },
  { hl = "StatusModeSelect", label = " ", modes = { "s" } },
  { hl = "StatusModeSelect", label = " ", modes = { "S" } },
  { hl = "StatusModeSelect", label = " ", modes = { "\19" } },
  { hl = "StatusModeInsert", label = " ", modes = { "i", "ic", "ix" } },
  { hl = "StatusModeReplace", label = " ", modes = { "R", "Rc", "Rx" } },
  { hl = "StatusModeReplace", label = " ", modes = { "Rv" } },
  { hl = "StatusModeCommand", label = " ", modes = { "c" } },
  { hl = "StatusModeCommand", label = " ", modes = { "cv", "ce" } },
  { hl = "StatusModePrompt", label = " ", modes = { "r", "rm", "r?" } },
  { hl = "StatusModeShell", label = " ", modes = { "!" } },
  { hl = "StatusModeTerminal", label = " ", modes = { "t" } },
}) do
  for _, mode in ipairs(spec.modes) do
    mode_labels[mode] = spec.label
    mode_highlights[mode] = spec.hl
  end
end

local redraw_pending = false

local function hi(group, opts)
  nvim_set_hl(0, group, opts)
end

local function mode_highlight(mode)
  return mode_highlights[mode] or "StatusModeNormal"
end

local function mode_label(mode)
  return string.format(" %s", mode_labels[mode] or mode)
end

-- Create default highlights
H.create_default_hl = function()
  for _, group in ipairs({ "StatusLine", "StatusLineNC", "StatusText" }) do
    hi(group, { bg = NONE, fg = NONE })
  end

  for group, fg in pairs(palette) do
    hi(group, { bg = NONE, fg = fg, bold = true })
  end

  hi("StatusHint", { bg = NONE, fg = palette.StatusHint })
end

-- Section helpers
H.section = function(group, text)
  if text == nil or text == "" then
    return ""
  end
  return "%#" .. group .. "# " .. text .. " "
end

H.mode_section = function(mode)
  return "%#" .. mode_highlight(mode) .. "#" .. mode_label(mode)
end

H.request_redraw = function()
  if redraw_pending then
    return
  end

  redraw_pending = true
  vim.defer_fn(function()
    redraw_pending = false
    vim.cmd.redrawstatus()
  end, 16)
end

-- Update diagnostics cache for a buffer
H.update_diagnostics = function(bufnr)
  if not nvim_buf_is_valid(bufnr) then
    return
  end

  local diagnostics = diagnostic_get(bufnr)
  if tbl_isempty(diagnostics) then
    vim.b[bufnr].statusline_diagnostics = ""
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

  vim.b[bufnr].statusline_diagnostics = table_concat(parts)
end

H.update_git = function(bufnr)
  if not nvim_buf_is_valid(bufnr) then
    return
  end

  local head = vim.b[bufnr].gitsigns_head
  if not head or head == "" then
    vim.b[bufnr].statusline_git_branch = ""
    vim.b[bufnr].statusline_git_diff = ""
    return
  end

  local status = vim.b[bufnr].gitsigns_status_dict or {}
  vim.b[bufnr].statusline_git_branch = head

  local diff = {}
  if (status.added or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffAdd#+" .. status.added
  end
  if (status.changed or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffChange#~" .. status.changed
  end
  if (status.removed or 0) > 0 then
    diff[#diff + 1] = "%#StatusDiffDelete#-" .. status.removed
  end

  vim.b[bufnr].statusline_git_diff = table_concat(diff, "%#StatusText# ")
end

H.get_git_branch = function()
  local bufnr = nvim_get_current_buf()
  return vim.b[bufnr].statusline_git_branch or ""
end

H.get_git_diff = function()
  local bufnr = nvim_get_current_buf()
  return vim.b[bufnr].statusline_git_diff or ""
end

H.get_diagnostics = function()
  return vim.b[nvim_get_current_buf()].statusline_diagnostics or ""
end

-- File label and metadata helpers
H.file_label = function()
  local filename = fn_expand("%:t")
  if filename == "" then
    filename = "[No Name]"
  end

  local parent = fn_expand("%:p:h:t")
  local label = filename
  if parent ~= "" and parent ~= "." then
    label = parent .. "/" .. filename
  end

  if vim.bo.readonly or not vim.bo.modifiable then
    label = label .. " [RO]"
  end

  if vim.bo.modified then
    return label .. " [+]"
  end
  return label
end

H.file_encoding = function()
  return vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
end

H.update_lsp = function(bufnr)
  if not nvim_buf_is_valid(bufnr) then
    return
  end

  for _, client in ipairs(lsp_get_clients({ bufnr = bufnr })) do
    if client.name and vim.tbl_get(client, "config", "_compl_source") ~= "snippet" then
      vim.b[bufnr].statusline_lsp = " "
      return
    end
  end

  vim.b[bufnr].statusline_lsp = ""
end

H.lsp_label = function()
  return vim.b[nvim_get_current_buf()].statusline_lsp or ""
end

H.file_meta = function()
  local meta = {}
  local encoding = H.file_encoding()
  local fileformat = vim.bo.fileformat

  if encoding ~= "utf-8" then
    meta[#meta + 1] = encoding
  end

  if fileformat ~= "unix" then
    meta[#meta + 1] = fileformat
  end

  return table_concat(meta, " ")
end

H.location_label = function()
  local bufnr = nvim_get_current_buf()
  local line_nr = vim.fn.line(".")
  local line = vim.fn.line(".")
  local col = vim.fn.virtcol(".")
  local progress = vim.fn.line("$") > 0 and math.floor((line / vim.fn.line("$")) * 100) or 0

  return string.format("%4d:%-3d %2d%%%%", line, col, progress)
end

function M.build()
  local parts = {}
  local width = api.nvim_win_get_width(nvim_get_current_win())

  local mode = (nvim_get_mode() or {}).mode or fn.mode(1)
  parts[#parts + 1] = H.mode_section(mode)
  parts[#parts + 1] = "%<"

  local file = H.file_label()
  if file ~= "" then
    parts[#parts + 1] = H.section("StatusText", file)
  end

  local branch = H.get_git_branch()
  if branch ~= "" and width > 70 then
    parts[#parts + 1] = H.section("StatusGit", " " .. branch)
    local diff = H.get_git_diff()
    if diff ~= "" and width > 90 then
      parts[#parts + 1] = "%#StatusText# " .. diff .. " "
    end
  end

  local diagnostics = H.get_diagnostics()
  if diagnostics ~= "" then
    parts[#parts + 1] = H.section("StatusText", diagnostics)
  end

  parts[#parts + 1] = "%="

  local lsp = H.lsp_label()
  if lsp ~= "" then
    parts[#parts + 1] = H.section("StatusText", lsp)
  end

  if vim.bo.filetype ~= "" then
    parts[#parts + 1] = H.section("StatusMeta", vim.bo.filetype)
  end

  local meta = H.file_meta()
  if meta ~= "" then
    parts[#parts + 1] = H.section("StatusMeta", meta)
  end

  parts[#parts + 1] = H.section("StatusText", H.location_label())

  return table_concat(parts)
end

H.refresh_cache = function(bufnr)
  H.update_diagnostics(bufnr)
  H.update_git(bufnr)
  H.update_lsp(bufnr)
end

-- Setup autocommands
H.create_autocommands = function()
  local statusline_group = nvim_create_augroup("UserStatusline", { clear = true })

  nvim_create_autocmd("ColorScheme", {
    group = statusline_group,
    callback = function()
      H.create_default_hl()
      H.request_redraw()
    end,
  })

  nvim_create_autocmd({ "DiagnosticChanged", "BufEnter", "WinEnter", "BufWritePost", "LspAttach", "LspDetach", "FileType" }, {
    group = statusline_group,
    callback = function(args)
      H.refresh_cache(args.buf)
      H.request_redraw()
    end,
  })

  nvim_create_autocmd({ "ModeChanged", "TextChanged", "TextChangedI", "CursorHold", "CursorHoldI" }, {
    group = statusline_group,
    callback = function()
      H.request_redraw()
    end,
  })

  nvim_create_autocmd("User", {
    group = statusline_group,
    pattern = "GitSignsUpdate",
    callback = function(args)
      local bufnr = args.data and args.data.buffer or nvim_get_current_buf()
      H.update_git(bufnr)
      H.request_redraw()
    end,
  })

  nvim_create_autocmd("BufDelete", {
    group = statusline_group,
    callback = function(args)
      local buf = vim.b[args.buf]
      buf.statusline_diagnostics = nil
      buf.statusline_git_branch = nil
      buf.statusline_git_diff = nil
      buf.statusline_lsp = nil
    end,
  })

  H.refresh_cache(nvim_get_current_buf())
end


-- Public setup to initialize statusline module
M.setup = function()
  H.create_default_hl()
  H.create_autocommands()
  vim.o.statusline = '%!v:lua.require(\"core.statusline\").build()'
end

return M
-- Custom statusline implementation with dynamic mode, git, diagnostics, and LSP info
