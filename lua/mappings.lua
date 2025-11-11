require("nvchad.mappings")

local map = vim.keymap.set
local gitsigns = require("gitsigns")

map("n", "<C-n>", function()
  require("edgy").toggle("left")
end, { noremap = true, silent = true })
map("n", "<A-i>", function()
  require("nvchad.tabufline").next()
end, { noremap = true, silent = true, desc = "buffer: Switch to next" })

map("n", "<A-o>", function()
  require("nvchad.tabufline").prev()
end, { noremap = true, silent = true, desc = "buffer: Switch to prev" })

map("n", "<A-S-i>", function()
  require("nvchad.tabufline").move_buf(1)
end, { noremap = true, silent = true, desc = "buffer: Switch to next" })

map("n", "<A-S-o>", function()
  require("nvchad.tabufline").move_buf(-1)
end, { noremap = true, silent = true, desc = "buffer: Switch to prev" })

map("n", "<A-q>", function()
  require("nvchad.tabufline").close_buffer()
end, { noremap = true, silent = true, desc = "buffer: Close others" })

map("n", "<A-S-q>", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { noremap = true, silent = true, desc = "buffer: Close others" })

map("n", "<A-h>", ":SmartResizeLeft<CR>", { noremap = true, silent = true })
map("n", "<A-l>", ":SmartResizeRight<CR>", { noremap = true, silent = true })
map("n", "<A-j>", ":SmartResizeDown<CR>", { noremap = true, silent = true })
map("n", "<A-k>", ":SmartResizeUp<CR>", { noremap = true, silent = true })

map("t", "<C-w>h", "<cmd>wincmd h<CR>", { noremap = true, silent = true })
map("t", "<C-w>l", "<cmd>wincmd l<CR>", { noremap = true, silent = true })
map("t", "<C-w>j", "<cmd>wincmd j<CR>", { noremap = true, silent = true })
map("t", "<C-w>k", "<cmd>wincmd k<CR>", { noremap = true, silent = true })

map("n", "<C-h>", ":SmartCursorMoveLeft<CR>", { noremap = true, silent = true })
map("n", "<C-l>", ":SmartCursorMoveRight<CR>", { noremap = true, silent = true })
map("n", "<C-j>", ":SmartCursorMoveDown<CR>", { noremap = true, silent = true })
map("n", "<C-k>", ":SmartCursorMoveUp<CR>", { noremap = true, silent = true })

map("n", "<leader>w", ":HopWordMW<CR>", { noremap = true, silent = true })
map("n", "<leader>j", ":HopLineMW<CR>", { noremap = true, silent = true })
map("n", "<leader>k", ":HopLineMW<CR>", { noremap = true, silent = true })

map("v", "J", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
map("v", "<", "<gv", { noremap = true, silent = true })
map("v", ">", ">gv", { noremap = true, silent = true })

map("n", "Y", "y$", { noremap = true, silent = true })
map("n", "D", "d$", { noremap = true, silent = true })
map("n", "n", "nzzzv", { noremap = true, silent = true })
map("n", "N", "Nzzzv", { noremap = true, silent = true })
map("n", "J", "mzJ`z", { noremap = true, silent = true })

map("o", "m", function()
  require("tsht").nodes()
end, { noremap = true, silent = true })

map({ "n", "i", "t" }, "<C-\\>", function()
  require("nvchad.term").toggle({ pos = "sp", id = "HorizontalTerm" })
end, { noremap = true, silent = true })

map({ "n", "i", "t" }, "<A-\\>", function()
  require("nvchad.term").toggle({ pos = "vsp", id = "VerticalTerm" })
end, { noremap = true, silent = true })
map({ "n", "i", "t" }, "<A-d>", "<cmd>FloatermToggle<CR>", { noremap = true, silent = true })

map("n", "<leader>lr", ":LspStart<CR>", { noremap = true, silent = true })
map("n", "<leader>li", ":LspInfo<CR>", { noremap = true, silent = true })

map("n", "<leader>tc", function()
  require("neotest").run.run()
end, { noremap = true, silent = true })
map("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { noremap = true, silent = true })
map("n", "<leader>td", function()
  require("neotest").run.run({ strategy = "dap" })
end, { noremap = true, silent = true })
map("n", "<leader>tl", function()
  require("neotest").run.run_last()
end, { noremap = true, silent = true })
map("n", "<leader>to", ":Neotest output-panel<CR>", { noremap = true, silent = true })

map("n", "mx", ":BookmarksMark<CR>", { noremap = true, silent = true })
map("n", "mq", ":BookmarksQuickMark<CR>", { noremap = true, silent = true })
map("n", "mj", ":BookmarksGotoNext<CR>", { noremap = true, silent = true })
map("n", "mk", ":BookmarksGotoPrev<CR>", { noremap = true, silent = true })
map("n", "mo", ":BookmarksGoto<CR>", { noremap = true, silent = true })

map({ "n", "x", "o" }, "w", function()
  require("spider").motion("w")
end, { noremap = true, silent = true })
map({ "n", "x", "o" }, "e", function()
  require("spider").motion("e")
end, { noremap = true, silent = true })
map({ "n", "x", "o" }, "b", function()
  require("spider").motion("b")
end, { noremap = true, silent = true })

map("n", "]g", function()
  if vim.wo.diff then
    return "]g"
  end
  vim.schedule(function()
    gitsigns.nav_hunk("next")
  end)
  return "<Ignore>"
end, { noremap = true, silent = true, expr = true })
map("n", "[g", function()
  if vim.wo.diff then
    return "[g"
  end
  vim.schedule(function()
    gitsigns.nav_hunk("prev")
  end)
  return "<Ignore>"
end, { noremap = true, silent = true, expr = true })
map("n", "<leader>gs", function()
  gitsigns.stage_hunk()
end, { noremap = true, silent = true })
map("v", "<leader>gs", function()
  gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { noremap = true, silent = true })
map("n", "<leader>gr", function()
  gitsigns.reset_hunk()
end, { noremap = true, silent = true })
map("v", "<leader>gr", function()
  gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { noremap = true, silent = true })
map("n", "<leader>gR", function()
  gitsigns.reset_buffer()
end, { noremap = true, silent = true })
map("n", "<leader>gp", function()
  gitsigns.preview_hunk()
end, { noremap = true, silent = true })
map("n", "<leader>gb", function()
  gitsigns.blame_line({ full = true })
end, { noremap = true, silent = true })

map("n", "<leader>fr", ":Telescope resume<CR>", { noremap = true, silent = true })
map("n", "<leader>fR", ":FzfLua resume<CR>", { noremap = true, silent = true })

map("n", "<leader>s", ":Grugfar<CR>", { noremap = true, silent = true })
