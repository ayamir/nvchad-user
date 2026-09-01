local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "gofumpt", "goimports", "gofmt" },
    rust = { "rustfmt", lsp_format = "fallback" },
    json = { "prettier" },
    -- ruff_format = ruff format（替代 black）；ruff_organize_imports = import 排序（替代 isort）
    python = { "ruff_format", "ruff_organize_imports", "ruff_fix" },
    sh = { "shfmt" },
    nix = { "nixfmt" },
  },
}

return options
