local M = {}

local output_count = 0
local output_win = -1
local commit_states = {}
local setup_output_buffer

local command_names = {
  "add",
  "branch",
  "checkout",
  "commit",
  "diff",
  "fetch",
  "log",
  "pull",
  "push",
  "restore",
  "show",
  "stash",
  "status",
}

local output_commands = {
  branch = true,
  diff = true,
  log = true,
  show = true,
  stash = true,
  status = true,
}

local notify_commands = {
  add = true,
  checkout = true,
  fetch = true,
  pull = true,
  push = true,
  restore = true,
}

local function trim(text)
  return vim.trim(text or "")
end

local function slice(tbl, first)
  local ret = {}

  for i = first, #tbl do
    ret[#ret + 1] = tbl[i]
  end

  return ret
end

local function lines(text)
  if not text or text == "" then
    return { "" }
  end

  return vim.split(text:gsub("\r\n", "\n"), "\n", { plain = true })
end

local function current_file()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" or vim.fn.filereadable(file) == 0 then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return nil
  end

  return file
end

local function start_dirs()
  local dirs = {}
  local file = vim.api.nvim_buf_get_name(0)

  if file ~= "" and vim.fn.filereadable(file) == 1 then
    dirs[#dirs + 1] = vim.fs.dirname(file)
  end

  dirs[#dirs + 1] = vim.fn.getcwd()
  return dirs
end

local function git_sync(args, cwd)
  return vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
end

local function git_root()
  if vim.fn.executable("git") ~= 1 then
    vim.notify("git executable not found", vim.log.levels.ERROR)
    return nil
  end

  for _, dir in ipairs(start_dirs()) do
    if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
      local result = git_sync({ "rev-parse", "--show-toplevel" }, dir)

      if result.code == 0 then
        return trim(result.stdout)
      end
    end
  end

  vim.notify("Not inside a git repository", vim.log.levels.WARN)
  return nil
end

local function expand_args(args)
  local expanded = {}

  for _, arg in ipairs(args) do
    if arg:sub(1, 1) == "%" then
      local file = current_file()

      if not file then
        return nil
      end

      expanded[#expanded + 1] = vim.fn.expand(arg)
    else
      expanded[#expanded + 1] = arg
    end
  end

  return expanded
end

local function result_output(result)
  local parts = {}

  if result.stdout and result.stdout ~= "" then
    parts[#parts + 1] = result.stdout
  end

  if result.stderr and result.stderr ~= "" then
    parts[#parts + 1] = result.stderr
  end

  return table.concat(parts, "\n")
end

local function open_output(title, text, opts)
  opts = opts or {}
  output_count = output_count + 1

  local buf = vim.api.nvim_create_buf(false, true)
  local name = ("git://%d/%s"):format(output_count, title:gsub("[%s/]+", "-"))

  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.b[buf].core_git_output = true
  vim.b[buf].core_git_root = opts.root
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = opts.filetype or "git"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines(text))
  vim.bo[buf].modifiable = false

  if vim.api.nvim_win_is_valid(output_win) then
    vim.api.nvim_set_current_win(output_win)
  else
    local height = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 2))

    vim.cmd("belowright split")
    output_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(output_win, height)
  end

  local old_buf = vim.api.nvim_win_get_buf(output_win)

  vim.api.nvim_win_set_buf(output_win, buf)

  if vim.api.nvim_buf_is_valid(old_buf) and vim.b[old_buf].core_git_output then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end

  setup_output_buffer(buf)

  if opts.on_open then
    opts.on_open(buf)
  end
end

local function output_title(args)
  return "git " .. table.concat(args, " ")
end

local function close_output_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      if win == output_win then
        output_win = -1
      end

      pcall(vim.api.nvim_win_call, win, function()
        if #vim.api.nvim_list_wins() > 1 then
          vim.cmd.close()
        else
          vim.cmd.enew()
        end
      end)
    end
  end

  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

setup_output_buffer = function(buf)
  vim.keymap.set("n", "q", function()
    close_output_buffer(buf)
  end, { buffer = buf, desc = "Close Git output", nowait = true })
end

local function output_root(buf)
  local root = vim.b[buf].core_git_root

  if root and root ~= "" and vim.fn.isdirectory(root) == 1 then
    return root
  end

  return git_root()
end

local function run_git(args, opts)
  opts = opts or {}

  local expanded = expand_args(args)

  if not expanded then
    return
  end

  local root = opts.root or git_root()

  if not root then
    return
  end

  vim.system(vim.list_extend({ "git" }, expanded), { cwd = root, text = true }, function(result)
    vim.schedule(function()
      local title = output_title(expanded)
      local output = result_output(result)

      if opts.output then
        if result.code == 0 then
          open_output(title, output ~= "" and output or title .. " finished", vim.tbl_extend("force", opts, { root = root }))
        else
          open_output(title .. " failed", output, vim.tbl_extend("force", opts, { root = root }))
        end

        return
      end

      if result.code == 0 then
        local clean = trim(output)

        if clean == "" then
          vim.notify(title .. " finished", vim.log.levels.INFO)
        elseif #lines(clean) <= 3 then
          vim.notify(clean, vim.log.levels.INFO)
        else
          open_output(title, output, vim.tbl_extend("force", opts, { root = root }))
        end
      else
        open_output(title .. " failed", output, vim.tbl_extend("force", opts, { root = root }))
      end
    end)
  end)
end

local function add_commented(out, title, text)
  out[#out + 1] = "#"
  out[#out + 1] = "# " .. title

  local clean = trim(text)

  if clean == "" then
    out[#out + 1] = "#   (none)"
    return
  end

  for _, line in ipairs(lines(clean)) do
    out[#out + 1] = "#   " .. line
  end
end

local function has_message_arg(args)
  for _, arg in ipairs(args) do
    if arg == "-m" or arg == "--message" or arg:match("^%-%-message=") then
      return true
    end

    if arg == "-F" or arg == "--file" or arg:match("^%-%-file=") then
      return true
    end
  end

  return false
end

local function has_arg(args, value)
  for _, arg in ipairs(args) do
    if arg == value then
      return true
    end
  end

  return false
end

local function checkout_needs_confirm(args)
  for _, arg in ipairs(args) do
    if arg == "--" or arg:sub(1, 1) == "%" then
      return true
    end
  end

  return false
end

local function commit_template(root, args)
  local out = {}

  if has_arg(args, "--amend") then
    local last = git_sync({ "log", "-1", "--pretty=%B" }, root)

    if last.code == 0 and trim(last.stdout) ~= "" then
      vim.list_extend(out, lines(trim(last.stdout)))
    else
      out[#out + 1] = ""
    end
  else
    out[#out + 1] = ""
  end

  out[#out + 1] = ""
  out[#out + 1] = "# Please enter the commit message. Lines starting with '#' are ignored."
  out[#out + 1] = "# Save and close this buffer to commit. Close without saving to abort."

  local branch = git_sync({ "branch", "--show-current" }, root)
  local status = git_sync({ "status", "--short", "--branch" }, root)
  local staged = git_sync({ "diff", "--cached", "--stat" }, root)
  local staged_names = git_sync({ "diff", "--cached", "--name-status" }, root)

  add_commented(out, "Branch", branch.stdout)
  add_commented(out, "Status", status.stdout)
  add_commented(out, "Staged files", staged_names.stdout)
  add_commented(out, "Diff stat", staged.stdout)

  return out
end

local function commit_message_from_file(file)
  local ok, file_lines = pcall(vim.fn.readfile, file)

  if not ok then
    return nil
  end

  local message = {}

  for _, line in ipairs(file_lines) do
    if not line:match("^%s*#") then
      message[#message + 1] = line
    end
  end

  while #message > 0 and message[1]:match("^%s*$") do
    table.remove(message, 1)
  end

  while #message > 0 and message[#message]:match("^%s*$") do
    table.remove(message)
  end

  return table.concat(message, "\n")
end

local function finalize_commit(bufnr)
  local state = commit_states[bufnr]

  if not state or state.done then
    return
  end

  state.done = true
  commit_states[bufnr] = nil

  local modified = false
  local ok, value = pcall(vim.api.nvim_get_option_value, "modified", { buf = bufnr })

  if ok then
    modified = value
  end

  if not state.written or modified then
    vim.fn.delete(state.dir, "rf")
    vim.notify("Git commit aborted", vim.log.levels.INFO)
    return
  end

  local message = commit_message_from_file(state.edit_file)

  if not message or trim(message) == "" then
    vim.fn.delete(state.dir, "rf")
    vim.notify("Git commit aborted: empty message", vim.log.levels.WARN)
    return
  end

  vim.fn.writefile(lines(message), state.message_file)

  local args = vim.list_extend({ "commit" }, vim.deepcopy(state.args))
  vim.list_extend(args, { "--file", state.message_file })

  local result = git_sync(args, state.root)
  local title = output_title(args)
  local output = result_output(result)

  if result.code == 0 then
    vim.fn.delete(state.dir, "rf")

    local clean = trim(output)

    if clean == "" then
      vim.notify(title .. " finished", vim.log.levels.INFO)
    else
      vim.notify(clean, vim.log.levels.INFO)
    end
  else
    local failure = output

    if failure ~= "" then
      failure = failure .. "\n\n"
    end

    failure = failure .. "Commit message preserved at: " .. state.message_file
    open_output(title .. " failed", failure, { filetype = "git", root = state.root })
  end
end

local function open_commit(args)
  args = expand_args(args)

  if not args then
    return
  end

  if has_message_arg(args) then
    run_git(vim.list_extend({ "commit" }, args), { filetype = "git" })
    return
  end

  local root = git_root()

  if not root then
    return
  end

  local dir = vim.fn.tempname()

  vim.fn.mkdir(dir, "p")

  local edit_file = vim.fs.joinpath(dir, "COMMIT_EDITMSG")
  local message_file = vim.fs.joinpath(dir, "COMMIT_MSG")

  vim.fn.writefile(commit_template(root, args), edit_file)
  vim.cmd.edit(vim.fn.fnameescape(edit_file))

  local bufnr = vim.api.nvim_get_current_buf()

  vim.bo[bufnr].filetype = "gitcommit"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].textwidth = 72

  commit_states[bufnr] = {
    args = args,
    dir = dir,
    edit_file = edit_file,
    message_file = message_file,
    root = root,
    written = false,
    done = false,
  }

  local group = vim.api.nvim_create_augroup("core_git_commit", { clear = false })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = bufnr,
    callback = function()
      local state = commit_states[bufnr]

      if state then
        state.written = true
      end
    end,
  })

  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_buf() == bufnr then
        finalize_commit(bufnr)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      finalize_commit(bufnr)
    end,
  })
end

local function status_args(args)
  if #args == 1 then
    return { "status", "--short", "--branch" }
  end

  return args
end

local function log_args(args)
  if #args == 1 then
    return { "log", "--oneline", "--decorate", "--graph", "--all" }
  end

  return args
end

local function commit_from_log_line(line)
  return line:match("[%*|/\\ _%.%-]*([0-9a-fA-F]+)")
end

local function setup_log_buffer(buf)
  local function commit_under_cursor()
    return commit_from_log_line(vim.api.nvim_get_current_line())
  end

  local function open_commit_under_cursor()
    local commit = commit_under_cursor()

    if not commit then
      vim.notify("No commit found on current line", vim.log.levels.WARN)
      return
    end

    run_git({ "show", commit }, { output = true, filetype = "git", root = output_root(buf) })
  end

  local function copy_commit_under_cursor()
    local commit = commit_under_cursor()

    if not commit then
      vim.notify("No commit found on current line", vim.log.levels.WARN)
      return
    end

    vim.fn.setreg(vim.v.register, commit)
    vim.notify("Copied commit " .. commit, vim.log.levels.INFO)
  end

  vim.keymap.set("n", "o", open_commit_under_cursor, { buffer = buf, desc = "Git show commit", nowait = true })
  vim.keymap.set("n", "<CR>", open_commit_under_cursor, { buffer = buf, desc = "Git show commit" })
  vim.keymap.set("n", "y", copy_commit_under_cursor, { buffer = buf, desc = "Copy commit hash", nowait = true })
end

local function file_from_status_line(line)
  if line:match("^##") then
    return nil
  end

  local file = line:match("^..%s+(.+)$")

  if not file then
    return nil
  end

  file = file:gsub('^"(.*)"$', "%1")

  if file:find(" -> ", 1, true) then
    file = file:match("%s%->%s(.+)$") or file
    file = file:gsub('^"(.*)"$', "%1")
  end

  return file
end

local function setup_status_buffer(buf)
  vim.keymap.set("n", "o", function()
    local file = file_from_status_line(vim.api.nvim_get_current_line())

    if not file then
      vim.notify("No file found on current line", vim.log.levels.WARN)
      return
    end

    local root = output_root(buf)

    if not root then
      return
    end

    vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(root, file)))
  end, { buffer = buf, desc = "Open Git status file", nowait = true })
end

function M.run(args, opts)
  opts = opts or {}
  args = vim.deepcopy(args or {})

  if #args == 0 then
    args = { "status" }
  end

  local cmd = args[1]

  if cmd == "commit" then
    open_commit(slice(args, 2))
    return
  end

  if cmd == "restore" and not opts.bang then
    local message = "Run git " .. table.concat(args, " ") .. "?"

    if vim.fn.confirm(message, "&No\n&Yes", 1) ~= 2 then
      return
    end
  end

  if cmd == "checkout" and checkout_needs_confirm(args) and not opts.bang then
    local message = "Run git " .. table.concat(args, " ") .. "?"

    if vim.fn.confirm(message, "&No\n&Yes", 1) ~= 2 then
      return
    end
  end

  if cmd == "status" then
    run_git(status_args(args), { output = true, filetype = "git", on_open = setup_status_buffer })
    return
  end

  if cmd == "log" then
    run_git(log_args(args), { output = true, filetype = "git", on_open = setup_log_buffer })
    return
  end

  if cmd == "stash" and #args == 1 then
    run_git({ "stash", "list" }, { output = true, filetype = "git" })
    return
  end

  if output_commands[cmd] then
    run_git(args, { output = true, filetype = "git" })
    return
  end

  if notify_commands[cmd] then
    run_git(args, { filetype = "git" })
    return
  end

  run_git(args, { output = true, filetype = "git" })
end

function M.complete(arglead, cmdline, cursorpos)
  local line = cmdline:sub(1, cursorpos)
  local args = vim.split(line, "%s+", { trimempty = true })

  if line:match("^%s*Git!?%s+%S+%s") then
    return vim.fn.getcompletion(arglead, "file")
  end

  if #args <= 2 then
    return vim.tbl_filter(function(command)
      return command:sub(1, #arglead) == arglead
    end, command_names)
  end

  return vim.fn.getcompletion(arglead, "file")
end

function M.setup()
  vim.api.nvim_create_user_command("Git", function(opts)
    M.run(opts.fargs, { bang = opts.bang })
  end, {
    bang = true,
    complete = M.complete,
    desc = "Run git command",
    nargs = "*",
  })

  vim.keymap.set("n", "<leader>lg", ":Git ", { desc = "Git" })
end

return M
