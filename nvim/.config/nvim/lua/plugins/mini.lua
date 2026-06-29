return {
  {
	  "nvim-mini/mini.ai",
	  event = "BufRead",
	  version = "*",
	  config = function()
		  require("mini.ai").setup({ n_lines = 500 })
	  end,
  },
  {
	  "nvim-mini/mini.bufremove",
	  event = "BufRead",
	  version = "*",
	  keys = {
		  {
			  "<leader>c",
			  function()
				  require("mini.bufremove").delete()
			  end,
			  desc = "Close current buffer",
		  },
	  },
  }
}
