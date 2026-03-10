return function()
  require("project").setup({
    manual_mode = false,
    patterns = { "=tcc_monorepo", "go.mod", ".git" },
    silent_chdir = true,
    lsp = { ignroe = { "null-ls", "copilot" }, enabled = false },
    exclude_dirs = {},
    show_hidden = false,
    scope_chdir = "global",
    datapath = vim.fn.stdpath("data"),
  })
end
