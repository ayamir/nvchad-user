return function()
  require("project").setup({
    manual_mode = false,
    patterns = { "=tcc_monorepo", "go.mod", ".git" },
    silent_chdir = true,
    lsp = { ignroe = { "null-ls", "copilot" }, enabled = false },
    exclude_dirs = {},
    show_hidden = false,
    scope_chdir = "global",
    history = {
      save_dir = vim.fn.stdpath("data"),
    },
    fzf_lua = {
      enabled = true,
    },
  })
end
