-- Session manager: restore session, select session, save session
local M = {}

local uv = vim.uv

local session_dir = vim.fn.stdpath("state") .. "/sessions/"

local function encode_path(path)
  return path:gsub("[\\/:]+", "%%")
end

local function decode_path(name)
  local path = name:gsub("%%", "/")

  if jit and jit.os:find("Windows") then
    path = path:gsub("^(%w)/", "%1:/")
  end

  return path
end

local function current_session()
  return session_dir .. encode_path(vim.fn.getcwd()) .. ".vim"
end

local function has_file_buffer()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= ""
        and not vim.tbl_contains({ "gitcommit", "gitrebase", "jj" }, vim.bo[bufnr].filetype) then
      return true
    end
  end

  return false
end

local function list_sessions()
  local sessions = vim.fn.glob(session_dir .. "*.vim", true, true)

  table.sort(sessions, function(a, b)
    local stat_a = uv.fs_stat(a)
    local stat_b = uv.fs_stat(b)

    if not stat_a or not stat_b then
      return stat_a ~= nil
    end

    return stat_a.mtime.sec > stat_b.mtime.sec
  end)

  return sessions
end

local function session_item(file)
  local name = vim.fn.fnamemodify(file, ":t:r")
  local dir = decode_path(name)

  return {
    file = file,
    dir = dir,
    label = vim.fn.fnamemodify(dir, ":p:~"),
  }
end

local function source_session(file)
  if not file or vim.fn.filereadable(file) == 0 then
    vim.notify("Session not found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "CoreSessionLoadPre" })
  vim.cmd("silent! source " .. vim.fn.fnameescape(file))
  vim.api.nvim_exec_autocmds("User", { pattern = "CoreSessionLoadPost" })
end

local function load_session(item)
  if not item then
    return
  end

  if vim.fn.isdirectory(item.dir) == 1 then
    vim.fn.chdir(item.dir)
  end

  source_session(item.file)
end

local function save_session()
  if not has_file_buffer() then
    return
  end

  vim.fn.mkdir(session_dir, "p")
  vim.api.nvim_exec_autocmds("User", { pattern = "CoreSessionSavePre" })
  vim.cmd("mksession! " .. vim.fn.fnameescape(current_session()))
  vim.api.nvim_exec_autocmds("User", { pattern = "CoreSessionSavePost" })
end

function M.load()
  source_session(current_session())
end

function M.load_last()
  source_session(list_sessions()[1])
end

function M.select()
  local items = vim.tbl_map(session_item, list_sessions())

  if vim.tbl_isempty(items) then
    vim.notify("No sessions found", vim.log.levels.WARN)
    return
  end

  local ok, fzf = pcall(require, "fzf-lua")

  if ok then
    fzf.fzf_exec(vim.tbl_map(function(item)
      return item.label
    end, items), {
      prompt = "Sessions> ",
      actions = {
        ["default"] = function(selected)
          if not selected or not selected[1] then
            return
          end

          for _, item in ipairs(items) do
            if item.label == selected[1] then
              load_session(item)
              return
            end
          end
        end,
      },
    })
    return
  end

  vim.ui.select(items, {
    prompt = "Select a session: ",
    format_item = function(item)
      return item.label
    end,
  }, load_session)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("core_session", { clear = true })

  vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "globals",
    "help",
    "localoptions",
    "tabpages",
    "terminal",
    "winsize",
    "winpos",
  }

  vim.keymap.set("n", "<leader>ss", M.load, { desc = "Restore current session" })
  vim.keymap.set("n", "<leader>sl", M.load_last, { desc = "Restore last session" })
  vim.keymap.set("n", "<leader>sS", M.select, { desc = "Select session" })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = save_session,
  })
end

return M
