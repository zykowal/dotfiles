require("fidget").setup({
	notification = {
		override_vim_notify = true,
		window = {
			border = "none",
		},
	},
	progress = {
		display = {
			skip_history = false,
		},
	},
})

-- Fidget Message Fzf Previewer
local builtin = require("fzf-lua.previewer.builtin")
local fzf = require("fzf-lua")

local function trim_message(message)
	message = tostring(message or "")
	return message:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function format_timestamp(epoch)
	if type(epoch) ~= "number" then
		return ""
	end
	return os.date("%Y-%m-%d %H:%M:%S", epoch)
end

local function level_label(item)
	local style = tostring(item.style or "")
	if style == "" then
		return "INFO"
	end

	local upper = style:upper()
	if upper:find("ERROR", 1, true) then
		return "ERROR"
	end
	if upper:find("WARN", 1, true) then
		return "WARN"
	end
	if upper:find("INFO", 1, true) then
		return "INFO"
	end
	if upper:find("DEBUG", 1, true) then
		return "DEBUG"
	end
	return upper
end

local function group_label(item)
	return trim_message(item.group_name or item.group_key or "fidget")
end

local function build_summary(item)
	local pieces = {
		format_timestamp(item.last_updated),
		string.format("[%s]", level_label(item)),
		string.format("[%s]", group_label(item)),
	}

	local annote = trim_message(item.annote)
	if annote ~= "" then
		table.insert(pieces, annote .. ":")
	end

	local message = trim_message(item.message)
	if message ~= "" then
		table.insert(pieces, message)
	end

	return table.concat(pieces, " ")
end

local function build_preview(item)
	local lines = {
		"Time: " .. format_timestamp(item.last_updated),
		"Level: " .. level_label(item),
		"Group: " .. group_label(item),
		"State: " .. (item.removed and "removed" or "active"),
	}

	local annote = trim_message(item.annote)
	if annote ~= "" then
		table.insert(lines, "Title: " .. annote)
	end

	local data = item.data and vim.inspect(item.data) or nil
	if data then
		table.insert(lines, "")
		table.insert(lines, "Data:")
		vim.list_extend(lines, vim.split(data, "\n", { plain = true }))
	end

	local message = tostring(item.message or "")
	if message ~= "" then
		table.insert(lines, "")
		table.insert(lines, "Message:")
		vim.list_extend(lines, vim.split(message, "\n", { plain = true }))
	end

	return lines
end

local function build_entries()
	local history = require("fidget.notification").get_history({
		include_active = true,
		include_removed = true,
	})

	local entries = {}
	for index, item in ipairs(history) do
		local summary = build_summary(item)
		if summary ~= "" then
			local id = tostring(index)
			entries[id] = {
				item = item,
				display = string.format("%s\t%s", id, summary),
				ordinal = table.concat({
					group_label(item),
					trim_message(item.annote),
					trim_message(item.message),
				}, " "),
			}
		end
	end

	return entries
end

local function previewer(entries)
	local Previewer = builtin.buffer_or_file:extend()

	function Previewer:new(o, opts, fzf_win)
		Previewer.super.new(self, o, opts, fzf_win)
		self.title = "Message"
		setmetatable(self, Previewer)
		return self
	end

	function Previewer:parse_entry(entry_str)
		local id = entry_str:match("^(%d+)\t")
		local entry = entries[id]
		assert(entry, "No Fidget message found for entry: " .. entry_str)
		return entry
	end

	function Previewer:populate_preview_buf(entry_str)
		local buf = self:get_tmp_buffer()
		local entry = self:parse_entry(entry_str)
		local lines = build_preview(entry.item)

		vim.bo[buf].filetype = "markdown"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

		self:set_preview_buf(buf)
		self.win:update_preview_title("Message")
		self.win:update_preview_scrollbar()
	end

	return Previewer
end

local function open()
	local entries = build_entries()
	if vim.tbl_isempty(entries) then
		vim.notify("No Fidget messages available", vim.log.levels.INFO)
		return
	end

	local lines = {}
	for _, entry in pairs(entries) do
		table.insert(lines, entry.display)
	end

	table.sort(lines, function(a, b)
		return tonumber(a:match("^(%d+)\t")) > tonumber(b:match("^(%d+)\t"))
	end)

	fzf.fzf_exec(lines, {
		prompt = "> ",
		previewer = previewer(entries),
		fzf_opts = {
			["--delimiter"] = "\t",
			["--with-nth"] = "2..",
		},
	})
end

vim.keymap.set("n", "<leader>fn", open, { desc = "Fidget messages" })
