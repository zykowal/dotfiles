local M = {}

local letters = {}
for code = string.byte("A"), string.byte("Z") do
  letters[#letters + 1] = string.char(code)
end

local default_config = {
  mappings = {
    mark = "ma",
    jump_latest = "ml",
    clear_line = "mc",
    delete_latest = "md",
    clear_all = "mC",
    list = "mm",
  },
  map_opts = { silent = true },
  notify = true,
}

local config = vim.deepcopy(default_config)

local function notify(message, level)
  if config.notify == false then
    return
  end

  vim.notify(message, level or vim.log.levels.INFO)
end

local function mark_name(letter)
  return "'" .. letter
end

local function normalize_path(path)
  if not path or path == "" then
    return ""
  end

  return vim.fn.fnamemodify(path, ":p")
end

local function entry_file(entry)
  if entry.file and entry.file ~= "" then
    return normalize_path(entry.file)
  end

  local bufnr = entry.pos and entry.pos[1]
  if bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
    return normalize_path(vim.api.nvim_buf_get_name(bufnr))
  end

  return ""
end

local function normalize_pos(entry)
  local pos = entry.pos
  if type(pos) ~= "table" or not pos[2] or pos[2] <= 0 then
    return nil
  end

  local bufnr = pos[1] or 0
  if (bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr)) and entry.file and entry.file ~= "" then
    bufnr = vim.fn.bufadd(normalize_path(entry.file))
  end

  if bufnr <= 0 then
    return nil
  end

  return { bufnr, pos[2], math.max(pos[3] or 1, 1), pos[4] or 0 }
end

local function get_marks()
  local marks = {}
  local seen = {}

  for _, entry in ipairs(vim.fn.getmarklist()) do
    local letter = entry.mark and entry.mark:match("^'([A-Z])$")

    if letter and not seen[letter] then
      local pos = normalize_pos(entry)

      if pos then
        marks[#marks + 1] = {
          name = letter,
          pos = pos,
          file = entry.file or "",
          path = entry_file(entry),
        }
        seen[letter] = true
      end
    end
  end

  table.sort(marks, function(a, b)
    return a.name < b.name
  end)

  return marks
end

local function current_mark()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)

  return {
    pos = { bufnr, cursor[1], cursor[2] + 1, 0 },
    file = file,
    path = normalize_path(file),
  }
end

local function is_same_line(mark, current)
  if mark.pos[2] ~= current.pos[2] then
    return false
  end

  if mark.pos[1] == current.pos[1] then
    return true
  end

  return mark.path ~= "" and mark.path == current.path
end

local function rewrite_marks(marks)
  local ok, err = pcall(vim.cmd, "delmarks A-Z")
  if not ok then
    notify("Failed to clear marks: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  for index, mark in ipairs(marks) do
    if index > #letters then
      break
    end

    ok, err = pcall(vim.fn.setpos, mark_name(letters[index]), mark.pos)
    if not ok or err ~= 0 then
      notify("Failed to set mark " .. letters[index], vim.log.levels.ERROR)
      return false
    end
  end

  return true
end

local function display_path(mark)
  local file = mark.file
  if (not file or file == "") and mark.pos[1] > 0 and vim.api.nvim_buf_is_valid(mark.pos[1]) then
    file = vim.api.nvim_buf_get_name(mark.pos[1])
  end

  if not file or file == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(file, ":~:.")
end

local function line_text(mark)
  local bufnr = mark.pos[1]
  local lnum = mark.pos[2]

  if bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return ""
  end

  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, lnum - 1, lnum, false)
  if not ok or not lines[1] then
    return ""
  end

  local text = vim.trim(lines[1])
  if #text > 80 then
    text = text:sub(1, 77) .. "..."
  end

  return text
end

local function format_mark(mark)
  local text = line_text(mark)
  local suffix = text ~= "" and "  " .. text or ""

  return string.format("%s  %s:%d:%d%s", mark.name, display_path(mark), mark.pos[2], mark.pos[3], suffix)
end

local function jump_to_mark(mark)
  local ok, err = pcall(vim.cmd, "normal! `" .. mark.name .. "zv")
  if not ok then
    notify("Failed to jump to mark " .. mark.name .. ": " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.mark()
  local marks = get_marks()
  local current = current_mark()
  local next_marks = {}
  local refreshed = false

  for _, mark in ipairs(marks) do
    if is_same_line(mark, current) then
      refreshed = true
    else
      next_marks[#next_marks + 1] = mark
    end
  end

  if not refreshed then
    while #next_marks >= #letters do
      table.remove(next_marks, 1)
    end
  end

  next_marks[#next_marks + 1] = current

  if rewrite_marks(next_marks) then
    notify("Marked as " .. letters[#next_marks])
  end
end

function M.clear_line()
  local marks = get_marks()
  local current = current_mark()
  local next_marks = {}
  local removed = {}

  for _, mark in ipairs(marks) do
    if is_same_line(mark, current) then
      removed[#removed + 1] = mark.name
    else
      next_marks[#next_marks + 1] = mark
    end
  end

  if #removed == 0 then
    notify("No mark on current line", vim.log.levels.WARN)
    return
  end

  if rewrite_marks(next_marks) then
    notify("Cleared mark " .. table.concat(removed, ", "))
  end
end

function M.delete_latest()
  local marks = get_marks()

  if #marks == 0 then
    notify("No marks", vim.log.levels.WARN)
    return
  end

  local removed = marks[#marks].name
  table.remove(marks)

  if rewrite_marks(marks) then
    notify("Deleted mark " .. removed)
  end
end

function M.jump_latest()
  local marks = get_marks()

  if #marks == 0 then
    notify("No marks", vim.log.levels.WARN)
    return
  end

  jump_to_mark(marks[#marks])
end

function M.clear_all()
  local marks = get_marks()

  if #marks == 0 then
    notify("No marks", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.cmd, "delmarks A-Z")
  if not ok then
    notify("Failed to clear marks: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  notify("Cleared all marks")
end

function M.list()
  local marks = get_marks()

  if #marks == 0 then
    notify("No marks", vim.log.levels.WARN)
    return
  end

  vim.ui.select(marks, {
    prompt = "Marks> ",
    format_item = format_mark,
  }, function(mark)
    if mark then
      jump_to_mark(mark)
    end
  end)
end

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), user_config or {})

  local mappings = config.mappings or {}
  local map_opts = config.map_opts or {}

  local function map(lhs, rhs, desc)
    if not lhs or lhs == "" then
      return
    end

    vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", map_opts, { desc = desc }))
  end

  map(mappings.mark, M.mark, "Mark current line")
  map(mappings.another_mark, M.mark, "Mark current line")
  map(mappings.jump_latest, M.jump_latest, "Jump to latest mark")
  map(mappings.clear_line, M.clear_line, "Clear mark on current line")
  map(mappings.delete_latest, M.delete_latest, "Delete latest mark")
  map(mappings.clear_all, M.clear_all, "Clear all marks")
  map(mappings.list, M.list, "List marks")
end

return M
