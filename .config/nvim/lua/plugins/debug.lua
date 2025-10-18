return {
	"mfussenegger/nvim-dap",
	lazy = true,
	dependencies = {
		-- Creates a beautiful debugger UI
		"rcarriga/nvim-dap-ui",

		-- Required dependency for nvim-dap-ui
		"nvim-neotest/nvim-nio",

		-- Installs the debug adapters for you
		"mason-org/mason.nvim",
		{
			"jay-babu/mason-nvim-dap.nvim",
			opts = {
				ensure_installed = {
					-- python
					-- "python",

					-- golang
					-- "delve",
				},
			},
		},
	},
	keys = {

		{
			"<F5>",
			function()
				require("dap").continue()
			end,
			desc = "Debugger: Start",
		},
		{
			"<F17>",
			function()
				require("dap").terminate()
			end,
			desc = "Debugger: Stop",
		}, -- Shift+F5
		{
			"<F21>",
			function()
				vim.ui.input({ prompt = "Condition: " }, function(condition)
					if condition then
						require("dap").set_breakpoint(condition)
					end
				end)
			end,
			desc = "Debugger: Conditional Breakpoint",
		}, -- Shift+F9
		{
			"<F29>",
			function()
				require("dap").restart_frame()
			end,
			desc = "Debugger: Restart",
		}, -- Control+F5
		{
			"<F6>",
			function()
				require("dap").pause()
			end,
			desc = "Debugger: Pause",
		},
		{
			"<F9>",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debugger: Toggle Breakpoint",
		},
		{
			"<F10>",
			function()
				require("dap").step_over()
			end,
			desc = "Debugger: Step Over",
		},
		{
			"<F11>",
			function()
				require("dap").step_into()
			end,
			desc = "Debugger: Step Into",
		},
		{
			"<F23>",
			function()
				require("dap").step_out()
			end,
			desc = "Debugger: Step Out",
		}, -- Shift+F11
		{
			"<Leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint (F9)",
		},
		{
			"<Leader>dB",
			function()
				require("dap").clear_breakpoints()
			end,
			desc = "Clear Breakpoints",
		},
		{
			"<Leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Start/Continue (F5)",
		},
		{
			"<Leader>dC",
			function()
				vim.ui.input({ prompt = "Condition: " }, function(condition)
					if condition then
						require("dap").set_breakpoint(condition)
					end
				end)
			end,
			desc = "Conditional Breakpoint (S-F9)",
		},
		{
			"<Leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into (F11)",
		},
		{
			"<Leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over (F10)",
		},
		{
			"<Leader>dO",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out (S-F11)",
		},
		{
			"<Leader>dq",
			function()
				require("dap").close()
			end,
			desc = "Close Session",
		},
		{
			"<Leader>dQ",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate Session (S-F5)",
		},
		{
			"<Leader>dp",
			function()
				require("dap").pause()
			end,
			desc = "Pause (F6)",
		},
		{
			"<Leader>dr",
			function()
				require("dap").restart_frame()
			end,
			desc = "Restart (C-F5)",
		},
		{
			"<Leader>dR",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Toggle REPL",
		},
		{
			"<Leader>ds",
			function()
				require("dap").run_to_cursor()
			end,
			desc = "Run To Cursor",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("mason-nvim-dap").setup({
			-- Makes a best effort to setup the various debuggers with
			-- reasonable debug configurations
			automatic_installation = true,

			-- You can provide additional configuration to the handlers,
			-- see mason-nvim-dap README for more information
			handlers = {},

			-- You'll need to check that you have the required things installed
			-- online, please don't ask me how to install them :)
			ensure_installed = {
				-- Update this to ensure that you have the debuggers for the langs you want
			},
		})

		-- Dap UI setup
		-- For more information, see |:help nvim-dap-ui|
		dapui.setup({
			-- Set icons to characters that are more likely to work in every terminal.
			--    Feel free to remove or use ones that you like more! :)
			--    Don't feel like these are good choices.
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "󰏤",
					play = "󰐊",
					step_into = "󰆹",
					step_over = "󰆷",
					step_out = "󰆸",
					step_back = "󰓕",
					run_last = "▶▶",
					terminate = "󰓛",
					disconnect = "󰇪",
				},
			},
		})

		-- Change breakpoint icons
		vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
		vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
		local breakpoint_icons = vim.g.have_nerd_font
				and {
					Breakpoint = "",
					BreakpointCondition = "",
					BreakpointRejected = "",
					LogPoint = "",
					Stopped = "",
				}
			or {
				Breakpoint = "●",
				BreakpointCondition = "⊜",
				BreakpointRejected = "⊘",
				LogPoint = "◆",
				Stopped = "⭔",
			}
		for type, icon in pairs(breakpoint_icons) do
			local tp = "Dap" .. type
			local hl = (type == "Stopped") and "DapStop" or "DapBreak"
			vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
		end

		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close

		-- Install golang specific config
	end,
}
