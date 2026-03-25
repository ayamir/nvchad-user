return function()
  require("fzf-lua").setup({
    { "telescope" },
    fzf_args = "--layout=reverse",
    winopts = {
      height = 0.4,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      preview = {
        layout = "horizontal",
        horizontal = "right:50%",
      },
      on_create = function()
        -- use <C-x> to split
        vim.keymap.set("t", "<C-x>", "<C-x>", {
          buffer = true,
          noremap = true,
          silent = true,
        })
      end,
    },
  })
end
