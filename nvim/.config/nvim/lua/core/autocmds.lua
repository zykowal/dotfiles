vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufRead" }, {
  pattern = "*",
  callback = function()
    vim.fn.matchadd("Question", [[TODO:]])
    vim.fn.matchadd("OkMsg", [[NOTE:]])
    vim.fn.matchadd("ErrorMsg", [[FIXME:]])
    vim.fn.matchadd("ErrorMsg", [[BUG:]])
    vim.fn.matchadd("DiagnosticWarn", [[PERF:]])
    vim.fn.matchadd("DiagnosticWarn", [[OPTIMIZE:]])
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help", "vim", "checkhealth"
  },
  callback = function(event)
    vim.keymap.set("n", "q", function()
      vim.cmd("close")
    end, { buffer = event.buf, silent = true })
  end,

})
