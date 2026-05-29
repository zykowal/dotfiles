local M = {}

local open_to_close = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
  ['"'] = '"',
  ["'"] = "'",
  ["`"] = "`",
}

local closing_chars = {
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
}

local pair_follow_chars = {
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
  [","] = true,
  [";"] = true,
  [":"] = true,
}

local quote_chars = {
  ['"'] = true,
  ["'"] = true,
  ["`"] = true,
}

local rust_single_quote_prefix_chars = {
  ["&"] = true,
  ["<"] = true,
  [":"] = true,
  [","] = true,
  ["+"] = true,
}

local rust_single_quote_label_prefix_chars = {
  ["{"] = true,
  ["}"] = true,
  [";"] = true,
}

local rust_single_quote_prefix_keywords = {
  ["break"] = true,
  ["continue"] = true,
  ["where"] = true,
}

local function termcode(keys)
  return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

local left_key = termcode("<Left>")
local right_key = termcode("<Right>")
local backspace_key = termcode("<BS>")
local delete_key = termcode("<Del>")

local function get_context()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local prev_char = col > 0 and line:sub(col, col) or ""
  local next_char = line:sub(col + 1, col + 1)

  return line, col, prev_char, next_char
end

local function is_word_char(char)
  return char ~= "" and char:match("[%w_]") ~= nil
end

local function is_space_char(char)
  return char ~= "" and char:match("%s") ~= nil
end

local function get_prev_non_space_col(line, col)
  while col > 0 do
    if not is_space_char(line:sub(col, col)) then
      return col
    end

    col = col - 1
  end

  return 0
end

local function get_prev_non_space_char(line, col)
  local prev_non_space_col = get_prev_non_space_col(line, col)

  if prev_non_space_col == 0 then
    return ""
  end

  return line:sub(prev_non_space_col, prev_non_space_col)
end

local function get_prev_word(line, col)
  local finish = get_prev_non_space_col(line, col)

  if finish == 0 then
    return ""
  end

  local start = finish
  while start > 0 and is_word_char(line:sub(start, start)) do
    start = start - 1
  end

  return line:sub(start + 1, finish)
end

local function is_escaped(line, col)
  local backslashes = 0

  while col > 0 and line:sub(col, col) == "\\" do
    backslashes = backslashes + 1
    col = col - 1
  end

  return backslashes % 2 == 1
end

local function has_unescaped_char_before_cursor(line, col, char)
  local backslashes = 0

  for i = 1, col do
    local current = line:sub(i, i)

    if current == "\\" then
      backslashes = backslashes + 1
    else
      if current == char and backslashes % 2 == 0 then
        return true
      end

      backslashes = 0
    end
  end

  return false
end

local function should_pair_bracket(next_char)
  return next_char == "" or is_space_char(next_char) or pair_follow_chars[next_char]
end

local function should_skip_rust_single_quote(line, col, next_char)
  local prev_non_space_char = get_prev_non_space_char(line, col)

  if rust_single_quote_prefix_chars[prev_non_space_char] then
    return true
  end

  local prev_word = get_prev_word(line, col)
  if rust_single_quote_prefix_keywords[prev_word] then
    return true
  end

  if (prev_non_space_char == "" or rust_single_quote_label_prefix_chars[prev_non_space_char])
    and (next_char == "" or is_space_char(next_char))
  then
    return true
  end

  return false
end

local function should_move_over_quote(char, line, col, prev_char, next_char)
  if next_char ~= char then
    return false
  end

  if prev_char == "" or prev_char == char then
    return false
  end

  if is_escaped(line, col) then
    return false
  end

  return has_unescaped_char_before_cursor(line, col, char)
end

local function should_skip_quote(char, line, col, prev_char, next_char)
  if is_escaped(line, col) then
    return true
  end

  if char == "'" and vim.bo.filetype == "rust" and should_skip_rust_single_quote(line, col, next_char) then
    return true
  end

  if is_word_char(next_char) then
    return true
  end

  if is_word_char(prev_char) then
    return true
  end

  return false
end

local function handle_open(char)
  return function()
    local line, col, prev_char, next_char = get_context()

    if quote_chars[char] then
      if should_move_over_quote(char, line, col, prev_char, next_char) then
        return right_key
      end

      if should_skip_quote(char, line, col, prev_char, next_char) then
        return char
      end

      return char .. char .. left_key
    end

    if not should_pair_bracket(next_char) then
      return char
    end

    return char .. open_to_close[char] .. left_key
  end
end

local function handle_close(char)
  return function()
    local _, _, _, next_char = get_context()

    if next_char == char then
      return right_key
    end

    return char
  end
end

local function handle_backspace()
  local _, _, prev_char, next_char = get_context()
  local close_char = open_to_close[prev_char]

  if close_char ~= nil and next_char == close_char then
    return backspace_key .. delete_key
  end

  return backspace_key
end

function M.setup()
  local expr_opts = { expr = true, replace_keycodes = false }

  for char in pairs(open_to_close) do
    vim.keymap.set("i", char, handle_open(char), expr_opts)
  end

  for char in pairs(closing_chars) do
    vim.keymap.set("i", char, handle_close(char), expr_opts)
  end

  vim.keymap.set("i", "<BS>", handle_backspace, expr_opts)
end

return M
