return function()
  require("fzf-lua").setup({
    { "telescope" },
    winopts = {
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
