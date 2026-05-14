local M = {}
_G.Compl = M

local protocol = vim.lsp.protocol

M._opts = {
  lsp = {
    -- Native ins-completion already drives omnifunc on every key when
    -- 'autocomplete' is enabled and 'complete' contains "o".
    autotrigger = false,
  },
  history = {
    enable = true,
    half_life_ms = 15 * 60 * 1000,
    max_entries = 1024,
  },
  snippet = {
    enable = true,
    paths = {
      vim.fs.joinpath(vim.fn.stdpath("config"), "snippets"),
    },
  },
}

M._ctx = {
  completion_history = {},
}

M._snippet = {
  sources = {},
}

local kind_order = {}
for idx, name in ipairs(protocol.CompletionItemKind) do
  kind_order[name] = idx
end
kind_order.Snippet = 0
kind_order.Text = 999
kind_order.Unknown = 1000

local function get_lsp_item(entry)
  return vim.tbl_get(entry, "user_data", "nvim", "lsp", "completion_item") or {}
end

local function is_snippet_client(client)
  return client ~= nil and vim.tbl_get(client, "config", "_compl_source") == "snippet"
end

local function is_snippet_entry(entry)
  local item = get_lsp_item(entry)
  if vim.tbl_get(item, "data", "compl", "source") == "snippet" then
    return true
  end

  local client_id = vim.tbl_get(entry, "user_data", "nvim", "lsp", "client_id")
  local client = type(client_id) == "number" and vim.lsp.get_client_by_id(client_id) or nil
  return is_snippet_client(client)
end

local function should_ignore_case(prefix)
  return vim.o.ignorecase and (not vim.o.smartcase or not prefix:find("%u"))
end

local function normalize_case(text, prefix)
  if should_ignore_case(prefix) then
    return text:lower()
  end

  return text
end

local function first_line(text)
  text = (text or ""):gsub("\r\n?", "\n")
  return text:match("([^\n]*)") or text
end

local function current_prefix()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return ""
  end

  local line = vim.api.nvim_get_current_line():sub(1, col)
  local start = vim.fn.match(line, "\\k*$")
  if start < 0 then
    return ""
  end

  return line:sub(start + 1)
end

local function line_to_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return ""
  end

  return vim.api.nvim_get_current_line():sub(1, col)
end

local function has_keyword_prefix(prefix)
  return prefix:find("%w") ~= nil
end

local function has_trigger_character_context(bufnr)
  local before = line_to_cursor()
  if before == "" then
    return false
  end

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/completion" })) do
    local triggers = vim.tbl_get(client.server_capabilities, "completionProvider", "triggerCharacters") or {}
    for _, trigger in ipairs(triggers) do
      if trigger ~= "" and vim.endswith(before, trigger) then
        return true
      end
    end
  end

  return false
end

local function should_trigger_omnifunc(bufnr, prefix)
  return has_keyword_prefix(prefix) or has_trigger_character_context(bufnr)
end

local function completion_key(entry)
  local item = get_lsp_item(entry)
  if next(item) then
    return table.concat({
      tostring(item.label or entry.abbr or entry.word or ""),
      tostring(item.kind or entry.kind or ""),
      is_snippet_entry(entry) and "snippet" or "lsp",
    }, "\31")
  end

  local label = tostring(entry.abbr or entry.word or "")
  if label == "" then
    return nil
  end

  return table.concat({
    label,
    tostring(entry.kind or ""),
    "plain",
  }, "\31")
end

local function starts_with_prefix(text, prefix)
  text = first_line(text)
  if prefix == "" or text == "" then
    return prefix == ""
  end

  return vim.startswith(normalize_case(text, prefix), normalize_case(prefix, prefix))
end

local function completion_text(entry)
  local item = get_lsp_item(entry)
  if next(item) then
    return first_line(item.filterText or vim.tbl_get(item, "textEdit", "newText") or item.insertText or item.label)
  end

  return first_line(entry.word or entry.abbr or "")
end

local function label_text(entry)
  local item = get_lsp_item(entry)
  return tostring(item.label or entry.abbr or entry.word or "")
end

local function source_rank(entry)
  if is_snippet_entry(entry) then
    return 1
  end

  return 0
end

local function query_rank(entry)
  -- Native completion may keep old items in the menu and annotate them with
  -- `match = false`. Those stale entries should never outrank the active query.
  if entry.match == false then
    return 0
  end

  return 1
end

local function prefix_rank(entry, prefix)
  if prefix == "" then
    return 0
  end

  for _, value in ipairs({ completion_text(entry), label_text(entry), entry.word }) do
    if starts_with_prefix(value, prefix) then
      return 2
    end
  end

  if entry.match == true or (entry._fuzzy_score or 0) > 0 then
    return 1
  end

  return 0
