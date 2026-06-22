return function()
  local function trouble_filter(position)
    return function(_, win)
      local tw = vim.w[win].trouble
      return tw
        and tw.position == position
        and tw.type == "split"
        and tw.relative == "editor"
        and not vim.w[win].trouble_preview
    end
  end

  local function is_explorer_win(win)
    for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
      local list = picker.list and picker.list.win
      local input = picker.input and picker.input.win
      local preview = picker.preview and picker.preview.win

      if (list and list.win == win) or (input and input.win == win) or (preview and preview.win == win) then
        return true
      end
    end

    return false
  end

  require("edgy").setup({
    animate = { enabled = false },
    close_when_all_hidden = true,
    exit_when_last = true,
    wo = { winbar = false },
    keys = {
      q = false,
      Q = false,
      ["<C-q>"] = false,
      ["<A-j>"] = function(win)
        win:resize("height", -2)
      end,
      ["<A-k>"] = function(win)
        win:resize("height", 2)
      end,
      ["<A-h>"] = function(win)
        win:resize("width", -2)
      end,
      ["<A-l>"] = function(win)
        win:resize("width", 2)
      end,
    },
    left = {
      {
        ft = "snacks_picker_list",
        pinned = true,
        collapsed = false,
        size = { height = 0.6, width = 0.2 },
        filter = function(_, win)
          return is_explorer_win(win)
        end,
        open = function()
          Snacks.explorer.open()
        end,
      },
      {
        ft = "trouble",
        pinned = true,
        collapsed = false,
        size = { height = 0.4, width = 0.15 },
        open = function()
          return vim.b.buftype == "" and "Trouble symbols toggle win.position=right"
        end,
        filter = trouble_filter("right"),
      },
    },
    bottom = {
      { ft = "qf", size = { height = 0.3 } },
      {
        ft = "snacks_terminal",
        size = { height = 0.3 },
        filter = function(_, win)
          return vim.w[win].snacks_win and vim.w[win].snacks_win.position == "bottom"
        end,
      },
      {
        ft = "help",
        size = { height = 0.3 },
        filter = function(buf)
          return vim.bo[buf].buftype == "help"
        end,
      },
    },
  })
end
