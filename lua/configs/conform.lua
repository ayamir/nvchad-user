local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "gofumpt", "goimports", "gofmt" },
    rust = { "rustfmt", lsp_format = "fallback" },
    json = { "prettier" },
    python = { "ruff", "black", "isort" },
    sh = { "shfmt" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