end

local function is_exact_match(entry, prefix)
  if prefix == "" then
    return false
  end

  local expected = normalize_case(prefix, prefix)
  for _, value in ipairs({ completion_text(entry), label_text(entry), entry.word }) do
    value = first_line(value)
    if value ~= "" and normalize_case(value, prefix) == expected then
      return true
    end
  end

  return false
end

local function completion_kind(entry)
  local item = get_lsp_item(entry)
  if type(item.kind) == "number" then
    return protocol.CompletionItemKind[item.kind] or entry.kind or "Unknown"
  end

  return entry.kind or "Unknown"
end

local function kind_rank(entry)
  return kind_order[completion_kind(entry)] or 500
end

local function sort_text(entry)
  local item = get_lsp_item(entry)
  return tostring(item.sortText or item.label or entry.abbr or entry.word or "")
end

local function compare_lexicographically(a, b)
  local diff = vim.stricmp(a, b)
  if diff < 0 then
    return true
  end
  if diff > 0 then
    return false
  end

  return nil
end

local function frecency(entry)
  if not M._opts.history.enable then
    return 0
  end

  local key = completion_key(entry)
  local record = key and M._ctx.completion_history[key] or nil
  if not record then
    return 0
  end

  local age_in_ms = vim.uv.now() - record.accepted_at
  local half_life = math.max(M._opts.history.half_life_ms, 1)
  return record.frequency * math.exp(-math.log(2) * age_in_ms / half_life)
end

local function prune_history()
  local max_entries = M._opts.history.max_entries
  if not max_entries or max_entries < 1 then
    return
  end

  while vim.tbl_count(M._ctx.completion_history) > max_entries do
    local oldest_key
    local oldest_at

    for key, record in pairs(M._ctx.completion_history) do
      if not oldest_at or record.accepted_at < oldest_at then
        oldest_key = key
        oldest_at = record.accepted_at
      end
    end

    if not oldest_key then
      break
    end

    M._ctx.completion_history[oldest_key] = nil
  end
end

local function enable_completion(client_id, bufnr)
  vim.lsp.completion.enable(true, client_id, bufnr, {
    autotrigger = M._opts.lsp.autotrigger,
    cmp = M._compare_items,
  })
end

function M._compare_items(a, b)
  local prefix = current_prefix()

  local a_source = source_rank(a)
  local b_source = source_rank(b)
  if a_source ~= b_source then
    return a_source < b_source
  end

  local a_query = query_rank(a)
  local b_query = query_rank(b)
  if a_query ~= b_query then
    return a_query > b_query
  end

  local a_prefix = prefix_rank(a, prefix)
  local b_prefix = prefix_rank(b, prefix)
  if a_prefix ~= b_prefix then
    return a_prefix > b_prefix
  end

  local a_exact = is_exact_match(a, prefix)
  local b_exact = is_exact_match(b, prefix)
  if a_exact ~= b_exact then
    return a_exact
  end

  -- Keep frecency within the same live-query/prefix bucket so it cannot lift
  -- stale or weakly related items above stronger current matches.
  local a_frecency = frecency(a)
  local b_frecency = frecency(b)
  if a_frecency ~= b_frecency then
    return a_frecency > b_frecency
  end

  local a_fuzzy = a._fuzzy_score or 0
  local b_fuzzy = b._fuzzy_score or 0
  if a_fuzzy ~= b_fuzzy then
    return a_fuzzy > b_fuzzy
  end

  local a_kind = kind_rank(a)
  local b_kind = kind_rank(b)
  if a_kind ~= b_kind then
    return a_kind < b_kind
  end

  local by_sort_text = compare_lexicographically(sort_text(a), sort_text(b))
  if by_sort_text ~= nil then
    return by_sort_text
  end

  local a_label = label_text(a)
  local b_label = label_text(b)
  local by_label = compare_lexicographically(a_label, b_label)
  if by_label ~= nil then
    return by_label
  end

  if #a_label ~= #b_label then
    return #a_label < #b_label
  end

  return false
end

