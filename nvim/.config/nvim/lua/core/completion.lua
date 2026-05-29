local M = {}
_G.Compl = M

local protocol = vim.lsp.protocol

M._opts = {
  lsp = {
    autotrigger = true,
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

local compare_state
local compare_generation = 0

local kind_order = {}
for idx, name in ipairs(protocol.CompletionItemKind) do
  kind_order[name] = idx
end
-- Keep low-signal kinds near the bottom within the same source bucket.
kind_order.Text = 999
kind_order.Snippet = 1000
kind_order.Unknown = 1001

local context_kind_rank = {
  plain = {
    Variable = 8,
    Parameter = 8,
    Field = 7,
    Property = 7,
    Method = 6,
    Function = 6,
    Constructor = 5,
    Class = 4,
    Struct = 4,
    Enum = 4,
    Interface = 4,
    Constant = 4,
    EnumMember = 4,
    TypeParameter = 3,
    Module = 2,
    Keyword = 1,
  },
  member = {
    Field = 2,
    Property = 2,
    Method = 2,
    Function = 2,
    Variable = 1,
    Constant = 1,
    EnumMember = 1,
  },
  scope = {
    Function = 2,
    Constructor = 2,
    Constant = 2,
    EnumMember = 2,
    Method = 1,
    Struct = 1,
    Enum = 1,
    Class = 1,
    Interface = 1,
    Module = 1,
    TypeParameter = 1,
    Keyword = 1,
  },
}

local member_context_suffix_patterns = {
  "%?%.%s*$",
  "%-%>%s*$",
  "%.%s*$",
}

local scope_context_suffix_patterns = {
  "::%s*$",
}

local function get_lsp_item(entry)
  return vim.tbl_get(entry, "user_data", "nvim", "lsp", "completion_item") or {}
end

local function is_snippet_client(client)
  return client ~= nil and vim.tbl_get(client, "config", "_compl_source") == "snippet"
end

local function get_lsp_client(entry)
  local client_id = vim.tbl_get(entry, "user_data", "nvim", "lsp", "client_id")
  if type(client_id) ~= "number" then
    return nil
  end

  return vim.lsp.get_client_by_id(client_id)
end

local function is_lsp_entry(entry)
  if next(get_lsp_item(entry)) then
    return true
  end

  return get_lsp_client(entry) ~= nil
end

local function is_custom_snippet_entry(entry)
  local item = get_lsp_item(entry)
  if vim.tbl_get(item, "data", "compl", "source") == "snippet" then
    return true
  end

  return is_snippet_client(get_lsp_client(entry))
end

local function is_snippet_entry(entry)
  if is_custom_snippet_entry(entry) then
    return true
  end

  local item = get_lsp_item(entry)
  if item.insertTextFormat == protocol.InsertTextFormat.Snippet then
    return true
  end
  if item.kind == protocol.CompletionItemKind.Snippet or item.kind == "Snippet" then
    return true
  end

  return false
end

-- Resolve all LSP-related fields for an entry exactly once.
-- Returns a lightweight struct reused across all ranking functions inside
-- compare_item_data, avoiding repeated vim.tbl_get traversals.
local function resolve_lsp_info(entry)
  local lsp_ud = vim.tbl_get(entry, "user_data", "nvim", "lsp") or {}
  local item = lsp_ud.completion_item or {}

  local client_id = lsp_ud.client_id
  local client = type(client_id) == "number" and vim.lsp.get_client_by_id(client_id) or nil

  local has_item = next(item) ~= nil
  local is_lsp = has_item or client ~= nil

  local is_custom_snip = false
  if has_item then
    is_custom_snip = vim.tbl_get(item, "data", "compl", "source") == "snippet"
  end
  if not is_custom_snip then
    is_custom_snip = is_snippet_client(client)
  end

  local is_snip = is_custom_snip
  if not is_snip and has_item then
    is_snip = item.insertTextFormat == protocol.InsertTextFormat.Snippet
      or item.kind == protocol.CompletionItemKind.Snippet
      or item.kind == "Snippet"
  end

  return {
    item = item,
    client = client,
    is_lsp = is_lsp,
    is_custom_snippet = is_custom_snip,
    is_snippet = is_snip,
  }
end

local function has_completeopt(flag)
  return vim.list_contains(vim.opt.completeopt:get(), flag)
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

local function keyword_suffix_start(text)
  return vim.fn.match(text or "", "\\k*$")
end

local function keyword_suffix(text)
  text = text or ""
  local start = keyword_suffix_start(text)
  if start < 0 then
    return ""
  end

  return text:sub(start + 1)
end

local function current_prefix()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return ""
  end

  local line = vim.api.nvim_get_current_line():sub(1, col)
  return keyword_suffix(line)
end

local function line_to_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return ""
  end

  return vim.api.nvim_get_current_line():sub(1, col)
end

local function trim_keyword_suffix(text)
  text = text or ""
  local start = keyword_suffix_start(text)
  if start < 0 then
    return text
  end

  return text:sub(1, start)
end

local function completion_context_from_before(before)
  for _, pattern in ipairs(scope_context_suffix_patterns) do
    if before:match(pattern) then
      return "scope"
    end
  end

  for _, pattern in ipairs(member_context_suffix_patterns) do
    if before:match(pattern) then
      return "member"
    end
  end

  return nil
end

local function has_keyword_prefix(prefix)
  return keyword_suffix(prefix) ~= ""
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

local function current_filetype()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end

  return vim.bo[bufnr].filetype or ""
end

local function normalize_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end

  return bufnr
end

local function completion_key(entry, filetype)
  filetype = type(filetype) == "string" and filetype or current_filetype()

  local item = get_lsp_item(entry)
  if next(item) then
    return table.concat({
      filetype,
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
    filetype,
    label,
    tostring(entry.kind or ""),
    "plain",
  }, "\31")
end

local function completion_key_with_info(entry, info, filetype)
  filetype = type(filetype) == "string" and filetype or current_filetype()

  local item = info.item
  if next(item) then
    return table.concat({
      filetype,
      tostring(item.label or entry.abbr or entry.word or ""),
      tostring(item.kind or entry.kind or ""),
      info.is_snippet and "snippet" or "lsp",
    }, "\31")
  end

  local label = tostring(entry.abbr or entry.word or "")
  if label == "" then
    return nil
  end

  return table.concat({
    filetype,
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

local function completion_text_with_info(entry, info)
  local item = info.item
  if next(item) then
    return first_line(item.filterText or vim.tbl_get(item, "textEdit", "newText") or item.insertText or item.label)
  end

  return first_line(entry.word or entry.abbr or "")
end

local function label_text_with_info(entry, info)
  local item = info.item
  return tostring(item.label or entry.abbr or entry.word or "")
end

local function source_rank_with_info(info)
  if info.is_custom_snippet then return 3 end
  if info.is_lsp then
    if info.is_snippet then return 1 end
    return 0
  end
  return 2
end

local function completion_context(prefix)
  local before = line_to_cursor()
  if prefix ~= "" then
    before = before:sub(1, math.max(#before - #prefix, 0))
  end

  return completion_context_from_before(before)
end

local function completion_context_at_position(params)
  local uri = vim.tbl_get(params, "textDocument", "uri")
  local position = vim.tbl_get(params, "position")
  if type(uri) ~= "string" or type(position) ~= "table" then
    return nil
  end

  local bufnr = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1]
  if type(line) ~= "string" then
    return nil
  end

  local byte_col = vim.str_byteindex(line, "utf-16", position.character, false)
  if type(byte_col) ~= "number" then
    byte_col = #line
  end

  local before = trim_keyword_suffix(line:sub(1, byte_col))
  return completion_context_from_before(before)
end

local function empty_completion_result(result)
  if type(result) == "table" and result.items ~= nil then
    return {
      isIncomplete = result.isIncomplete or false,
      itemDefaults = result.itemDefaults,
      items = {},
    }
  end

  return {}
end

local function get_compare_state()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = cursor[1], cursor[2]
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  if compare_state
      and compare_state.bufnr == bufnr
      and compare_state.changedtick == changedtick
      and compare_state.cursor_row == cursor_row
      and compare_state.cursor_col == cursor_col then
    return compare_state
  end

  local prefix = current_prefix()
  compare_state = {
    bufnr = bufnr,
    changedtick = changedtick,
    cursor_row = cursor_row,
    cursor_col = cursor_col,
    prefix = prefix,
    context = completion_context(prefix),
    filetype = vim.bo[bufnr].filetype or "",
    fuzzy_sort = has_completeopt("fuzzy") and not has_completeopt("nosort"),
    now_ms = vim.uv.now(),
    item_cache = setmetatable({}, { __mode = "k" }),
  }

  compare_generation = compare_generation + 1
  local generation = compare_generation
  vim.schedule(function()
    if compare_generation == generation then
      compare_state = nil
    end
  end)

  return compare_state
end

local function query_rank(entry)
  -- Native completion may keep old items in the menu and annotate them with
  -- `match = false`. Those stale entries should never outrank the active query.
  if entry.match == false then
    return 0
  end

  return 1
end

local function prefix_rank_with_info(entry, info, prefix)
  if prefix == "" then
    return 0
  end

  for _, value in ipairs({ completion_text_with_info(entry, info), label_text_with_info(entry, info), entry.word }) do
    if starts_with_prefix(value, prefix) then
      return 2
    end
  end

  if entry.match == true or (entry._fuzzy_score or 0) > 0 then
    return 1
  end

  return 0
end

local function is_exact_match_with_info(entry, info, prefix)
  if prefix == "" then
    return false
  end

  local expected = normalize_case(prefix, prefix)
  for _, value in ipairs({ completion_text_with_info(entry, info), label_text_with_info(entry, info), entry.word }) do
    value = first_line(value)
    if value ~= "" and normalize_case(value, prefix) == expected then
      return true
    end
  end

  return false
end

local function completion_kind_with_info(entry, info)
  local item = info.item
  if type(item.kind) == "number" then
    return protocol.CompletionItemKind[item.kind] or entry.kind or "Unknown"
  end

  return entry.kind or "Unknown"
end

local function kind_rank_with_info(entry, info)
  return kind_order[completion_kind_with_info(entry, info)] or 500
end

local function context_rank_with_info(entry, info, context)
  local kind = completion_kind_with_info(entry, info)
  return vim.tbl_get(context_kind_rank, context or "plain", kind) or 0
end

local function sort_text_with_info(entry, info)
  local item = info.item
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

local function frecency_with_info(entry, info, filetype, now_ms)
  if not M._opts.history.enable then
    return 0
  end

  local key = completion_key_with_info(entry, info, filetype)
  local record = key and M._ctx.completion_history[key] or nil
  if not record then
    return 0
  end

  local age_in_ms = (now_ms or vim.uv.now()) - record.accepted_at
  local half_life = math.max(M._opts.history.half_life_ms, 1)
  return record.frequency * math.exp(-math.log(2) * age_in_ms / half_life)
end

local function prune_history()
  local max_entries = M._opts.history.max_entries
  if not max_entries or max_entries < 1 then
    return
  end

  local history = M._ctx.completion_history

  -- Count entries in a single pass.
  local count = 0
  for _ in pairs(history) do
    count = count + 1
  end

  local to_delete = count - max_entries
  if to_delete <= 0 then
    return
  end

  -- Collect all (key, accepted_at) pairs, sort ascending, drop the oldest.
  local entries = {}
  for key, record in pairs(history) do
    entries[#entries + 1] = { key = key, at = record.accepted_at }
  end

  table.sort(entries, function(a, b) return a.at < b.at end)

  for i = 1, to_delete do
    history[entries[i].key] = nil
  end
end

local function enable_completion(client_id, bufnr)
  vim.lsp.completion.enable(true, client_id, bufnr, {
    autotrigger = M._opts.lsp.autotrigger,
    cmp = M._compare_items,
  })
end

local function compare_item_data(entry, state)
  local data = state.item_cache[entry]
  if data then
    return data
  end

  -- Resolve LSP fields once; all ranking functions reuse this struct.
  local info = resolve_lsp_info(entry)
  local label = label_text_with_info(entry, info)
  data = {
    query = query_rank(entry),
    source = source_rank_with_info(info),
    exact = is_exact_match_with_info(entry, info, state.prefix),
    prefix = prefix_rank_with_info(entry, info, state.prefix),
    context = context_rank_with_info(entry, info, state.context),
    fuzzy = state.fuzzy_sort and (entry._fuzzy_score or 0) or 0,
    sort_text = sort_text_with_info(entry, info),
    kind = kind_rank_with_info(entry, info),
    frecency = frecency_with_info(entry, info, state.filetype, state.now_ms),
    label = label,
    label_len = #label,
  }

  state.item_cache[entry] = data
  return data
end

function M._compare_items(a, b)
  local state = get_compare_state()
  local a_data = compare_item_data(a, state)
  local b_data = compare_item_data(b, state)

  if a_data.query ~= b_data.query then
    return a_data.query > b_data.query
  end

  if a_data.exact ~= b_data.exact then
    return a_data.exact
  end

  if a_data.prefix ~= b_data.prefix then
    return a_data.prefix > b_data.prefix
  end

  if a_data.context ~= b_data.context then
    return a_data.context > b_data.context
  end

  if state.fuzzy_sort and a_data.prefix == 1 and b_data.prefix == 1 and a_data.fuzzy ~= b_data.fuzzy then
    return a_data.fuzzy > b_data.fuzzy
  end

  -- Prefer items you actually accept often, but only after live-query,
  -- source-specific, and context-aware ranking has already narrowed the field.
  if a_data.frecency ~= b_data.frecency then
    return a_data.frecency > b_data.frecency
  end

  if a_data.source ~= b_data.source then
    return a_data.source < b_data.source
  end

  local by_sort_text = compare_lexicographically(a_data.sort_text, b_data.sort_text)
  if by_sort_text ~= nil then
    return by_sort_text
  end

  if a_data.kind ~= b_data.kind then
    return a_data.kind < b_data.kind
  end

  local by_label = compare_lexicographically(a_data.label, b_data.label)
  if by_label ~= nil then
    return by_label
  end

  if a_data.label_len ~= b_data.label_len then
    return a_data.label_len < b_data.label_len
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

  local key = completion_key(completed_item, current_filetype())
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
    client:stop()
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
            labelDetails = {
              description = "[snip]",
            },
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

    function srv.request(method, params, callback)
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
        local result = completion_items
        if completion_context_at_position(params) ~= nil then
          result = empty_completion_result(completion_items)
        end

        respond(callback, nil, result)
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

  bufnr = normalize_bufnr(bufnr)
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
