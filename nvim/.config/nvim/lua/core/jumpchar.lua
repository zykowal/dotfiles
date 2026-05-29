local M = {}

local ns = vim.api.nvim_create_namespace("jumpchar")
local labels = {}
local max_targets
local dim_priority = 150
local label_priority = 300
local label_order = {
  "a",
  "s",
  "d",
  "f",
  "j",
  "k",
  "l",
  ";",
  "g",
  "h",
  "r",
  "e",
  "u",
  "i",
  "w",
  "o",
  "q",
  "p",
  "t",
  "y",
  "v",
  "n",
  "c",
  "m",
  "x",
  "z",
  "b",
}
local left_hand = {
  a = true,
  s = true,
  d = true,
  f = true,
  g = true,
  r = true,
  e = true,
  w = true,
  q = true,
  t = true,
  v = true,
  c = true,
  x = true,
  z = true,
  b = true,
}
local left_hand_labels = {}
local right_hand_labels = {}

for _, label in ipairs(label_order) do
  labels[#labels + 1] = label

  if left_hand[label] then
    left_hand_labels[#left_hand_labels + 1] = label
  else
    right_hand_labels[#right_hand_labels + 1] = label
  end
end

max_targets = #labels * #labels

local function clear_marks(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
end

local function get_visible_region()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local top = vim.fn.line("w0")
  local bottom = vim.fn.line("w$")
  local lines = vim.api.nvim_buf_get_lines(bufnr, top - 1, bottom, false)

  return win, bufnr, top, lines
end

local function get_window_geometry(win)
  local pos = vim.fn.win_screenpos(win)

  return {
    top = pos[1],
    left = pos[2],
    bottom = pos[1] + vim.api.nvim_win_get_height(win) - 1,
    right = pos[2] + vim.api.nvim_win_get_width(win) - 1,
  }
end

local function is_visible_position(pos, geometry)
  return pos.row > 0
    and pos.col > 0
    and pos.row >= geometry.top
    and pos.row <= geometry.bottom
    and pos.col >= geometry.left
    and pos.col <= geometry.right
end

local function set_dim_mark(bufnr, lnum, start_col, end_col)
  if start_col >= end_col then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, start_col, {
    end_row = lnum - 1,
    end_col = end_col,
    hl_group = "JumpCharDim",
    priority = dim_priority,
    strict = false,
  })
end

local function read_key()
  local ok, char = pcall(vim.fn.getcharstr)
  if not ok or char == nil or char == "" then
    return nil, nil
  end

  local key = vim.fn.keytrans(char)
  if key == "<Esc>" or key == "<C-c>" then
    return nil, nil
  end

  return char, key
end

local function generate_jump_labels(count)
  local jump_labels = {}

  if count <= #labels then
    for i = 1, count do
      jump_labels[i] = labels[i]
    end

    return jump_labels, 1
  end

  local function get_second_order(first)
    local opposite_hand_labels = left_hand[first] and right_hand_labels or left_hand_labels
    local same_hand_labels = left_hand[first] and left_hand_labels or right_hand_labels
    local second_order = {}

    for _, label in ipairs(opposite_hand_labels) do
      second_order[#second_order + 1] = label
    end

    for _, label in ipairs(same_hand_labels) do
      if label ~= first then
        second_order[#second_order + 1] = label
      end
    end

    second_order[#second_order + 1] = first

    return second_order
  end

  local second_orders = {}
  for _, first in ipairs(labels) do
    second_orders[first] = get_second_order(first)
  end

  local index = 1
  for round = 1, #labels do
    for _, first in ipairs(labels) do
      local second = second_orders[first][round]
      jump_labels[index] = first .. second
      index = index + 1
      if index > count then
        return jump_labels, 2
      end
    end
  end

  return jump_labels, 2
end

local function compare_targets(a, b, cursor_pos)
  local a_row_diff = a.row - cursor_pos.row
  local a_col_diff = a.screen_col - cursor_pos.col
  local b_row_diff = b.row - cursor_pos.row
  local b_col_diff = b.screen_col - cursor_pos.col
  local a_same_line = a_row_diff == 0
  local b_same_line = b_row_diff == 0

  if a_same_line ~= b_same_line then
    return a_same_line
  end

  if a_same_line and b_same_line then
    local a_col_distance = math.abs(a_col_diff)
    local b_col_distance = math.abs(b_col_diff)

    if a_col_distance ~= b_col_distance then
      return a_col_distance < b_col_distance
    end

    local a_forward = a_col_diff > 0
    local b_forward = b_col_diff > 0
    if a_forward ~= b_forward then
      return a_forward
    end
  end

  local a_forward = a_row_diff > 0 or (a_row_diff == 0 and a_col_diff > 0)
  local b_forward = b_row_diff > 0 or (b_row_diff == 0 and b_col_diff > 0)
  if a_forward ~= b_forward then
    return a_forward
  end

  local a_line_distance = math.abs(a_row_diff)
  local b_line_distance = math.abs(b_row_diff)
  if a_line_distance ~= b_line_distance then
    return a_line_distance < b_line_distance
  end

  local a_col_distance = math.abs(a_col_diff)
  local b_col_distance = math.abs(b_col_diff)
  if a_col_distance ~= b_col_distance then
    return a_col_distance < b_col_distance
  end

  if a.row ~= b.row then
    return a.row < b.row
  end

  return a.screen_col < b.screen_col
end

local function collect_targets(target_char)
  local win, bufnr, top, lines = get_visible_region()
  local geometry = get_window_geometry(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_pos = vim.fn.screenpos(win, cursor[1], cursor[2] + 1)
  local targets = {}
  local needle = target_char:lower()
  local step = math.max(1, #target_char)

  for i, line in ipairs(lines) do
    local lnum = top + i - 1
    local haystack = line:lower()
    local start = 1

    while true do
      local col = haystack:find(needle, start, true)
      if not col then
        break
      end

      local target_col = col - 1
      local pos = vim.fn.screenpos(win, lnum, col)

      -- Skip folded or horizontally hidden matches and avoid wasting a label on the cursor.
      if is_visible_position(pos, geometry) and not (lnum == cursor[1] and target_col == cursor[2]) then
        targets[#targets + 1] = {
          line = lnum,
          col = target_col,
          row = pos.row,
          screen_col = pos.col,
          width = step,
        }
      end

      start = col + step
    end
  end

  table.sort(targets, function(a, b)
    return compare_targets(a, b, cursor_pos)
  end)

  if #targets > max_targets then
    for i = max_targets + 1, #targets do
      targets[i] = nil
    end
  end

  return bufnr, targets
end

local function render_dim(bufnr, top, lines, targets, target_width)
  clear_marks(bufnr)

  local targets_by_line = {}

  if targets then
    for _, target in ipairs(targets) do
      local line_targets = targets_by_line[target.line]
      if not line_targets then
        line_targets = {}
        targets_by_line[target.line] = line_targets
      end

      line_targets[#line_targets + 1] = target.col
    end
  end

  for i, line in ipairs(lines) do
    if line ~= "" then
      local lnum = top + i - 1
      local line_targets = targets_by_line[lnum]

      if not line_targets or #line_targets == 0 then
        set_dim_mark(bufnr, lnum, 0, #line)
      else
        table.sort(line_targets)

        local start_col = 0
        for _, target_col in ipairs(line_targets) do
          set_dim_mark(bufnr, lnum, start_col, target_col)
          start_col = math.max(start_col, target_col + target_width)
        end

        set_dim_mark(bufnr, lnum, start_col, #line)
      end
    end
  end
end

local function set_label_mark(bufnr, lnum, col, text)
  if text == "" then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, col, {
    priority = label_priority,
    virt_text = { { text, "JumpCharLabel" } },
    virt_text_pos = "overlay",
  })
end

local function filter_targets(targets, active_prefix)
  if not active_prefix then
    return targets
  end

  local visible_targets = {}
  for _, target in ipairs(targets) do
    if target.label:sub(1, #active_prefix) == active_prefix then
      visible_targets[#visible_targets + 1] = target
    end
  end

  return visible_targets
end

local function render_targets(bufnr, top, lines, targets, active_prefix)
  local target_cols_by_line = {}

  for _, target in ipairs(targets) do
    local line_cols = target_cols_by_line[target.line]
    if not line_cols then
      line_cols = {}
      target_cols_by_line[target.line] = line_cols
    end

    line_cols[target.col] = true
  end

  for _, target in ipairs(targets) do
    if #target.label == 1 then
      set_label_mark(bufnr, target.line, target.col, target.label)
    elseif active_prefix then
      set_label_mark(bufnr, target.line, target.col, target.label:sub(#active_prefix + 1, #active_prefix + 1))
    else
      local line = lines[target.line - top + 1] or ""
      local line_cols = target_cols_by_line[target.line] or {}
      local second_col = target.col + target.width

      if second_col >= #line then
        set_label_mark(bufnr, target.line, target.col, target.label)
      else
        set_label_mark(bufnr, target.line, target.col, target.label:sub(1, 1))

        if not line_cols[second_col] then
          set_label_mark(bufnr, target.line, second_col, target.label:sub(2, 2))
        end
      end
    end
  end
end

local function render_state(bufnr, targets, target_width, active_prefix)
  local _, _, top, lines = get_visible_region()
  local visible_targets = filter_targets(targets, active_prefix)

  render_dim(bufnr, top, lines, visible_targets, target_width)
  render_targets(bufnr, top, lines, visible_targets, active_prefix)
  vim.cmd.redraw()
end

local function has_matching_prefix(targets, prefix)
  for _, target in ipairs(targets) do
    if target.label:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

local function select_target(bufnr, targets, label_length, target_width)
  local _, first_key = read_key()
  if not first_key or #first_key ~= 1 then
    return nil
  end

  local wanted = first_key:lower()
  if label_length == 2 then
    if not has_matching_prefix(targets, wanted) then
      return nil
    end

    render_state(bufnr, targets, target_width, wanted)

    local _, second_key = read_key()
    if not second_key or #second_key ~= 1 then
      return nil
    end

    wanted = wanted .. second_key:lower()
  end

  for _, target in ipairs(targets) do
    if target.label == wanted then
      return target
    end
  end

  return nil
end

local function jump_to(target)
  vim.api.nvim_win_set_cursor(0, { target.line, target.col })
end

function M.jump()
  local _, bufnr, top, lines = get_visible_region()

  render_dim(bufnr, top, lines)
  vim.cmd.redraw()

  local target_char = read_key()
  if not target_char then
    clear_marks(bufnr)
    vim.cmd.redraw()
    return
  end

  local targets
  bufnr, targets = collect_targets(target_char)
  if #targets == 0 then
    clear_marks(bufnr)
    vim.cmd.redraw()
    return
  end

  local jump_labels, label_length = generate_jump_labels(#targets)
  for i, label in ipairs(jump_labels) do
    targets[i].label = label
  end

  render_state(bufnr, targets, #target_char)

  local selected = select_target(bufnr, targets, label_length, #target_char)

  clear_marks(bufnr)
  vim.cmd.redraw()

  if selected then
    jump_to(selected)
  end
end

function M.setup()
  vim.keymap.set({ "n", "x" }, "s", function()
    M.jump()
  end, { desc = "Jump to visible character", silent = true })
end

return M
