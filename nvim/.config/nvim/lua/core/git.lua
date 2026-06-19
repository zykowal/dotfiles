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
  "rebase",
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

local function apply_output_panel_opts(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local opts = {
    colorcolumn = "",
    cursorline = true,
    foldcolumn = "0",
    foldenable = false,
    list = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = "",
    winfixheight = true,
    wrap = false,
  }

  for name, value in pairs(opts) do
    pcall(vim.api.nvim_set_option_value, name, value, { win = win })
  end
end

local function open_output(title, text, opts)
  opts = opts or {}
  output_count = output_count + 1

  local buf = vim.api.nvim_create_buf(false, true)
  local name = ("git://%d/%s"):format(output_count, title:gsub("[%s/]+", "-"))

  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.b[buf].core_git_output = true
  vim.b[buf].core_git_root = opts.root
  vim.b[buf].core_git_previous_buf = opts.previous_buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = opts.filetype or "git"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines(text))
  vim.bo[buf].modifiable = false

  if vim.api.nvim_win_is_valid(output_win) then
    vim.api.nvim_set_current_win(output_win)
  else
    local height = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 2))

    vim.cmd("keepalt belowright split")
    output_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(output_win, height)
  end

  local old_buf = vim.api.nvim_win_get_buf(output_win)

  vim.api.nvim_win_set_buf(output_win, buf)
  apply_output_panel_opts(output_win)

  if vim.api.nvim_buf_is_valid(old_buf) and vim.b[old_buf].core_git_output and old_buf ~= opts.previous_buf then
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

  local previous_buf = vim.b[buf].core_git_previous_buf

  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.api.nvim_win_is_valid(win) then
        if win == output_win then
          vim.api.nvim_win_set_buf(win, previous_buf)
          apply_output_panel_opts(win)
        end
      end
    end

    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end

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

local function open_git_terminal(args)
  local expanded = expand_args(args)

  if not expanded then
    return
  end

  local root = git_root()

  if not root then
    return
  end

  local height = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 2))

  vim.cmd("keepalt belowright split")
  vim.cmd.lcd(vim.fn.fnameescape(root))
  vim.api.nvim_win_set_height(0, height)
  vim.cmd.terminal(vim.list_extend({ "git" }, expanded))
  vim.bo.buflisted = false
  vim.cmd.startinsert()
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

local function has_prefixed_arg(args, prefix)
  for _, arg in ipairs(args) do
    if arg:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

local function has_staged_changes(root)
  return git_sync({ "diff", "--cached", "--quiet" }, root).code ~= 0
end

local function has_head(root)
  return git_sync({ "rev-parse", "--verify", "--quiet", "HEAD" }, root).code == 0
end

local function has_tracked_worktree_changes(root)
  return git_sync({ "diff", "--quiet" }, root).code ~= 0
end

local function commit_has_content(root, args)
  if has_arg(args, "--amend") or has_arg(args, "--allow-empty") or has_prefixed_arg(args, "--allow-empty=") then
    return true
  end

  if has_arg(args, "-a") or has_arg(args, "--all") then
    return has_staged_changes(root) or has_tracked_worktree_changes(root)
  end

  return has_staged_changes(root)
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

  if not commit_has_content(root, args) then
    vim.notify("No staged changes to commit", vim.log.levels.WARN)
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
  vim.bo[bufnr].buflisted = false
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
  local commit = line:match("^[%s%*|/\\_%.%-]*commit%s+([0-9a-fA-F]+)")

  if commit then
    return commit
  end

  commit = line:match("^[%s%*|/\\_%.%-]*([0-9a-fA-F]+)%s")

  if commit and #commit >= 4 then
    return commit
  end

  return nil
end

