return function()
  require("fzf-lua").setup({
    { "telescope" },
    fzf_args = "--layout=reverse",
    -- 使用 fd 加速文件查找，--no-ignore-vcs 跳过 .gitignore 解析可进一步提速
    files = {
      -- fd 比 find 快很多，--strip-cwd-prefix 减少输出处理开销
      cmd = "fd --type f --hidden --follow --exclude .git --strip-cwd-prefix",
      -- 异步批量获取，减少阻塞
      multiprocess = true,
    },
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
