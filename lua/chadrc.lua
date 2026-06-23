-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local helper = require("utils.helpers")

local function is_snacks_explorer_root_win(win)
  if not Snacks or not Snacks.picker or not Snacks.picker.get then
    return false
  end

  local ok, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  if not ok then
    return false
  end

  for _, picker in ipairs(pickers) do
    local root = picker.layout and picker.layout.root
    if root and root.win == win then
      return true
    end
  end

  return false
end

local function snacks_explorer_tree_offset()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" and is_snacks_explorer_root_win(win) then
      local width = vim.api.nvim_win_get_width(win)
      return "%#NvimTreeNormal#" .. string.rep(" ", width) .. "%#NvimTreeWinSeparator#" .. "│"
    end
  end

  return ""
end

M.base46 = {
  theme = "everforest_light",
  theme_toggle = { "everforest_light", "everforest" },
  transparency = helper.is_linux(),

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
      treeOffset = snacks_explorer_tree_offset,
    },
  },
  tabufline = {
    lazyload = false,
    modules = {
      treeOffset = snacks_explorer_tree_offset,
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
