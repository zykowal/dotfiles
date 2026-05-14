-- Cmdline autocompletion with a delay.
if vim.fn.has('nvim-0.12') == 0 then error('(core.cmdline) Neovim>=0.12 required.', 0) end

local delay = 75
local blocked_types = {
  expression = true,
  shellcmd = true,
  shellcmdline = true,
}

local timer = vim.uv.new_timer()
local state
local nested

local function get_state()
  return { line = vim.fn.getcmdline(), pos = vim.fn.getcmdpos() }
end

local function should_complete(line)
  if vim.fn.getcmdtype() ~= ':' then return false end
  if blocked_types[vim.fn.getcmdcompltype()] then return false end
  return line:find('%a') ~= nil
end

local function trigger_complete()
  if vim.fn.mode() == 'c' then vim.fn.wildtrigger() end
end

local trigger_complete_scheduled = vim.schedule_wrap(trigger_complete)

local function hide_wild()
  vim.cmd('redraw')
end

local function autocomplete()
  timer:stop()
  if not should_complete(state.line) then return hide_wild() end
  if delay == 0 then return trigger_complete() end
  timer:start(delay, 0, trigger_complete_scheduled)
end

local function on_cmdline_enter()
  if vim.fn.mode() ~= 'c' then return end
  if state ~= nil then
    nested = (nested or 0) + 1
    return
  end
  state = get_state()
end

local function on_cmdline_update()
  if state == nil or nested ~= nil then return end

  local new_state = get_state()
  if new_state.line == state.line and new_state.pos == state.pos then return end

  local line_changed = new_state.line ~= state.line
  state = new_state
  if line_changed then autocomplete() end
end

local function on_cmdline_leave()
  if state == nil then return end
  if nested ~= nil then
    nested = nested > 1 and (nested - 1) or nil
    return
  end
  timer:stop()
  hide_wild()
  state = nil
end

local group = vim.api.nvim_create_augroup('CoreCmdline', { clear = true })

vim.api.nvim_create_autocmd('CmdlineEnter', {
  group = group,
  callback = vim.schedule_wrap(on_cmdline_enter),
})

vim.api.nvim_create_autocmd('CursorMovedC', {
  group = group,
  callback = vim.schedule_wrap(on_cmdline_update),
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = group,
  callback = on_cmdline_leave,
})
