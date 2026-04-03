-- Pull in the wezterm API
local wezterm = require("wezterm")
local mappings = require("keymappings")
local keytables = require("keytables")

-- This will hold the configuration.
local config = wezterm.config_builder()

config = {
	color_scheme = "Catppuccin Mocha",
	font = wezterm.font("Monaco"),
	-- harfbuzz_features = { "calt", "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "ss09", "liga" },
	font_size = 18,
	enable_tab_bar = false,
	window_decorations = "RESIZE",
	window_background_opacity = 0.8,
	macos_window_background_blur = 20,
	audible_bell = "Disabled",
	exit_behavior = "Close",
	use_dead_keys = false,
	window_close_confirmation = "NeverPrompt",
	adjust_window_size_when_changing_font_size = false,
	-- for windows
	-- default_prog = { "powershell" or "pwsh" },
	-- default_cwd = os.getenv("PWD") or os.getenv("OLDPWD")
	window_padding = {
		left = 10,
		right = 10,
		top = 15,
		bottom = 0,
	},
	hyperlink_rules = {
		-- Matches: a URL in parens: (URL)
		{
			regex = "\\((\\w+://\\S+)\\)",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in brackets: [URL]
		{
			regex = "\\[(\\w+://\\S+)\\]",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in curly braces: {URL}
		{
			regex = "\\{(\\w+://\\S+)\\}",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in angle brackets: <URL>
		{
			regex = "<(\\w+://\\S+)>",
			format = "$1",
			highlight = 1,
		},
		-- Then handle URLs not wrapped in brackets
		{
			-- Before
			--regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
			--format = '$0',
			-- After
			regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
			format = "$1",
			highlight = 1,
		},
		-- implicit mailto link
		{
			regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
			format = "mailto:$0",
		},
	},
	-- background = {
	-- 	{
	-- 		source = {
	-- 			File = wezterm.config_dir .. "/background.png",
	-- 		},
	-- 		hsb = {
	-- 			hue = 1.0,
	-- 			saturation = 1.02,
	-- 			brightness = 0.25,
	-- 		},
	-- 		-- attachment = { Parallax = 0.3 },
	-- 		-- width = "100%",
	-- 		-- height = "100%",
	-- 	},
	-- 	{
	-- 		source = {
	-- 			-- Color = "#282c35",
	-- 			Color = "#000000",
	-- 		},
	-- 		width = "100%",
	-- 		height = "100%",
	-- 		opacity = 0.5,
	-- 	},
	-- },
}

config.leader = mappings.leader
config.keys = mappings.keys
config.key_tables = keytables.key_tables

-- and finally, return the configuration to wezterm
return config
