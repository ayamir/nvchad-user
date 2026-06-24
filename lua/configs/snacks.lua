return {
  bigfile = { enabled = true },
  dashboard = { enabled = true },
  indent = {
    enabled = true,
    animate = { enabled = false },
    scope = { enabled = true },
  },
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
  },
  quickfile = { enabled = true },
  terminal = { enabled = false },
  words = { enabled = false },
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
