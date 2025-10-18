return { -- Linting
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- golang
		-- lint.linters.golangci_lint = {
		-- 	cmd = "golangci-lint",
		-- 	stdin = false,
		-- 	args = {
		-- 		"run",
		-- 		"--output.json.path=stdout",
		-- 		"--output.text.path=",
		-- 		"--output.tab.path=",
		-- 		"--output.html.path=",
		-- 		"--output.checkstyle.path=",
		-- 		"--output.code-climate.path=",
		-- 		"--output.junit-xml.path=",
		-- 		"--output.teamcity.path=",
		-- 		"--output.sarif.path=",
		-- 		"--issues-exit-code=0",
		-- 		"--show-stats=false",
		-- 		"--path-mode=abs",
		-- 	},
		-- 	stream = "stdout",
		-- 	ignore_exitcode = true,
		-- 	parser = require("lint.parser").from_errorformat("%f:%l:%c: %m", {
		-- 		source = "golangci-lint",
		-- 	}),
		-- }

		lint.linters_by_ft = {
			-- python
			-- python = { "ruff" },

			-- golang
			-- go = { "golangci_lint" },

			-- lua = { "selene" },

			-- js/ts
			-- javascript = { "oxlint" },
			-- typescript = { "oxlint" },
			-- javascriptreact = { "oxlint" },
			-- typescriptreact = { "oxlint" },
		}

		-- To allow other plugins to add linters to require('lint').linters_by_ft,
		-- instead set linters_by_ft like this:
		-- lint.linters_by_ft = lint.linters_by_ft or {}
		-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
		--
		-- However, note that this will enable a set of default linters,
		-- which will cause errors unless these tools are available:
		-- {
		--   clojure = { "clj-kondo" },
		--   dockerfile = { "hadolint" },
		--   inko = { "inko" },
		--   janet = { "janet" },
		--   json = { "jsonlint" },
		--   markdown = { "vale" },
		--   rst = { "vale" },
		--   ruby = { "ruby" },
		--   terraform = { "tflint" },
		--   text = { "vale" }
		-- }
		--
		-- You can disable the default linters by setting their filetypes to nil:
		-- lint.linters_by_ft['clojure'] = nil
		-- lint.linters_by_ft['dockerfile'] = nil
		-- lint.linters_by_ft['inko'] = nil
		-- lint.linters_by_ft['janet'] = nil
		-- lint.linters_by_ft['json'] = nil
		-- lint.linters_by_ft['markdown'] = nil
		-- lint.linters_by_ft['rst'] = nil
		-- lint.linters_by_ft['ruby'] = nil
		-- lint.linters_by_ft['terraform'] = nil
		-- lint.linters_by_ft['text'] = nil

		-- Create autocommand which carries out the actual linting
		-- on the specified events.
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				-- Only run the linter in buffers that you can modify in order to
				-- avoid superfluous noise, notably within the handy LSP pop-ups that
				-- describe the hovered symbol using Markdown.
				if vim.bo.modifiable then
					lint.try_lint()
				end
			end,
		})
	end,
}
