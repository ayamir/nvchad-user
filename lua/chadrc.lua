-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local helper = require("utils.helpers")

local function sidekick_statusline()
  local ok, sidekick = pcall(require, "sidekick.status")
  if not ok then
    return ""
  end

  local parts = {}
  local status = sidekick.get()
  local sessions = sidekick.cli()

  if status then
    local hl = "%#St_LspInfo#"
    if status.kind == "Error" then
      hl = "%#St_lspError#"
    elseif status.busy then
      hl = "%#St_lspWarning#"
    end
    parts[#parts + 1] = hl .. " "
  end

  if #sessions > 0 then
    parts[#parts + 1] = "%#St_LspInfo# " .. (#sessions > 1 and #sessions or "") .. " "
  end

  if #parts == 0 then
    return ""
  end

  return " " .. table.concat(parts, "")
end

M.base46 = {
  theme = "solarized_light",
  theme_toggle = { "solarized_light", "everforest" },
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
    "blankline",
    "treesitter",
    "dap",
    "blankline",
    "edgy",
    "grug_far",
    "mason",
    "notify",
    "lsp",
    "lspsaga",
    "whichkey",
    "trouble",
    -- "rainbowdelimiters",
    "git",
    "devicons",
    "todo",
    "telescope",
    "tiny-inline-diagnostic",
  },
}

M.nvdash = { load_on_startup = true }
M.ui = {
  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "sidekick", "%=", "diagnostics", "lsp", "cwd", "cursor" },
    modules = {
      sidekick = sidekick_statusline,
    },
  },
  tabufline = {
    lazyload = false,
  },
  telescope = {
    style = "bordered",
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
