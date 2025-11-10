require("nvchad.options")

-- add yours here!

local o = vim.o
o.cursorlineopt = "both" -- to enable cursorline!
o.relativenumber = true
o.formatexpr = "v:lua.require'conform'.formatexpr()"
o.swapfile = false
o.autoindent = true
o.cursorcolumn = false
o.wrap = true
o.splitkeep = "cursor"
o.equalalways = true
