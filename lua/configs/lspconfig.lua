require("nvchad.configs.lspconfig").defaults()

local servers = { "lua_ls", "gopls", "jsonls" }
vim.lsp.enable(servers)

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = {
        globals = { "vim" },
        disable = { "different-requires", "undefined-field" },
      },
      workspace = {
        library = {
          vim.fn.expand("$VIMRUNTIME/lua"),
          vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
      hint = { enable = true, setType = true },
      format = { enable = false },
      telemetry = { enable = false },
      semantic = { enable = false },
    },
  },
})

-- read :h vim.lsp.config for changing options of lsp servers
vim.lsp.config("gopls", {
  cmd = { "gopls", "-remote.debug=:0", "-remote=auto" },
  filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
  flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
  capabilities = {
    textDocument = {
      completion = {
        contextSupport = true,
        dynamicRegistration = true,
        completionItem = {
          commitCharactersSupport = true,
          deprecatedSupport = true,
          preselectSupport = true,
          insertReplaceSupport = true,
          labelDetailsSupport = true,
          snippetSupport = true,
          documentationFormat = { "markdown", "plaintext" },
          resolveSupport = {
            properties = {
              "documentation",
              "details",
              "additionalTextEdits",
            },
          },
        },
      },
    },
  },
  settings = {
    gopls = {
      staticcheck = true,
      semanticTokens = true,
      usePlaceholders = true,
      completeUnimported = true,
      symbolMatcher = "Fuzzy",
      buildFlags = { "-tags", "integration" },
      semanticTokenTypes = { string = false },
      codelenses = {
        generate = true,
        gc_details = true,
        test = true,
        tidy = true,
        vendor = true,
        regenerate_cgo = true,
        upgrade_dependency = true,
      },
    },
  },
})

vim.lsp.config("jsonls", {
  flags = { debounce_text_changes = 500 },
  settings = {
    json = {
      -- Schemas https://www.schemastore.org
      schemas = {
        {
          fileMatch = { "package.json" },
          url = "https://json.schemastore.org/package.json",
        },
        {
          fileMatch = { "tsconfig*.json" },
          url = "https://json.schemastore.org/tsconfig.json",
        },
        {
          fileMatch = {
            ".prettierrc",
            ".prettierrc.json",
            "prettier.config.json",
          },
          url = "https://json.schemastore.org/prettierrc.json",
        },
        {
          fileMatch = { ".eslintrc", ".eslintrc.json" },
          url = "https://json.schemastore.org/eslintrc.json",
        },
        {
          fileMatch = {
            ".babelrc",
            ".babelrc.json",
            "babel.config.json",
          },
          url = "https://json.schemastore.org/babelrc.json",
        },
        {
          fileMatch = { "lerna.json" },
          url = "https://json.schemastore.org/lerna.json",
        },
        {
          fileMatch = {
            ".stylelintrc",
            ".stylelintrc.json",
            "stylelint.config.json",
          },
          url = "http://json.schemastore.org/stylelintrc.json",
        },
        {
          fileMatch = { "/.github/workflows/*" },
          url = "https://json.schemastore.org/github-workflow.json",
        },
      },
    },
  },
})
