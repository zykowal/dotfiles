local leap = require "leap"
leap.opts.labels = 'sfnjklhodweimbuyvrgtaqpcxz/?'
leap.opts.safe_labels = {}
leap.opts.on_beacons = function(targets, _, _)
  for _, t in ipairs(targets) do
    if t.label and t.beacon then t.beacon[1] = 0 end
  end
end

do
  local function ft(key_specific_args)
    require('leap').leap(
      vim.tbl_deep_extend('keep', key_specific_args, {
        inputlen = 1,
        inclusive = true,
        opts = {
          labels = 'sfnjklhodweimburgtaqpz/?',
          safe_labels = vim.fn.mode(1):match('o') and '' or nil,
        },
      })
    )
  end

  local clever = require('leap.user').with_traversal_keys
  local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')

  vim.keymap.set({ 'n', 'x', 'o' }, 'f', function()
    ft { opts = clever_f }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'F', function()
    ft { backward = true, opts = clever_f }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 't', function()
    ft { offset = -1, opts = clever_t }
  end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'T', function()
    ft { backward = true, offset = 1, opts = clever_t }
  end)
end

vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)', { desc = 'Leap' })
vim.keymap.set({'n', 'x', 'o'}, 'S', function() require("leap.remote").action() end, { desc = 'Leap remote' })