function M.omnifunc(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()

  if findstart == 1 then
    local prefix = current_prefix()
    if not should_trigger_omnifunc(bufnr, prefix) then
      return -3
    end
  elseif not should_trigger_omnifunc(bufnr, base or "") then
    return {}
  end

  return vim.lsp.omnifunc(findstart, base)
end

function M._on_lsp_attach(args)
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if not client or not client:supports_method("textDocument/completion") then
    return
  end

  vim.bo[args.buf].omnifunc = "v:lua.Compl.omnifunc"
  enable_completion(client.id, args.buf)
end

function M._on_completedone()
  if not M._opts.history.enable then
    return
  end
  if vim.tbl_get(vim.v.event, "reason") ~= "accept" then
    return
  end

  local completed_item = vim.v.completed_item or {}
  if completed_item.match == false then
    return
  end

  local key = completion_key(completed_item)
  if not key then
    return
  end

  local record = M._ctx.completion_history[key] or { frequency = 0, accepted_at = 0 }
  record.frequency = record.frequency + 1
  record.accepted_at = vim.uv.now()
  M._ctx.completion_history[key] = record
  prune_history()
end

local function replace_items(target, items)
  for idx = #target, 1, -1 do
    target[idx] = nil
  end

  for _, item in ipairs(items) do
    target[#target + 1] = item
  end
end

local function stop_snippet_source(source)
  if not source or not source.client_id then
    return
  end

  local client = vim.lsp.get_client_by_id(source.client_id)
  if client then
    vim.lsp.stop_client(source.client_id)
  end

  source.client_id = nil
end

local function start_snippet_source(source, filetype, bufnr)
  vim.schedule(function()
    if not source or #source.list.items == 0 then
      stop_snippet_source(source)
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
      return
    end
    if vim.bo[bufnr].filetype ~= filetype then
      return
    end

    source.client_id = vim.lsp.start({
      name = ("snippets-%s"):format(filetype),
      cmd = M._make_lsp_server(source.list),
      _compl_source = "snippet",
    }, { bufnr = bufnr, silent = true }) or source.client_id
  end)
end

local function matches_filetype(filetype, language)
  if type(language) == "table" then
    return vim.iter(language):any(function(ft)
      return ft == filetype
    end)
  end

  return language == filetype
end

local function collect_snippet_items(snippet_data, items, seen)
  for _, snippet in pairs(snippet_data or {}) do
    local prefixes = type(snippet.prefix) == "table" and snippet.prefix or { snippet.prefix }
    local body = type(snippet.body) == "table" and table.concat(snippet.body, "\n") or snippet.body or ""
    local description = snippet.description or snippet.name or ""

    for _, prefix in ipairs(prefixes) do
      if type(prefix) == "string" and prefix ~= "" and body ~= "" then
        local key = table.concat({ prefix, body }, "\31")
        if not seen[key] then
          seen[key] = true
          items[#items + 1] = {
            label = prefix,
            kind = protocol.CompletionItemKind.Snippet,
            menu = "[snip]",
            detail = "snippet",
            data = {
              compl = {
                source = "snippet",
              },
            },
            documentation = description ~= "" and {
              kind = protocol.MarkupKind.Markdown,
              value = description,
            } or nil,
            insertTextFormat = protocol.InsertTextFormat.Snippet,
            insertText = body,
            filterText = prefix,
            sortText = prefix,
          }
        end
      end
    end
  end
end

function M._async_read(file, callback)
  vim.uv.fs_open(file, "r", 438, function(open_err, fd)
    if open_err or not fd then
      return callback(nil, open_err)
    end

    vim.uv.fs_fstat(fd, function(stat_err, stat)
      if stat_err or not stat or stat.type ~= "file" then
        return vim.uv.fs_close(fd, function()
          callback(nil, stat_err or "not a file")
        end)
      end

      vim.uv.fs_read(fd, stat.size, 0, function(read_err, data)
        vim.uv.fs_close(fd, function(close_err)
          if read_err or close_err then
            return callback(nil, read_err or close_err)
          end

          callback(data or "", nil)
        end)
      end)
    end)
  end)
end

function M._async_read_json(file, callback)
  M._async_read(file, function(buffer, err)
    if err or not buffer then
      return callback(nil, err)
    end

    local ok, data = pcall(vim.json.decode, buffer)
    if not ok or data == nil then
      vim.schedule(function()
        vim.notify(string.format("core.compl: Could not decode json file %s", file), vim.log.levels.ERROR)
      end)
      return callback(nil, "decode")
    end

    callback(data, nil)
  end)
end

function M._load_snippets(filetype, callback)
  local items = {}
  local seen = {}
  local pending = 0
  local done = false

  local function finish()
    if done or pending ~= 0 then
      return
    end

    done = true
    vim.schedule(function()
      callback(items)
    end)
  end

  local function read_json(file, on_data)
    pending = pending + 1
    M._async_read_json(file, function(data)
      if data then
        on_data(data)
      end

      pending = pending - 1
      finish()
    end)
  end

  local function is_file(path)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.type == "file"
  end

  for _, root in ipairs(M._opts.snippet.paths) do
    local expanded_root = vim.fn.resolve(vim.fn.expand(root))
    local manifest = vim.fs.joinpath(expanded_root, "package.json")

    if is_file(manifest) then
      read_json(manifest, function(manifest_data)
        for _, contribution in ipairs(vim.tbl_get(manifest_data, "contributes", "snippets") or {}) do
          if contribution.path and matches_filetype(filetype, contribution.language) then
            local snippet_file = vim.fn.resolve(vim.fs.joinpath(expanded_root, contribution.path))
            if is_file(snippet_file) then
              read_json(snippet_file, function(snippet_data)
                collect_snippet_items(snippet_data, items, seen)
              end)
            end
          end
        end
      end)
    end

    local flat_file = vim.fs.joinpath(expanded_root, string.format("%s.json", filetype))
    if is_file(flat_file) then
      read_json(flat_file, function(snippet_data)
        collect_snippet_items(snippet_data, items, seen)
      end)
    end
  end

  finish()
end

function M._make_lsp_server(completion_items)
  return function(dispatchers)
    local closing = false
    local srv = {}

    local function respond(callback, err, result)
      vim.schedule(function()
        callback(err, result)
      end)
    end

    function srv.request(method, _, callback)
      if method == "initialize" then
        respond(callback, nil, {
          capabilities = {
            completionProvider = {
              resolveProvider = false,
              triggerCharacters = {},
            },
          },
        })
      elseif method == "textDocument/completion" then
        respond(callback, nil, completion_items)
      elseif method == "shutdown" then
        closing = true
        respond(callback, nil, nil)
      end

      return true, 1
    end

    function srv.notify(method, _)
      if method == "exit" then
        dispatchers.on_exit(0, 15)
      end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end
end

function M._ensure_snippet_source(bufnr)
  if not M._opts.snippet.enable or #M._opts.snippet.paths == 0 then
    return
  end

  bufnr = vim._resolve_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype == "" then
    return
  end

  local source = M._snippet.sources[filetype]
  if not source then
    source = {
      client_id = nil,
      loaded = false,
      loading = false,
      pending_buffers = {},
      list = {
        isIncomplete = false,
        items = {},
      },
    }
    M._snippet.sources[filetype] = source
  end

  source.pending_buffers[bufnr] = true

  local function attach_pending_buffers()
    local pending_buffers = source.pending_buffers
    source.pending_buffers = {}

    if #source.list.items == 0 then
      stop_snippet_source(source)
      return
    end

    for pending_bufnr in pairs(pending_buffers) do
      start_snippet_source(source, filetype, pending_bufnr)
    end
  end

  if source.loaded then
    attach_pending_buffers()
    return
  end

  if source.loading then
    return
  end

  source.loading = true
  M._load_snippets(filetype, function(items)
    source.loading = false
    source.loaded = true
    replace_items(source.list.items, items)
    attach_pending_buffers()
  end)
end

function M._prioritize_omnifunc_source()
  local sources = vim.opt.complete:get()
  sources = vim.tbl_filter(function(source)
    return source ~= "o"
  end, sources)
  table.insert(sources, 1, "o")
  vim.opt.complete = sources
end

function M.setup(opts)
  if vim.fn.has("nvim-0.12") ~= 1 then
    vim.notify("core.compl: Requires nvim-0.12 or higher.", vim.log.levels.ERROR)
    return
  end

  M._opts = vim.tbl_deep_extend("force", M._opts, opts or {})
  vim.validate {
    ["lsp"] = { M._opts.lsp, "t" },
    ["lsp.autotrigger"] = { M._opts.lsp.autotrigger, "b" },
    ["history"] = { M._opts.history, "t" },
    ["history.enable"] = { M._opts.history.enable, "b" },
    ["history.half_life_ms"] = { M._opts.history.half_life_ms, "n" },
    ["history.max_entries"] = { M._opts.history.max_entries, "n" },
    ["snippet"] = { M._opts.snippet, "t" },
    ["snippet.enable"] = { M._opts.snippet.enable, "b" },
    ["snippet.paths"] = { M._opts.snippet.paths, "t" },
  }

  M._prioritize_omnifunc_source()

  local group = vim.api.nvim_create_augroup("CoreCompl", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = M._on_lsp_attach,
  })

  vim.api.nvim_create_autocmd("CompleteDone", {
    group = group,
    callback = M._on_completedone,
  })

  if M._opts.snippet.enable and #M._opts.snippet.paths > 0 then
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      group = group,
      callback = function(args)
        M._ensure_snippet_source(args.buf)
      end,
    })

    M._ensure_snippet_source(0)
  end
end

M.setup()

return M
