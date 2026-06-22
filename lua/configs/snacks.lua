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
            },
          },
          list = {
            keys = {
              ["<c-n>"] = { "close", mode = "n", desc = "Toggle filetree" },
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
  terminal = {
    enabled = true,
    win = { style = "terminal" },
  },
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
