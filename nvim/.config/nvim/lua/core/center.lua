local M = {}

M.cfg = {
	skip_filetypes = {},
	enabled = true, -- takes precedence over `active`
	active = true, -- for internally disabling plugin behavior
	allow_scroll_move = true,
	disable_on_mouse = true,
}

local insert = "insert"
local other = "other"

local function must_skip_file(skip_filetypes, current_type)
    if not skip_filetypes then
        return false
    end

    if type(skip_filetypes) == "string" then
        return skip_filetypes == current_type
    end

    if type(skip_filetypes) == "table" then
        return vim.tbl_contains(skip_filetypes, current_type)
    end

    return false
end

local function stay_centered(ctx)
    -- hot path: minimize global/table lookups
    if not ctx.cfg.enabled or not ctx.cfg.active then
        return
    end

    if vim.bo.buftype == "terminal" then
        return
    end

    if must_skip_file(ctx.cfg.skip_filetypes, vim.bo.filetype) then
        return
    end

    local api = vim.api
    local fn = vim.fn

    local pos = api.nvim_win_get_cursor(0)
    local line = pos[1]

    -- track last line per window (window-local) to support splits
    if vim.w.last_line == nil then
        vim.w.last_line = line
    end

    -- check if cursor moved from window scroll
    if ctx.cfg.allow_scroll_move then
        local scrolloff = vim.wo.scrolloff or vim.o.scrolloff
        local top = fn.line("w0") + scrolloff
        local bottom = fn.line("w$") - scrolloff
        if (line <= top and line > vim.w.last_line) or (line >= bottom and line < vim.w.last_line) then
            vim.w.last_line = line
            return
        end
    end

    if line ~= vim.w.last_line then
        if ctx.mode == insert then
            -- in insert mode, use <C-o>zz so we stay in insert and only run a single normal cmd
            local seq = api.nvim_replace_termcodes("<C-o>zz", true, false, true)
            api.nvim_feedkeys(seq, "n", false)
        else
            -- normal/other modes: run normal! zz
            vim.cmd("normal! zz")
        end

        vim.w.last_line = line
    end
end

M.setup = function(ctx)
	if ctx == nil then
		return
	end

	M.cfg.skip_filetypes = ctx.skip_filetypes or {}
	if type(ctx.enabled) == "boolean" then
		M.cfg.enabled = ctx.enabled
	end
	if type(ctx.allow_scroll_move) == "boolean" then
		M.cfg.allow_scroll_move = ctx.allow_scroll_move
	end
	if type(ctx.disable_on_mouse) == "boolean" then
		M.cfg.disable_on_mouse = ctx.disable_on_mouse
	end

    if M.cfg.disable_on_mouse then
        -- If a previous callback exists, stop it first
        if M.mcb_stop then
            pcall(M.mcb_stop)
        end
        M.mcb_stop = vim.on_key(M.mouse_callback)
    else
        if M.mcb_stop then
            pcall(M.mcb_stop)
            M.mcb_stop = nil
        end
    end
end

local add_group = vim.api.nvim_create_augroup
local group = add_group("StayCentered", { clear = true })

local add_command = vim.api.nvim_create_autocmd
add_command("CursorMovedI", {
	group = group,
	callback = function()
		stay_centered({ mode = insert, cfg = M.cfg })
	end,
})
add_command("CursorMoved", {
	group = group,
	callback = function()
		stay_centered({ mode = other, cfg = M.cfg })
	end,
})
add_command("BufEnter", {
	group = group,
	callback = function()
		stay_centered({ mode = other, cfg = M.cfg })
	end,
})

M.enable = function()
	M.cfg.enabled = true

	-- if mouse-based disable behavior is enabled, ensure the on_key callback is registered
	if M.cfg.disable_on_mouse and not M.mcb_stop then
		M.mcb_stop = vim.on_key(M.mouse_callback)
	end

	stay_centered({ mode = other, cfg = M.cfg })
end

M.disable = function()
	M.cfg.enabled = false

	-- stop mouse callback when plugin is disabled to avoid unnecessary callbacks
	if M.mcb_stop then
		pcall(M.mcb_stop)
		M.mcb_stop = nil
	end
end

M.toggle = function()
	if M.cfg.enabled then
		M.disable()
	else
		M.enable()
	end
end

M.activate = function()
	M.cfg.active = true
end

M.deactivate = function()
	M.cfg.active = false
end

M.mouse_callback = function(key, typed)
	if not M.cfg.enabled then
		return
	end

    if key == vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true) then
        M.deactivate()
    end
    if key == vim.api.nvim_replace_termcodes("<LeftDrag>", true, false, true) then
    end
    if key == vim.api.nvim_replace_termcodes("<LeftRelease>", true, false, true) then
        -- update window-local last_line when mouse release occurs
        vim.w.last_line = vim.api.nvim_win_get_cursor(0)[1]
        M.activate()
    end
end

return M
