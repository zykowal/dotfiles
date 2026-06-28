vim.pack.add({
	{ src = "https://github.com/monkoose/neocodeium" },
}, { confirm = false })

require("neocodeium").setup()

vim.keymap.set({ 'i', 'c' }, '<C-l>', function()
  return require("neocodeium").accept()
end, { expr = true })
vim.keymap.set('i', '<Tab>',function()
  return require("neocodeium").cycle_or_complete()
end, { expr = true })
vim.keymap.set('i', '<S-Tab>',function()
  return require("neocodeium").cycle_or_complete(-1)
end, { expr = true })
