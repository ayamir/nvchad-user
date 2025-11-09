return {
  auto_open = false,
  auto_close = false,
  auto_jump = false,
  auto_preview = true,
  auto_refresh = true,
  focus = false, -- do not focus the window when opened
  follow = true,
  restore = true,
  modes = {
    project_diagnostics = {
      mode = "diagnostics",
      filter = {
        any = {
          {
            function(item)
              return item.filename:find(vim.uv.cwd(), 1, true)
            end,
          },
        },
      },
    },
  },
}
