local cmp = require("cmp")

local find_or_create_project_bookmark_group = function()
  local project_root = require("project").get_project_root()
  if not project_root then
    return
  end

  local project_name = string.gsub(project_root, "^" .. os.getenv("HOME") .. "/", "")
  local Service = require("bookmarks.domain.service")
  local Repo = require("bookmarks.domain.repo")
  local bookmark_list = nil

  for _, bl in ipairs(Repo.find_lists()) do
    if bl.name == project_name then
      bookmark_list = bl
      break
    end
  end

  if not bookmark_list then
    bookmark_list = Service.create_list(project_name)
  end
  Service.set_active_list(bookmark_list.id)
  require("bookmarks.sign").safe_refresh_signs()
end

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require("configs.conform"),
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("configs.lspconfig")
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    init = function()
      vim.g.trae_disable_autocompletion = true
      vim.g.trae_no_map_tab = true
      vim.g.trae_disable_bindings = true
    end,
    opts = {
      sources = {
        { name = "trae" },
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "nvim_lua" },
        { name = "async_path" },
      },
      matching = {
        disallow_partial_fuzzy_matching = false,
      },
      performance = {
        async_budget = 1,
        max_view_entries = 120,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-w>"] = cmp.mapping.abort(),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif require("luasnip").expand_or_locally_jumpable() then
            require("luasnip").expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          elseif require("luasnip").jumpable(-1) then
            require("luasnip").jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPre",
    opts = {
      ensure_installed = {
        "lua",
        "go",
        "toml",
        "json",
      },
    },
    dependencies = {
      "mfussenegger/nvim-treehopper",
      "nvim-treesitter/nvim-treesitter-context",
      { "andymass/vim-matchup", init = require("configs.matchup") },
      { "hiphish/rainbow-delimiters.nvim", config = require("configs.rainbow_delims") },
    },
  },

  -- tools
  {
    "olimorris/persisted.nvim",
    lazy = false,
    opts = {
      save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
      autostart = true,
      autoload = true,
      follow_cwd = true,
      use_git_branch = true,
      should_save = function()
        return vim.bo.filetype == "Nvdash" and false or true
      end,
    },
  },
  {
    "smoka7/hop.nvim",
    lazy = true,
    version = "*",
    event = { "CursorHold", "CursorHoldI" },
    opts = { keys = "etovxqpdygfblzhckisuran" },
  },

  {
    "ibhagwan/smartyank.nvim",
    event = "BufReadPost",
    config = require("configs.smartyank"),
  },

  {
    "gelguy/wilder.nvim",
    lazy = true,
    event = "CmdlineEnter",
    config = require("configs.wilder"),
    dependencies = "romgrk/fzy-lua-native",
  },

  {
    "mrjones2014/smart-splits.nvim",
    event = { "CursorHoldI", "CursorHold" },
    opts = require("configs.splits"),
  },

  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleRefresh" },
    opts = require("configs.trouble"),
  },

  {
    "ibhagwan/fzf-lua",
    lazy = true,
    cmd = "FzfLua",
    config = require("configs.fzf-lua"),
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  {
    "ayamir/lspsaga.nvim",
    lazy = true,
    event = "LspAttach",
    config = require("configs.lspsaga"),
    dependencies = "nvim-tree/nvim-web-devicons",
  },

  {
    "kevinhwang91/nvim-bqf",
    lazy = true,
    ft = "qf",
    config = require("configs.bqf"),
    dependencies = {
      { "junegunn/fzf", build = ":call fzf#install()" },
    },
  },

  {
    "DrKJeff16/project.nvim",
    event = { "CursorHold", "CursorHoldI" },
    config = require("configs.project"),
  },

  {
    "mrcjkb/rustaceanvim",
    lazy = true,
    ft = "rust",
    version = "*",
    init = require("configs.rust"),
    dependencies = "nvim-lua/plenary.nvim",
  },

  {
    "git@code.byted.org:chenjiaqi.cposture/codeverse.vim.git",
    lazy = true,
    event = "InsertEnter",
    init = function()
      vim.g.trae_disable_autocompletion = true
      vim.g.trae_no_map_tab = true
      vim.g.trae_disable_bindings = true
    end,
    config = function()
      vim.g.trae_disable_autocompletion = true
      vim.g.trae_no_map_tab = true
      vim.g.trae_disable_bindings = true
      require("trae").setup()
    end,
  },

  {
    "ayamir/garbage-day.nvim",
    lazy = true,
    event = "LspAttach",
  },

  {
    "Wansmer/symbol-usage.nvim",
    lazy = true,
    event = "LspAttach",
    config = function()
      require("symbol-usage").setup({})

      vim.api.nvim_create_user_command("E", function()
        require("symbol-usage").refresh()
      end, {})
    end,
  },

  {
    "max397574/better-escape.nvim",
    lazy = true,
    event = { "CursorHold", "CursorHoldI" },
    config = true,
  },

  {
    "chrisgrieser/nvim-spider",
    lazy = true,
    event = { "CursorHold", "CursorHoldI" },
  },

  {
    "kylechui/nvim-surround",
    lazy = true,
    version = "*",
    event = { "CursorHoldI", "CursorHold" },
    config = function()
      require("nvim-surround").setup()
    end,
  },

  {
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    opts = {
      autoFold = { enabled = false },
    }, -- needed even when using default config

    -- recommended: disable vim's auto-folding
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
  },

  {
    "ayamir/bookmarks.nvim",
    lazy = true,
    cmd = { "BookmarksGoto" },
    dependencies = {
      { "kkharji/sqlite.lua" },
      { "stevearc/dressing.nvim" }, -- optional: better UI
    },
    config = function()
      require("bookmarks").setup({})

      vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("BookmarksGroup", {}),
        pattern = { "*" },
        callback = find_or_create_project_bookmark_group,
      })
    end,
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "fredrikaverpil/neotest-golang",
      "leoluz/nvim-dap-go",
      "rouge8/neotest-rust",
    },
    config = require("configs.neotest"),
  },

  {
    "echasnovski/mini.cursorword",
    lazy = true,
    event = { "BufReadPost", "BufAdd", "BufNewFile" },
    opts = {
      delay = 200,
    },
  },

  {
    "romainl/vim-cool",
    lazy = true,
    event = { "CursorMoved", "InsertEnter" },
  },

  {
    "tpope/vim-sleuth",
    lazy = true,
    event = { "BufNewFile", "BufReadPost", "BufFilePost" },
  },

  {
    "MagicDuck/grug-far.nvim",
    lazy = true,
    cmd = "GrugFar",
    opts = {
      engine = "ripgrep",
      engines = {
        ripgrep = {
          path = "rg",
          showReplaceDiff = true,
          placeholders = {
            enabled = true,
          },
        },
      },
      transient = true,
      icons = { enabled = true },
      disableBufferLineNumbers = true,
      windowCreationCommand = "bot split",
      keymaps = {
        replace = { n = ",r" },
        qflist = { n = ",q" },
        syncLocations = { n = ",s" },
        syncLine = { n = ",l" },
        close = { n = ",c" },
        historyOpen = { n = ",t" },
        historyAdd = { n = ",a" },
        refresh = { n = ",f" },
        openLocation = { n = ",o" },
        openNextLocation = { n = "<Down>" },
        openPrevLocation = { n = "<Up>" },
        gotoLocation = { n = "<Enter>" },
        pickHistoryEntry = { n = "<Enter>" },
        abort = { n = ",b" },
        help = { n = "g?" },
        toggleShowCommand = { n = ",w" },
        swapEngine = { n = ",e" },
        previewLocation = { n = ",i" },
        swapReplacementInterpreter = { n = ",x" },
        applyNext = { n = ",j" },
        applyPrev = { n = ",k" },
        syncNext = { n = ",n" },
        syncPrev = { n = ",p" },
        syncFile = { n = ",v" },
        nextInput = { n = "<Tab>" },
        prevInput = { n = "<S-Tab>" },
      },
    },
  },

  {
    "folke/edgy.nvim",
    lazy = true,
    event = { "CursorHold", "CursorHoldI" },
    config = require("configs.edgy"),
    dependencies = {
      {
        "nvim-tree/nvim-tree.lua",
        lazy = true,
        cmd = {
          "NvimTreeToggle",
          "NvimTreeOpen",
          "NvimTreeFindFile",
          "NvimTreeFindFileToggle",
          "NvimTreeRefresh",
        },
      },
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        progress = {
          enabled = false,
        },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
      cmdline = {
        enabled = true,
        view = "cmdline",
      },
    },
    dependencies = {
      { "MunifTanjim/nui.nvim" },
      {
        "rcarriga/nvim-notify",
        opts = {
          fps = 20,
          stages = "slide",
          timeout = 1000,
          render = "default",
          minimum_width = 50,
          background_colour = "NotifyBackground",
          on_open = function(win)
            vim.api.nvim_set_option_value("winblend", 0, { scope = "local", win = win })
            vim.api.nvim_win_set_config(win, { zindex = 90 })
          end,
          level = "INFO",
        },
      },
    },
  },

  {
    "nacro90/numb.nvim",
    config = function()
      require("numb").setup()
    end,
  },

  {
    "lowitea/aw-watcher.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      aw_server = {
        host = "127.0.0.1",
        port = 5600,
      },
    },
  },
}
