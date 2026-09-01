require("nvchad.configs.lspconfig").defaults()

local map = vim.keymap.set
local capabilities = vim.lsp.protocol.make_client_capabilities()

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
    Snacks.picker.lsp_symbols()
  end, opts())
  map("n", "g[", ":Lspsaga diagnostic_jump_prev<CR>", opts())
  map("n", "g]", ":Lspsaga diagnostic_jump_next<CR>", opts())
  map("n", "gr", ":Lspsaga rename<CR>", opts())
  map("n", "gR", ":Lspsaga rename ++project<CR>", opts())
  map("n", "gd", ":Lspsaga peek_definition<CR>", opts())
  map("n", "gD", ":Lspsaga goto_definition<CR>", opts())
  map("n", "gt", ":Trouble diagnostics toggle<CR>", opts())
  map("n", "gh", function()
    Snacks.picker.lsp_references({
      filter = {
        filter = function(item)
          return not (item.file or ""):match("_test%.go$")
        end,
      },
    })
  end, opts())
  map("n", "gm", function()
    Snacks.picker.lsp_implementations({
      filter = {
        filter = function(item)
          return not (item.file or ""):lower():find("mock", 1, true)
        end,
      },
    })
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

local function enable_mason_installed_servers()
  local ok_mlsp, mlsp = pcall(require, "mason-lspconfig")
  if not ok_mlsp then
    return
  end

  local function is_mason_lsp_server_eligible(name)
    -- rust-analyzer 交给 rustaceanvim；ruff/ruff_lsp 只当 formatter 用，不作为 LSP（否则会扫描 workspace 报错）
    local excluded = { rust_analyzer = true, ruff = true, ruff_lsp = true }
    return not excluded[name]
  end

  -- 仅用于“根据已安装的 Mason server 自动启用 LSP”，不强制安装。
  -- setup 里显式排除 ruff，避免 its automatic_enable 把 ruff 当 LSP 拉起。
  mlsp.setup({
    automatic_enable = {
      -- exclude 表外的服务器才会被 automatic_enable 启用
      exclude = { "rust_analyzer", "ruff", "ruff_lsp" },
    },
  })

  local installed = mlsp.get_installed_servers()
  if type(installed) ~= "table" or vim.tbl_isempty(installed) then
    return
  end

  local to_enable = {}
  for _, name in ipairs(installed) do
    if is_mason_lsp_server_eligible(name) then
      table.insert(to_enable, name)
    end
  end

  if #to_enable > 0 then
    vim.lsp.enable(to_enable)
  end
end

vim.lsp.config("gopls", {
  cmd = { "gopls", "-remote.debug=:0", "-remote=auto" },
  filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
  flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
  settings = {
    gopls = {
      -- 以“索引/跳转/查找”为主：尽量减少会导致大范围刷新/计算的功能
      -- 需要诊断/代码体检时再按需开启（例如 staticcheck / analyses / codelens）
      analyses = {
        efaceany = false, -- 保留你之前的定向禁用
        unusedparams = false,
      },
      staticcheck = false,
      usePlaceholders = false,
      completeUnimported = true,
      symbolMatcher = "Fuzzy",
      buildFlags = { "-tags", "integration" },

      -- 仅索引时建议关闭 codelens（会触发额外 request，恢复窗口后更容易卡）
      codelenses = {
        generate = false,
        gc_details = false,
        test = false,
        tidy = false,
        vendor = false,
        regenerate_cgo = false,
        upgrade_dependency = false,
      },

      -- 大仓库里减少无关目录的扫描，通常能明显提升索引体验
      directoryFilters = {
        "-.git",
        "-node_modules",
        "-vendor",
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

-- Python 项目判定用到的 marker：缺失时按“单文件”处理（root 取文件所在目录）
local python_markers = {
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "tox.ini",
}

local python_project_root = function(bufnr)
  local dir = vim.fs.root(bufnr, python_markers)
  if dir then
    return dir
  end
  -- 无项目 marker：退回单文件模式，root 取文件所在目录，绝不冒泡到 $HOME
  return vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
end

-- Python 语言服务器：zuban（字节内部 Rust 类型检查 + LSP）
-- 安装：MasonInstall zuban --confirm；命令为 `zuban server`
vim.lsp.config("zuban", {
  cmd = { "zuban", "server" },
  filetypes = { "python" },
  root_markers = python_markers,
  -- 有项目 marker 用项目根，否则单文件模式取文件所在目录，避免冒泡到 $HOME
  root_dir = python_project_root,
})

-- 显式 FileType autocmd 启动（双保险）：确保 zuban 一定在 python 文件拉起。
-- （若 zuban 也已通过 enable_mason_installed_servers 自动启用，vim.lsp.start 会复用
-- 已有 client，不会重复启动。）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(args)
    local cfg = vim.lsp.config["zuban"]
    if cfg then
      vim.lsp.start(cfg, { bufnr = args.buf })
    end
  end,
  group = vim.api.nvim_create_augroup("PythonLspStart", { clear = true }),
})

vim.lsp.config("nixd", {
  filetypes = { "nix" },
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake "path:/etc/nixos").inputs.nixpkgs { system = "x86_64-linux"; }',
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "path:/etc/nixos").nixosConfigurations.nixos.options',
        },
        home_manager = {
          expr = '(builtins.getFlake "path:/etc/nixos").homeConfigurations.ayamir.options',
        },
      },
    },
  },
})

enable_mason_installed_servers()
