-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "catppuccin",

  hl_override = {
    ["@comment"] = { italic = true },
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
    "hop",
    "treesitter",
    "dap",
    "cmp",
    "blankline",
    "edgy",
    "grug_far",
    "mason",
    "notify",
    "flash",
    "lsp",
    "lspsaga",
    "whichkey",
    "trouble",
    "rainbowdelimiters",
    "git",
    "diffview",
    "devicons",
    "todo",
    "telescope",
    "tiny-inline-diagnostic",
  },
}

M.nvdash = { load_on_startup = true }
M.ui = {
  tabufline = {
    lazyload = false,
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
