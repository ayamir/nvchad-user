local function current_explorer_root_win()
  if not Snacks or not Snacks.picker or not Snacks.picker.get then
    return nil
  end

  local current_win = vim.api.nvim_get_current_win()
  local ok, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  if not ok then
    return nil
  end

  for _, picker in ipairs(pickers) do
    local layout = picker.layout
    local root = layout and layout.root
    if root and root.win == current_win then
      return root.win
    end

    local wins = layout and layout.wins or {}
    for _, name in ipairs({ "input", "list", "preview" }) do
      local win = wins[name]
      if win and win.win == current_win then
        return root and root.win or nil
      end
    end
  end

  return nil
end

local function focus_left_sidebar(dir)
  local root_win = current_explorer_root_win()
  if not root_win then
    return false
  end

  local ok, editor = pcall(require, "edgy.editor")
  if not ok then
    return false
  end

  local win = editor.get_win(root_win)
  if not win or win.view.edgebar.pos ~= "left" then
    return false
  end

  local target = dir == "up" and win:prev({ visible = true, focus = true })
    or win:next({ visible = true, focus = true })
  if target then
    return true
  end

  local siblings = win.view.edgebar.wins or {}
  if #siblings == 0 then
    return false
  end

  local start = dir == "up" and #siblings or 1
  local step = dir == "up" and -1 or 1
  for i = start, dir == "up" and 1 or #siblings, step do
    local sibling = siblings[i]
    if sibling and sibling.visible then
      sibling:focus()
      return true
    end
  end

  return false
end

local function move_down_from_explorer()
  focus_left_sidebar("down")
end

local function move_up_from_explorer()
  focus_left_sidebar("up")
end

return {
  bigfile = { enabled = true },
  dashboard = { enabled = true },
  explorer = {
    enabled = true,
    replace_netrw = true,
  },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 1000,
    style = "compact",
    width = { min = 50, max = 0.4 },
  },
  picker = {
    enabled = true,
    ui_select = true,
    layout = {
      preset = "ivy",
    },
    matcher = {
      fuzzy = true,
      smartcase = true,
      ignorecase = true,
      filename_bonus = true,
      frecency = true,
      history_bonus = true,
    },
    sources = {
      explorer = {
        layout = { preset = "sidebar", preview = { enabled = false, main = true } },
        win = {
          input = {
            keys = {
              ["<c-n>"] = { "close", mode = { "i", "n" }, desc = "Toggle filetree" },
              ["<c-j>"] = { move_down_from_explorer, mode = { "i", "n" }, desc = "Focus lower sidebar window" },
              ["<c-k>"] = { move_up_from_explorer, mode = { "i", "n" }, desc = "Focus upper sidebar window" },
              ["<c-w>j"] = { move_down_from_explorer, mode = { "i", "n" }, desc = "Focus lower sidebar window" },
              ["<c-w>k"] = { move_up_from_explorer, mode = { "i", "n" }, desc = "Focus upper sidebar window" },
            },
          },
          list = {
            keys = {
              ["<c-n>"] = { "close", mode = "n", desc = "Toggle filetree" },
              ["<c-j>"] = { move_down_from_explorer, mode = "n", desc = "Focus lower sidebar window" },
              ["<c-k>"] = { move_up_from_explorer, mode = "n", desc = "Focus upper sidebar window" },
              ["<c-w>j"] = { move_down_from_explorer, mode = "n", desc = "Focus lower sidebar window" },
              ["<c-w>k"] = { move_up_from_explorer, mode = "n", desc = "Focus upper sidebar window" },
            },
          },
          preview = {
            width = 0.55,
            height = 0.45,
            row = 0.18,
            col = 0.225,
            border = "rounded",
            title = " {preview} ",
            title_pos = "center",
            backdrop = false,
          },
        },
      },
    },
  },
  quickfile = { enabled = true },
  terminal = { enabled = false },
  words = { enabled = true },
  styles = {
    terminal = {
      position = "float",
      relative = "editor",
      row = 0.1,
      col = 0.1,
      width = 0.8,
      height = 0.8,
      border = "single",
      wo = { number = false, relativenumber = false },
    },
  },
}
