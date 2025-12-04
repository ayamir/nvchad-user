require("nvchad.configs.lspconfig").defaults()

local map = vim.keymap.set
local capabilities = vim.lsp.protocol.make_client_capabilities()
local prompt_position = require("telescope.config").values.layout_config.horizontal.prompt_position
local fzf_opts = { ["--layout"] = prompt_position == "top" and "reverse" or "default" }

capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}
local on_init = function(client, _)
  if vim.fn.has("nvim-0.11") ~= 1 then
    if client.supports_method("textDocument/semanticTokens") then
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    if client:supports_method("textDocument/semanticTokens") then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
end

local on_attach = function(_, bufnr)
  local function opts()
    return { noremap = true, silent = true, buffer = bufnr }
  end

  map("n", "ga", ":Lspsaga code_action<CR>", opts())
  map("n", "go", ":Trouble symbols toggle win.position=right<CR>", opts())
  map("n", "gp", function()
    require("fzf-lua").lsp_document_symbols({ fzf_opts = fzf_opts })
  end)
  map("n", "g[", ":Lspsaga diagnostic_jump_prev<CR>", opts())
  map("n", "g]", ":Lspsaga diagnostic_jump_next<CR>", opts())
  map("n", "gr", ":Lspsaga rename<CR>", opts())
  map("n", "gR", ":Lspsaga rename ++project<CR>", opts())
  map("n", "gd", ":Lspsaga peek_definition<CR>", opts())
  map("n", "gD", ":Lspsaga goto_definition<CR>", opts())
  map("n", "gt", ":Trouble diagnostics toggle<CR>", opts())
  map("n", "gh", function()
    require("fzf-lua").lsp_references({ fzf_opts = fzf_opts })
  end, opts())
  map("n", "gm", function()
    require("fzf-lua").lsp_implementations({ fzf_opts = fzf_opts })
  end, opts())
  map("n", "gy", function()
    require("symbol-usage").refresh()
  end, opts())
end

dofile(vim.g.base46_cache .. "lsp")
require("nvchad.lsp").diagnostic_config()
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    on_attach(_, args.buf)
  end,
})

vim.lsp.config("*", { capabilities = capabilities, on_init = on_init })

local servers = { "gopls", "jsonls", "zuban" }
vim.lsp.enable(servers)
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
      analyses = {
        efaceany = false, -- 在此处禁用 efaceany
        unusedparams = true,
      },
      staticcheck = false,
      semanticTokens = true,
      usePlaceholders = false,
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

vim.lsp.config("zuban", {
  cmd = { "zuban", "server" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
})
