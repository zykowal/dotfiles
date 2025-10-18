local wezterm = require("wezterm")
local act = wezterm.action

local copy_mode = {}
if wezterm.gui then
	copy_mode = wezterm.gui.default_key_tables().copy_mode
	table.insert(copy_mode, {
		key = "L",
		mods = "NONE",
		action = act.CopyMode("MoveToEndOfLineContent"),
	})
	table.insert(copy_mode, {
		key = "H",
		mods = "NONE",
		action = act.CopyMode("MoveToStartOfLine"),
	})

	table.insert(copy_mode, {
		key = "i",
		mods = "NONE",
		action = act.CopyMode("Close"),
	})
end

return {
	key_tables = {
		copy_mode = copy_mode,
	},
}
