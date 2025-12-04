return function()
  require("toggleterm").setup({
    size = function()
      return math.floor(vim.o.lines * 0.7) -- 高度 70%
    end,
    hide_numbers = true,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = true,
    direction = "float",
    close_on_exit = true,
    float_opts = {
      border = "rounded",
      width = math.floor(vim.o.columns * 0.75),
      height = math.floor(vim.o.lines * 0.7),
      winblend = 15,
    },
    shade_terminals = false,
    highlights = {
      Normal = { guibg = "NONE" },
      NormalFloat = { guibg = "#1e1e2e" },
      FloatBorder = { guifg = "#45475a", guibg = "NONE" },
    },
  })
end
