local leap = require "leap"
leap.opts.labels = 'sfnjklhodweimbuyvrgtaqpcxz/?'
leap.opts.safe_labels = {}
leap.opts.on_beacons = function(targets, _, _)
  for _, t in ipairs(targets) do
    if t.label and t.beacon then t.beacon[1] = 0 end
  end
end

vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap-anywhere)', { desc = 'Leap' })
vim.keymap.set({'n', 'x', 'o'}, 'S', function() require("leap.remote").action() end, { desc = 'Leap remote' })
vim.keymap.set({'n', 'x', 'o'}, 'f', '<Plug>(leap-forward)')
vim.keymap.set({'n', 'x', 'o'}, 'F', '<Plug>(leap-backward)')
vim.keymap.set({'n', 'x', 'o'}, 't', '<Plug>(leap-forward-till)')
vim.keymap.set({'n', 'x', 'o'}, 'T', '<Plug>(leap-backward-till)')
