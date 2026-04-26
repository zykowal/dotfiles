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

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help", "vim", "checkhealth", "gitsigns-blame"
  },
  callback = function(event)
    vim.keymap.set("n", "q", function()
      vim.cmd("close")
    end, { buffer = event.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    local opts = { buffer = true, silent = true }
    vim.keymap.set('n', 'o', '<CR>', opts)
    vim.keymap.set('n', 'q', function () vim.cmd("close") end, opts)
    vim.keymap.set('n', '>', '<C-w>+', opts)
    vim.keymap.set('n', '<', '<C-w>-', opts)
  end,
})
