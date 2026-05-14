-- Trailspace plugin: highlights and trims trailing whitespace in buffers.
local M = {}

local cfg = { only_in_normal_buffers = true, hl = 'MiniTrailspace' }

local function is_disabled()
  return vim.g.minitrailspace_disable == true or vim.b.minitrailspace_disable == true
end

local function get_match_id()
  for _, m in ipairs(vim.fn.getmatches()) do
    if m.group == cfg.hl then return m.id end
  end
end

local function create_default_hl()
  pcall(vim.api.nvim_set_hl, 0, cfg.hl, { default = true, link = 'Error' })
end

function M.highlight()
  if is_disabled() or vim.fn.mode() ~= 'n' then M.unhighlight(); return end
  if cfg.only_in_normal_buffers and vim.bo[0].buftype ~= '' then return end
  if get_match_id() then return end
  vim.fn.matchadd(cfg.hl, [[\s\+$]])
end

function M.unhighlight()
  pcall(vim.fn.matchdelete, get_match_id())
end

local function save_wins_cursor(buf)
  local res = {}
  for _, w in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(w) then res[w] = vim.api.nvim_win_get_cursor(w) end
  end
  return res
end

local function restore_wins_cursor(cursors)
  for w, pos in pairs(cursors) do
    if vim.api.nvim_win_is_valid(w) then pcall(vim.api.nvim_win_set_cursor, w, pos) end
  end
end

function M.trim(buf)
  buf = buf or 0
  if not vim.api.nvim_buf_get_option(buf, 'modifiable') then return true end

  -- (Previously skipped very large buffers; now always attempt trimming)

  -- Quick check using Vim search (runs inside buffer context) to avoid
  -- loading all lines into Lua when there's nothing to trim.
  local need_trim = false
  pcall(function()
    vim.api.nvim_buf_call(buf, function()
      if vim.fn.search([[\s\+$]], 'nw') > 0 then need_trim = true end
    end)
  end)
  if not need_trim then return true end

  -- Perform substitution in buffer context (fast, implemented in C)
  local curs = save_wins_cursor(buf)
  local ok, err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      vim.cmd([[keeppatterns %s/\s\+$//e]])
    end)
  end)
  restore_wins_cursor(curs)
  if not ok then return false, err end

  return true
end

function M.trim_last_lines(buf)
  buf = buf or 0
  -- (Previously skipped very large buffers; now always attempt trimming)

  local ok, err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      local n = vim.api.nvim_buf_line_count(0)
      local last = vim.fn.prevnonblank(n)
      if last < n then
        local curs = save_wins_cursor(buf)
        vim.api.nvim_buf_set_lines(buf, last, n, false, {})
        restore_wins_cursor(curs)
      end
    end)
  end)
  if not ok then return false, err end
  return true
end

local function on_buf_write_pre(ev)
  if is_disabled() then return end
  local buf = ev and ev.buf or 0
  if cfg.only_in_normal_buffers and vim.bo[buf].buftype ~= '' then return end
  if not vim.api.nvim_buf_get_option(buf, 'modifiable') then return end

  local ok, err = pcall(function()
    M.trim(buf)
    M.trim_last_lines(buf)
  end)
  if not ok then vim.notify('(trailspace) Failed to trim: ' .. tostring(err), vim.log.levels.ERROR) end
end

function M.setup(opts)
  if type(opts) == 'table' then cfg = vim.tbl_extend('force', cfg, opts) end
  create_default_hl()

  local g = vim.api.nvim_create_augroup('Trailspace', { clear = true })
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'InsertLeave' }, { group = g, pattern = '*', callback = function() M.highlight() end })
  vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave', 'InsertEnter' }, { group = g, pattern = '*', callback = function() M.unhighlight() end })
  vim.api.nvim_create_autocmd('OptionSet', { group = g, pattern = 'buftype', callback = function() if vim.v.option_new == '' then M.highlight() else M.unhighlight() end end })
  vim.api.nvim_create_autocmd('BufWritePre', { group = g, pattern = '*', callback = on_buf_write_pre })
  vim.api.nvim_create_autocmd('ColorScheme', { group = g, pattern = '*', callback = create_default_hl })

  -- No user commands: trimming is performed automatically on save.
end

-- Auto-setup for personal config
M.setup()

return M
