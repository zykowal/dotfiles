-- Minimal buffer closer to replace external mini.bufremove dependency.
-- Provides a small `close` function and maps <leader>c to close current buffer.

local M = {}

local default_config = {
  key = '<leader>c', -- mapping to close buffer
  map_opts = { noremap = true, silent = true },
}

local config = vim.tbl_extend('force', {}, default_config)

local function normalize_buf_id(buf_id)
  if buf_id == nil or buf_id == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf_id
end

local function can_close(buf_id, force)
  if force then return true end
  if not vim.api.nvim_buf_get_option(buf_id, 'modified') then return true end
  local msg = string.format('Buffer %d has unsaved changes. Close without saving?', buf_id)
  return vim.fn.confirm(msg, '&No\n&Yes', 1) == 2
end

local function unshow_in_windows(buf_id)
  for _, win in ipairs(vim.fn.win_findbuf(buf_id)) do
    -- Use nvim_win_call so window-local commands work as expected
    pcall(vim.api.nvim_win_call, win, function()
      if vim.fn.getcmdwintype() ~= '' then
        pcall(vim.cmd, 'close!')
        return
      end

      local cur = vim.api.nvim_win_get_buf(0)
      local alt = vim.fn.bufnr('#')
      if alt ~= cur and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(0, alt)
        return
      end

      -- Try previous buffer
      local ok = pcall(vim.cmd, 'bprevious')
      if ok and vim.api.nvim_win_get_buf(0) ~= cur then return end

      -- Fallback: create a new listed buffer and show it
      local nb = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(0, nb)
    end)
  end
end

--- Close buffer (simple, self-contained)
-- @param buf_id number|nil Buffer id (nil or 0 = current)
-- @param opts table|nil Options: force = boolean
function M.close(buf_id, opts)
  if type(buf_id) == 'table' and opts == nil then
    opts = buf_id
    buf_id = nil
  end
  opts = opts or {}
  local force = opts.force == true

  buf_id = normalize_buf_id(buf_id)
  if not vim.api.nvim_buf_is_valid(buf_id) then return false end

  if not can_close(buf_id, force) then return false end

  -- Try to ensure windows don't end up empty
  unshow_in_windows(buf_id)

  local ok, err = pcall(vim.api.nvim_buf_delete, buf_id, { force = force })
  if not ok then
    vim.notify('Failed to delete buffer: ' .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.setup(user_config)
  config = vim.tbl_extend('force', config, user_config or {})
  vim.keymap.set('n', config.key, function() M.close() end, config.map_opts)
end

return M
