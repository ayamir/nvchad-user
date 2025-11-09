require "nvchad.mappings"

local map = vim.keymap.set
local prompt_position = require("telescope.config").values.layout_config.horizontal.prompt_position
local fzf_opts = { ["--layout"] = prompt_position == "top" and "reverse" or "default" }

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

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

map("n", "<C-h>", ":SmartCursorMoveLeft<CR>", { noremap = true, silent = true })
map("n", "<C-l>", ":SmartCursorMoveRight<CR>", { noremap = true, silent = true })
map("n", "<C-j>", ":SmartCursorMoveDown<CR>", { noremap = true, silent = true })
map("n", "<C-k>", ":SmartCursorMoveUp<CR>", { noremap = true, silent = true })

map("n", "gt", ":Trouble diagnostics toggle", { noremap = true, silent = true })

map("n", "<leader>w", ":HopWordMW<CR>", { noremap = true, silent = true })
map("n", "<leader>j", ":HopLineMW<CR>", { noremap = true, silent = true })

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
  require("nvchad.term").toggle { pos = "sp", id = "HorizontalTerm" }
end, { noremap = true, silent = true })

map({ "n", "i", "t" }, "<A-\\>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "VerticalTerm" }
end, { noremap = true, silent = true })

map({ "n", "i", "t" }, "<A-d>", function()
  require("nvchad.term").toggle { pos = "float", id = "FloatTerm" }
end, { noremap = true, silent = true })

map("n", "go", ":Trouble symbols toggle win.position=right<CR>", { noremap = true, silent = true })
map("n", "g[", ":Lspsaga diagnostics_jump_prev<CR>", { noremap = true, silent = true })
map("n", "g]", ":Lspsaga diagnostics_jump_next<CR>", { noremap = true, silent = true })
map("n", "gr", ":Lspsaga rename", { noremap = true, silent = true })
map("n", "gR", ":Lspsaga rename ++project", { noremap = true, silent = true })
map("n", "gd", ":Lspsaga peek_definition", { noremap = true, silent = true })
map("n", "gD", ":Lspsaga goto_definition", { noremap = true, silent = true })
map("n", "gh", function()
  require("fzf-lua").lsp_references { fzf_opts = fzf_opts }
end, { noremap = true, silent = true })
map("n", "gm", function()
  require("fzf-lua").lsp_implementations { fzf_opts = fzf_opts }
end, { noremap = true, silent = true })
