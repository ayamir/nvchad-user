require("nvchad.configs.lspconfig").defaults()

local servers = { "lua_ls", "gopls" }
vim.lsp.enable(servers)

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
      -- Do not override treesitter lua highlighting with lua_ls's highlighting
      semantic = { enable = false },
    },
  },
})
