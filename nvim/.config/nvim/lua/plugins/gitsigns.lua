require("gitsigns").setup({
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map("n", "]h", function()
      gitsigns.nav_hunk("next")
    end, { desc = "Next hunk" })

    map("n", "[h", function()
      gitsigns.nav_hunk("prev")
    end, { desc = "Prev hunk" })

    map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage hunk" })
    map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage buffer" })

    map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset hunk" })
    map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset buffer" })

    map("v", "<leader>gs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }, { desc = "Stage hunk" })
    end)
    map("v", "<leader>gr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }, { desc = "Reset hunk" })
    end)

    map("n", "<leader>gp", gitsigns.preview_hunk_inline, { desc = "Preview hunk" })

    map("n", "<leader>gl", gitsigns.blame, { desc = "Blame" })

    map("n", "<leader>gq", gitsigns.setqflist, { desc = "Git quickfix list" })

    map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff" })

    map("n", "<leader>gT", gitsigns.toggle_current_line_blame, { desc = "Toggle blame" })

    map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "Select hunk" })
  end,
})
