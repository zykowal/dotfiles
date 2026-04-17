local function create_float_state()
  return { buf = -1, win = -1 }
end

local terminal_state = create_float_state()
local git_state = create_float_state()

local function open_float(buf)
  buf = vim.api.nvim_buf_is_valid(buf) and buf or vim.api.nvim_create_buf(false, true)
  local width = vim.o.columns
  local height = vim.o.lines

  local win_width = math.floor(width * 0.8)
  local win_height = math.floor(height * 0.8)

  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  local win_config = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "none",
  }

  return {
    buf = buf,
    win = vim.api.nvim_open_win(buf, true, win_config),
  }
end

local function is_terminal_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal"
end

local function ensure_terminal_float(state, open_cmd, direction)
  local float = open_float(state.buf)
  state.buf = float.buf
  state.win = float.win

  if not is_terminal_buffer(state.buf) then
    open_cmd()
  end

  vim.cmd.startinsert()
  if direction == "up" then
    vim.cmd("wincmd K")
  end
  if direction == "right" then
    vim.cmd("wincmd L")
  end
end

vim.keymap.set({ "n", "t" }, "<C-s>", function()
  if vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_hide(terminal_state.win)
    return
  end

  ensure_terminal_float(terminal_state, vim.cmd.terminal, "up")
end, { desc = "Term" })

vim.keymap.set({ "n", "t" }, "<C-y>", function()
  if vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_hide(terminal_state.win)
    return
  end

  ensure_terminal_float(terminal_state, vim.cmd.terminal, "right")
end, { desc = "Term" })

vim.keymap.set("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("Lazygit not found", vim.log.levels.ERROR)
    return
  end

  if vim.api.nvim_win_is_valid(git_state.win) then
    return
  end

  ensure_terminal_float(git_state, function()
    vim.fn.termopen("lazygit")
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = git_state.buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(git_state.win) then
          vim.api.nvim_win_close(git_state.win, true)
        end
        git_state.buf = -1
        git_state.win = -1
      end,
    })
  end, "float")
end, { desc = "Lazygit" })