local function blob_hash_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local old, new = line:match("^index%s+([0-9a-fA-F]+)%.%.([0-9a-fA-F]+)")

  if not old or not new then
    return nil
  end

  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local old_start = line:find(old, 1, true)
  local new_start = line:find(new, old_start + #old + 2, true)

  if col >= old_start and col < old_start + #old then
    return old
  end

  if col >= new_start and col < new_start + #new then
    return new
  end

  return nil
end

local function diff_file_under_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local buf = vim.api.nvim_get_current_buf()

  for lnum = row, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
    local old, new = line:match("^diff %-%-git a/(.-) b/(.+)$")

    if old or new then
      return new ~= "/dev/null" and new or old
    end
  end

  return nil
end

local function filetype_for_blob(path)
  local ok, filetype = pcall(vim.filetype.match, { filename = path })

  if ok then
    return filetype
  end

  return nil
end

local function setup_commit_details_buffer(buf)
  vim.keymap.set("n", "o", function()
    local hash = blob_hash_under_cursor()

    if not hash then
      vim.notify("No blob hash found under cursor", vim.log.levels.WARN)
      return
    end

    if hash:match("^0+$") then
      vim.notify("No blob exists for " .. hash, vim.log.levels.WARN)
      return
    end

    local root = output_root(buf)

    if not root then
      return
    end

    local result = git_sync({ "cat-file", "-p", hash }, root)
    local file = diff_file_under_cursor()
    local title = "git cat-file -p " .. hash

    if result.code ~= 0 then
      open_output(title .. " failed", result_output(result), { filetype = "git", root = root, previous_buf = buf })
      return
    end

    open_output(title, result.stdout, { filetype = filetype_for_blob(file), root = root, previous_buf = buf })
  end, { buffer = buf, desc = "Git show blob", nowait = true })
end

local function open_commit_details(root, commit, previous_buf)
  local meta = git_sync({ "show", "--no-patch", "--format=fuller", commit }, root)
  local stat = git_sync({ "show", "--stat", "--format=", commit }, root)
  local diff = git_sync({ "show", "--format=", "--patch", commit }, root)
  local title = "git show " .. commit

  if meta.code ~= 0 then
    open_output(title .. " failed", result_output(meta), { filetype = "git", root = root, previous_buf = previous_buf })
    return
  end

  if stat.code ~= 0 then
    open_output(title .. " failed", result_output(stat), { filetype = "git", root = root, previous_buf = previous_buf })
    return
  end

  if diff.code ~= 0 then
    open_output(title .. " failed", result_output(diff), { filetype = "git", root = root, previous_buf = previous_buf })
    return
  end

  local content = table.concat({
    trim(meta.stdout),
    "---",
    trim(stat.stdout) ~= "" and stat.stdout or "(none)",
    trim(diff.stdout) ~= "" and diff.stdout or "(none)",
  }, "\n")

  open_output(title, content, { filetype = "git", root = root, previous_buf = previous_buf, on_open = setup_commit_details_buffer })
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

    local root = output_root(buf)

    if not root then
      return
    end

    open_commit_details(root, commit, buf)
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

local function status_info_from_line(line)
  if line:match("^##") then
    return nil
  end

  local file = line:match("^..%s+(.+)$")
  local old_file

  if not file then
    return nil
  end

  file = file:gsub('^"(.*)"$', "%1")

  if file:find(" -> ", 1, true) then
    old_file = file:match("^(.-)%s%->%s")
    file = file:match("%s%->%s(.+)$") or file
    old_file = old_file and old_file:gsub('^"(.*)"$', "%1")
    file = file:gsub('^"(.*)"$', "%1")
  end

  return {
    file = file,
    old_file = old_file or file,
    index = line:sub(1, 1),
    worktree = line:sub(2, 2),
    untracked = line:sub(1, 2) == "??",
  }
end

local function filetype_for_path(path)
  local ok, filetype = pcall(vim.filetype.match, { filename = path })

  if ok then
    return filetype
  end

  return nil
end

local function blob_lines(root, file)
  local result = git_sync({ "show", "HEAD:" .. file }, root)

  if result.code ~= 0 then
    return { "" }
  end

  return lines(result.stdout)
end

local function worktree_lines(file)
  local ok, content = pcall(vim.fn.readfile, file)

  if ok then
    return content
  end

  return { "" }
end

local function setup_diff_buffer(buf, name, content, filetype)
  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype or ""
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
end

local function close_status_diff(left_buf, right_win, right_buf, status_buf, status_win)
  for _, win in ipairs({ status_win, right_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_call, win, function()
        vim.cmd.diffoff()
      end)
    end
  end

  if right_win and vim.api.nvim_win_is_valid(right_win) then
    pcall(vim.api.nvim_win_close, right_win, false)
  end

  if vim.api.nvim_win_is_valid(status_win) and vim.api.nvim_buf_is_valid(status_buf) then
    vim.api.nvim_win_set_buf(status_win, status_buf)
    vim.api.nvim_set_current_win(status_win)
    apply_output_panel_opts(status_win)

    if vim.b[status_buf].core_git_output then
      output_win = status_win
    end
  end

  if vim.api.nvim_buf_is_valid(left_buf) then
    pcall(vim.api.nvim_buf_delete, left_buf, { force = true })
  end

  if right_buf and vim.api.nvim_buf_is_valid(right_buf) and vim.b[right_buf].core_git_status_diff_temp then
    pcall(vim.api.nvim_buf_delete, right_buf, { force = true })
  end
end

local function open_status_diff(root, info)
  local filetype = filetype_for_path(info.file)
  local status_buf = vim.api.nvim_get_current_buf()
  local status_win = vim.api.nvim_get_current_win()
  local left_buf = vim.api.nvim_create_buf(false, true)
  local left_name = ("git://HEAD/%s"):format(info.old_file)
  local right_file = vim.fs.joinpath(root, info.file)
  local right_buf
  local right_win

  setup_diff_buffer(left_buf, left_name, blob_lines(root, info.old_file), filetype)

  vim.keymap.set("n", "q", function()
    close_status_diff(left_buf, right_win, right_buf, status_buf, status_win)
  end, { buffer = left_buf, desc = "Close Git diff", nowait = true })

  if status_win == output_win then
    output_win = -1
  end

  vim.api.nvim_win_set_buf(status_win, left_buf)
  apply_output_panel_opts(status_win)
  vim.cmd.diffthis()

  vim.cmd("rightbelow vertical split")
  right_win = vim.api.nvim_get_current_win()

  if vim.fn.filereadable(right_file) == 1 then
    vim.cmd.edit(vim.fn.fnameescape(right_file))
    right_buf = vim.api.nvim_get_current_buf()
  else
    right_buf = vim.api.nvim_create_buf(false, true)
    local right_name = ("git://WORKTREE/%s"):format(info.file)

    setup_diff_buffer(right_buf, right_name, worktree_lines(right_file), filetype)
    vim.b[right_buf].core_git_status_diff_temp = true
    vim.api.nvim_win_set_buf(0, right_buf)
  end

  vim.cmd.diffthis()
end

local function setup_status_buffer(buf)
  local function info_under_cursor()
    local info = status_info_from_line(vim.api.nvim_get_current_line())

    if not info then
      vim.notify("No file found on current line", vim.log.levels.WARN)
      return
    end

    return info
  end

  local function restore_status_cursor(file, fallback_row)
    local row = fallback_row or 1

    if file then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      for lnum, line in ipairs(lines) do
        local info = status_info_from_line(line)

        if info and info.file == file then
          row = lnum
          break
        end
      end
    end

    row = math.min(row, math.max(1, vim.api.nvim_buf_line_count(0)))
    pcall(vim.api.nvim_win_set_cursor, 0, { row, 0 })
  end

  local function refresh_status(root, info, fallback_row)
    run_git(status_args({ "status" }), {
      output = true,
      filetype = "git",
      root = root,
      on_open = function(status_buf)
        setup_status_buffer(status_buf)
        restore_status_cursor(info and info.file or nil, fallback_row)
      end,
    })
  end

  local function run_status_action(root, args, info)
    local title = output_title(args)
    local fallback_row = vim.api.nvim_win_get_cursor(0)[1]

    vim.system(vim.list_extend({ "git" }, args), { cwd = root, text = true }, function(result)
      vim.schedule(function()
        local output = result_output(result)

        if result.code == 0 then
          local clean = trim(output)

          vim.notify(clean ~= "" and clean or title .. " finished", vim.log.levels.INFO)
          refresh_status(root, info, fallback_row)
        else
          open_output(title .. " failed", output, { filetype = "git", root = root })
        end
      end)
    end)
  end

  local function unstage_file(root, info)
    if info.index == "A" and not has_head(root) then
      run_status_action(root, { "rm", "--cached", "--", info.file }, info)
      return
    end

    run_status_action(root, { "restore", "--staged", "--", info.file }, info)
  end

  local function root_for_status()
    local root = output_root(buf)

    if not root then
      return
    end

    return root
  end

  vim.keymap.set("n", "o", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(root, info.file)))
  end, { buffer = buf, desc = "Open Git status file", nowait = true })

  vim.keymap.set("n", "a", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    run_status_action(root, { "add", "--", info.file }, info)
  end, { buffer = buf, desc = "Git add file", nowait = true })

  vim.keymap.set("n", "A", function()
    local root = root_for_status()

    if not root then
      return
    end

    run_status_action(root, { "add", "--all" })
  end, { buffer = buf, desc = "Git add all files", nowait = true })

  vim.keymap.set("n", "u", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    if info.untracked or info.index == " " then
      vim.notify("File is not staged: " .. info.file, vim.log.levels.WARN)
      return
    end

    unstage_file(root, info)
  end, { buffer = buf, desc = "Git unstage file", nowait = true })

  vim.keymap.set("n", "U", function()
    local root = root_for_status()

    if not root then
      return
    end

    if not has_staged_changes(root) then
      vim.notify("No staged changes to unstage", vim.log.levels.WARN)
      return
    end

    if not has_head(root) then
      run_status_action(root, { "rm", "--cached", "-r", "--", "." })
      return
    end

    run_status_action(root, { "restore", "--staged", "--", "." })
  end, { buffer = buf, desc = "Git unstage all files", nowait = true })

  vim.keymap.set("n", "r", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    if info.untracked then
      vim.notify("Cannot restore untracked file: " .. info.file, vim.log.levels.WARN)
      return
    end

    if vim.fn.confirm("Discard changes to " .. info.file .. "?", "&No\n&Yes", 1) ~= 2 then
      return
    end

    if info.index == "A" and info.worktree == " " then
      unstage_file(root, info)
      return
    end

    run_status_action(root, { "restore", "--staged", "--worktree", "--", info.file }, info)
  end, { buffer = buf, desc = "Git restore file", nowait = true })

  vim.keymap.set("n", "x", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    if vim.fn.confirm("Discard all changes to " .. info.file .. "?", "&No\n&Yes", 1) ~= 2 then
      return
    end

    if info.untracked then
      run_status_action(root, { "clean", "-f", "--", info.file }, info)
      return
    end

    if info.index == "A" then
      run_status_action(root, { "rm", "-f", "--cached", "--", info.file }, info)
      return
    end

    run_status_action(root, { "restore", "--staged", "--worktree", "--", info.file }, info)
  end, { buffer = buf, desc = "Git discard file", nowait = true })

  vim.keymap.set("n", "d", function()
    local info = info_under_cursor()
    local root = root_for_status()

    if not info or not root then
      return
    end

    if info.untracked then
      vim.notify("No git diff for untracked file: " .. info.file, vim.log.levels.WARN)
      return
    end

    open_status_diff(root, info)
  end, { buffer = buf, desc = "Git diff file", nowait = true })

  vim.keymap.set("n", "c", function()
    local root = root_for_status()

    if not root then
      return
    end

    if not commit_has_content(root, {}) then
      vim.notify("No staged changes to commit", vim.log.levels.WARN)
      return
    end

    open_commit({})
  end, { buffer = buf, desc = "Git commit staged changes", nowait = true })
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

  if cmd == "rebase" then
    open_git_terminal(args)
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

  vim.keymap.set("n", "<C-g>b", "<cmd>Git branch -a<CR>", { desc = "Git branch" })
  vim.keymap.set("n", "<C-g>s", "<cmd>Git status<CR>", { desc = "Git status" })
  vim.keymap.set("n", "<C-g>S", ":Git stash ", { desc = "Git stash" })
  vim.keymap.set("n", "<C-g>c", ":Git checkout ", { desc = "Git checkout" })
  vim.keymap.set("n", "<C-g>r", ":Git rebase ", { desc = "Git rebase" })
  vim.keymap.set("n", "<C-g>f", "<cmd>Git fetch -atp<CR>", { desc = "Git fetch" })
  vim.keymap.set("n", "<C-g>l", "<cmd>Git log<CR>", { desc = "Git log" })
  vim.keymap.set("n", "<C-g>p", "<cmd>Git pull<CR>", { desc = "Git pull" })
  vim.keymap.set("n", "<C-g>P", "<cmd>Git push<CR>", { desc = "Git push" })
end

return M
