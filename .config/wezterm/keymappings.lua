local wezterm = require("wezterm")
local act = wezterm.action
local mappings = {}

wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

local function is_vim(pane)
	local process_info = pane:get_foreground_process_info()
	local process_name = process_info and process_info.name

	return process_name == "nvim" or process_name == "vim"
end

local direction_keys = {
	Left = "h",
	Down = "j",
	Up = "k",
	Right = "l",
	-- reverse lookup
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

-- This is where you can define custom keybindings
mappings.leader = { key = ";", mods = "CTRL", timeout_milliseconds = 1000 }

mappings.keys = {
	{ key = ";", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{
		key = "|",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "\\",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "h",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "k",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "z",
		mods = "CTRL",
		action = wezterm.action.TogglePaneZoomState,
	},
	{
		key = "w",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},
	{ key = "c", mods = "LEADER", action = act.SwitchToWorkspace },
	{ key = "n", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
	{ key = "p", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{ key = "Space", mods = "LEADER", action = wezterm.action.QuickSelect },
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
}

return mappings
