local M = {}
local H = {}

local lazygit = {
  buf = -1,
  win = -1,
}

local tab_states = {}

function H.is_valid_buf(buf)
  return type(buf) == "number" and buf > 0 and vim.api.nvim_buf_is_valid(buf)
end

function H.is_valid_win(win)
  return type(win) == "number" and win > 0 and vim.api.nvim_win_is_valid(win)
end

function H.is_terminal_buf(buf)
  return H.is_valid_buf(buf) and vim.bo[buf].buftype == "terminal"
end

function H.is_managed_shell_buf(buf)
  if not H.is_terminal_buf(buf) then
    return false
  end

  local role = vim.b[buf].core_terminal_role
  return role == "main" or role == "aux"
end

function H.is_terminal_mode()
  return vim.api.nvim_get_mode().mode:sub(1, 1) == "t"
end

function H.run_after_terminal_mode(fn)
  if H.is_terminal_mode() then
    local keys = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
    vim.schedule(fn)
    return
  end

  fn()
end

function H.current_tabpage()
  return vim.api.nvim_get_current_tabpage()
end

function H.tab_state()
  local tabpage = H.current_tabpage()
  tab_states[tabpage] = tab_states[tabpage] or {
    main_buf = -1,
    main_win = -1,
    aux_bufs = {},
    hidden_layout = nil,
  }

  return tab_states[tabpage]
end

