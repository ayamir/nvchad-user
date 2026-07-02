-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local helper = require("utils.helpers")

local function nvim_tree_offset()
  if vim.bo.filetype == "NvimTree" then
    return ""
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if
      vim.api.nvim_win_get_config(win).relative == "" and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree"
    then
      local width = vim.api.nvim_win_get_width(win)
      return "%#NvimTreeNormal#" .. string.rep(" ", width) .. "%#NvimTreeWinSeparator#" .. "│"
    end
  end

  return ""
end

M.base46 = {
  theme = "rosepine",
  theme_toggle = { "rosepine", "rosepine-dawn" },
  transparency = helper.is_linux(),

  hl_override = {
    ["@comment"] = { italic = true },
    ["@keyword"] = { italic = true, bold = true },
    NvDashButtons = {
      italic = true,
    },
    Function = {
      bold = true,
    },
    Keyword = {
      italic = true,
    },
    Operator = {
      bold = true,
    },
    Conditional = {
      bold = true,
    },
    Loop = {
      bold = true,
    },
    Boolean = {
      italic = true,
      bold = true,
    },
    Comment = {
      italic = true,
    },
  },

  integrations = {
    "blankline",
    "hop",
    "bookmarks",
    "blink",
    "treesitter",
    "dap",
    "edgy",
    "grug_far",
    "mason",
    "lsp",
    "lspsaga",
    "whichkey",
    "trouble",
    -- "rainbowdelimiters",
    "git",
    "devicons",
    "todo",
    "tiny-inline-diagnostic",
  },
}

M.nvdash = { load_on_startup = false }
M.ui = {
  statusline = {
    order = { "treeOffset", "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor" },
    modules = {
      treeOffset = nvim_tree_offset,
    },
  },
  tabufline = {
    lazyload = false,
    modules = {
      treeOffset = nvim_tree_offset,
    },
  },
}
M.term = {
  base46_colors = true,
  winopts = { number = false, relativenumber = false },
  sizes = { sp = 0.3, vsp = 0.3, ["bo sp"] = 0.3, ["bo vsp"] = 0.3 },
  float = {
    relative = "editor",
    row = 0.1,
    col = 0.1,
    width = 0.8,
    height = 0.8,
    border = "single",
  },
}

return M
