local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "gofumpt", "goimports", "gofmt" },
    rust = { "rustfmt", lsp_format = "fallback" },
    json = { "prettier" },
    python = { "ruff", "black", "isort" },
    sh = { "shfmt" },
  },
}

return options