function H.filter_terminal_buffers(buffers)
  local valid = {}
  local seen = {}

  for _, buf in ipairs(buffers or {}) do
    if H.is_terminal_buf(buf) and not seen[buf] then
      valid[#valid + 1] = buf
      seen[buf] = true
    end
  end

  return valid
end

function H.sync_aux_buffers(state)
  local filtered = {}
  local seen = {}

  for _, buf in ipairs(state.aux_bufs) do
    if H.is_terminal_buf(buf) and buf ~= state.main_buf and not seen[buf] then
      filtered[#filtered + 1] = buf
      seen[buf] = true
    end
  end

  state.aux_bufs = filtered
end

function H.cleanup_state(state)
  if not H.is_terminal_buf(state.main_buf) then
    state.main_buf = -1
    state.main_win = -1
  elseif not H.is_valid_win(state.main_win) or vim.api.nvim_win_get_buf(state.main_win) ~= state.main_buf then
    state.main_win = -1
  end

  H.sync_aux_buffers(state)

  if state.hidden_layout then
    state.hidden_layout.main_buf = H.is_terminal_buf(state.hidden_layout.main_buf) and state.hidden_layout.main_buf or -1
    state.hidden_layout.aux_bufs = H.filter_terminal_buffers(state.hidden_layout.aux_bufs)

    if state.hidden_layout.main_buf == -1 and #state.hidden_layout.aux_bufs == 0 then
      state.hidden_layout = nil
    end
  end
end

function H.set_shell_role(buf, role)
  vim.b[buf].core_terminal_managed = true
  vim.b[buf].core_terminal_role = role
end

function H.apply_terminal_opts(buf, win)
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"

  local target_win = win or vim.api.nvim_get_current_win()
  vim.api.nvim_set_option_value("number", false, { win = target_win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = target_win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = target_win })
  vim.api.nvim_set_option_value("spell", false, { win = target_win })
end

function H.open_top_split()
  local total_height = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then
      local pos = vim.api.nvim_win_get_position(win)
      total_height = math.max(total_height, pos[1] + vim.api.nvim_win_get_height(win))
    end
  end

  local target_height = math.max(1, math.floor(total_height / 2))

  vim.cmd("topleft split")

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, target_height)

  return win
end

function H.open_right_split()
  vim.cmd("rightbelow vsplit")
  return vim.api.nvim_get_current_win()
end

function H.is_managed_shell_win(win)
  if not H.is_valid_win(win) then
    return false
  end

  local config = vim.api.nvim_win_get_config(win)
  if config.relative ~= "" then
    return false
  end

  return H.is_managed_shell_buf(vim.api.nvim_win_get_buf(win))
end

function H.tab_terminal_windows()
  local wins = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if H.is_managed_shell_win(win) then
      wins[#wins + 1] = win
    end
  end

  table.sort(wins, function(a, b)
    local pos_a = vim.api.nvim_win_get_position(a)
    local pos_b = vim.api.nvim_win_get_position(b)

    if pos_a[1] == pos_b[1] then
      return pos_a[2] < pos_b[2]
    end

    return pos_a[1] < pos_b[1]
  end)

  return wins
end

function H.sync_visible_shell_state(state)
  local wins = H.tab_terminal_windows()
  if #wins == 0 then
    return false
  end

  local main_buf = state.main_buf
  local buffers = {}
  local seen = {}
  local main_win = -1

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not seen[buf] then
      buffers[#buffers + 1] = buf
      seen[buf] = true
    end
  end

  if not H.is_terminal_buf(main_buf) or not seen[main_buf] then
    main_buf = buffers[1]
  end

  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_buf(win) == main_buf then
      main_win = win
      break
    end
  end

  local aux_bufs = {}
  for _, buf in ipairs(buffers) do
    if buf ~= main_buf then
      aux_bufs[#aux_bufs + 1] = buf
    end
  end

  state.main_buf = main_buf
  state.main_win = main_win
  state.aux_bufs = aux_bufs

  return true
end

function H.capture_layout(state)
  H.cleanup_state(state)

  if not H.sync_visible_shell_state(state) then
    return nil
  end

  return {
    main_buf = state.main_buf,
    aux_bufs = vim.deepcopy(state.aux_bufs),
  }
end

function H.hide_terminal_window(win)
  if not H.is_valid_win(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local state = H.tab_state()
  H.cleanup_state(state)

  if state.main_win == win then
    state.main_win = -1
  end

  if lazygit.win == win then
    lazygit.win = -1
  end

  if buf == state.main_buf then
    state.hidden_layout = nil
  else
    local remaining = {}
    for _, item in ipairs(state.aux_bufs) do
      if item ~= buf then
        remaining[#remaining + 1] = item
      end
    end
    state.aux_bufs = remaining

    if state.hidden_layout then
      local aux = {}
      for _, item in ipairs(state.hidden_layout.aux_bufs or {}) do
        if item ~= buf then
          aux[#aux + 1] = item
        end
      end
      state.hidden_layout.aux_bufs = aux
    end
  end

  vim.api.nvim_win_hide(win)
end

function H.hide_shell_windows(state)
  H.cleanup_state(state)

  local wins = H.tab_terminal_windows()
  if #wins == 0 then
    return false
  end

  H.sync_visible_shell_state(state)
  state.hidden_layout = H.capture_layout(state)

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if buf == state.main_buf then
      state.main_win = -1
    end
    vim.api.nvim_win_hide(win)
  end

  return true
end

function H.restore_shell_windows(state)
  H.cleanup_state(state)

  local layout = state.hidden_layout
  if not layout then
    return false
  end

  local main_buf = layout.main_buf
  if not H.is_terminal_buf(main_buf) then
    state.hidden_layout = nil
    return false
  end

  local aux_bufs = H.filter_terminal_buffers(layout.aux_bufs)
  state.hidden_layout = nil

  local main_win = H.open_top_split()
  vim.api.nvim_win_set_buf(main_win, main_buf)
  H.apply_terminal_opts(main_buf, main_win)
  state.main_buf = main_buf
  state.main_win = main_win

  local restored_aux = {}
  for _, buf in ipairs(aux_bufs) do
    if buf ~= main_buf then
      local win = H.open_right_split()
      vim.api.nvim_win_set_buf(win, buf)
      H.apply_terminal_opts(buf, win)
      restored_aux[#restored_aux + 1] = buf
    end
  end

  state.aux_bufs = restored_aux
  vim.api.nvim_set_current_win(main_win)
  vim.cmd.startinsert()

  return true
end

function H.create_shell_buffer(role)
  vim.cmd.terminal()

  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  H.set_shell_role(buf, role)
  H.apply_terminal_opts(buf, win)
  H.set_terminal_keymaps(buf)

  return buf, win
end

function H.ensure_main_shell(state)
  local win = H.open_top_split()

  if H.is_terminal_buf(state.main_buf) then
    vim.api.nvim_win_set_buf(win, state.main_buf)
    H.apply_terminal_opts(state.main_buf, win)
    state.main_win = win
  else
    local buf, term_win = H.create_shell_buffer("main")
    state.main_buf = buf
    state.main_win = term_win
  end

  vim.cmd.startinsert()
end

function H.open_aux_shell()
  local state = H.tab_state()
  H.cleanup_state(state)

  H.open_right_split()
  local buf = H.create_shell_buffer("aux")

  state.aux_bufs[#state.aux_bufs + 1] = buf
  H.sync_aux_buffers(state)

  vim.cmd.startinsert()
end

function H.float_config()
  local width = vim.o.columns
  local height = vim.o.lines - vim.o.cmdheight

  local win_width = math.max(20, math.floor(width * 0.85))
  local win_height = math.max(8, math.floor(height * 0.85))

  return {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = math.floor((height - win_height) / 2),
    col = math.floor((width - win_width) / 2),
    style = "minimal",
    border = "none",
  }
end

function H.open_lazygit()
  local buf = lazygit.buf
  if not H.is_valid_buf(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
  end

  local win = vim.api.nvim_open_win(buf, true, H.float_config())
  lazygit.buf = buf
  lazygit.win = win

  if not H.is_terminal_buf(buf) then
    vim.fn.termopen({ "lazygit" })
    lazygit.buf = vim.api.nvim_get_current_buf()
    lazygit.win = vim.api.nvim_get_current_win()
    vim.b[lazygit.buf].core_terminal_managed = true
    vim.b[lazygit.buf].core_terminal_role = "lazygit"
    H.apply_terminal_opts(lazygit.buf, lazygit.win)
    H.set_terminal_keymaps(lazygit.buf)
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = lazygit.buf,
      once = true,
      callback = function()
        if H.is_valid_win(lazygit.win) then
          vim.api.nvim_win_close(lazygit.win, true)
        end
        lazygit.buf = -1
        lazygit.win = -1
      end,
    })
  else
    H.apply_terminal_opts(lazygit.buf, lazygit.win)
  end

  vim.cmd.startinsert()
end

function H.set_terminal_keymaps(buf)
  local opts = { buffer = buf, silent = true }

  vim.keymap.set("t", "<C-y>", function()
    if vim.b[buf].core_terminal_role == "lazygit" then
      return
    end
    H.run_after_terminal_mode(H.open_aux_shell)
  end, opts)
  vim.keymap.set("t", "<C-h>", "<Cmd>wincmd h<CR>", opts)
  vim.keymap.set("t", "<C-j>", "<Cmd>wincmd j<CR>", opts)
  vim.keymap.set("t", "<C-k>", "<Cmd>wincmd k<CR>", opts)
  vim.keymap.set("t", "<C-l>", "<Cmd>wincmd l<CR>", opts)
  vim.keymap.set("n", "q", function()
    H.hide_terminal_window(vim.api.nvim_get_current_win())
  end, opts)
end

function M.toggle_terminal()
  local state = H.tab_state()
  H.cleanup_state(state)

  if H.hide_shell_windows(state) then
    return
  end

  if H.restore_shell_windows(state) then
    return
  end

  H.ensure_main_shell(state)
end

function M.toggle_lazygit()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("Lazygit not found", vim.log.levels.ERROR)
    return
  end

  if H.is_valid_win(lazygit.win) then
    H.hide_terminal_window(lazygit.win)
    return
  end

  H.open_lazygit()
end

function M.setup()
  vim.keymap.set("n", "<C-s>", M.toggle_terminal, { desc = "Terminal" })
  vim.keymap.set("t", "<C-s>", function()
    H.run_after_terminal_mode(M.toggle_terminal)
  end, { desc = "Terminal" })
  vim.keymap.set("n", "<leader>gg", M.toggle_lazygit, { desc = "Lazygit" })

  vim.api.nvim_create_autocmd("TabClosed", {
    callback = function(args)
      local tabpage = tonumber(args.file)
      if tabpage then
        tab_states[tabpage] = nil
      end
    end,
  })
end

return M
