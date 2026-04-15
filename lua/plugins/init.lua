local helpers = require("utils.helpers")

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

  { import = "nvchad.blink.lazyspec" },

  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "saghen/blink.compat",
        version = "v2.*",
        opts = {},
      },
      {
        "git@code.byted.org:chenjiaqi.cposture/codeverse.vim.git",
        cond = not (helpers.is_nixos() or helpers.is_archlinux()),
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
    },
    opts = function(_, opts)
      opts = opts or {}

      opts.completion = opts.completion or {}
      opts.completion.ghost_text = { enabled = false }
      opts.completion.list = { max_items = 120 }
      local menu = vim.deepcopy(require("nvchad.blink").menu)
      menu.draw = menu.draw or {}
      menu.draw.components = menu.draw.components or {}
      menu.draw.components.kind = menu.draw.components.kind or {}
      menu.draw.components.kind.text = function(ctx)
        if ctx.source_id == "trae" then
          return "Trae"
        end
        return ctx.kind
      end
      opts.completion.menu = menu

      -- Sources
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or { "lsp", "buffer", "snippets", "path" }
      if not vim.tbl_contains(opts.sources.default, "trae") then
        table.insert(opts.sources.default, 1, "trae")
      end

      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.trae = {
        name = "Trae",
        module = "blink.compat.source",
        opts = { cmp_name = "trae" },
      }

      return opts
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      {
        "nvim-telescope/telescope-frecency.nvim",
        dependencies = { "kkharji/sqlite.lua" },
      },
    },
    opts = function()
      return {
        defaults = require("telescope.themes").get_ivy({
          sorting_strategy = "ascending",
        }),
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
      telescope.load_extension("frecency")
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.del("n", "<C-e>", { buffer = bufnr })
      end,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = function()
      if #vim.api.nvim_list_uis() > 0 then
        vim.api.nvim_command([[TSUpdate]])
      end
    end,
    config = function()
      vim.api.nvim_set_option_value("indentexpr", "v:lua.require'nvim-treesitter'.indentexpr()", {})
      require("nvim-treesitter").install(require("settings")["treesitter_deps"])
    end,
    dependencies = {
      "mfussenegger/nvim-treehopper",
      "nvim-treesitter/nvim-treesitter-context",
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      auto_attach = true,
      signcolumn = true,
      sign_priority = 6,
      update_debounce = 100,
      word_diff = false,
      current_line_blame = true,
      diff_opts = { internal = true },
      watch_gitdir = { follow_files = false },
      current_line_blame_opts = { delay = 3000, virt_text = true, virtual_text_pos = "eol" },
    },
  },

  {
    "karb94/neoscroll.nvim",
    lazy = true,
    event = { "BufReadPost" },
    opts = {
      hide_cursor = true,
      stop_eof = true,
      use_local_scrolloff = false,
      respect_scrolloff = false,
      cursor_scrolls_alone = true,
      mappings = {
        "<C-u>",
        "<C-d>",
        "<C-b>",
        "<C-f>",
        "<C-y>",
        "<C-e>",
        "zt",
        "zz",
        "zb",
      },
      easing_function = "quadratic",
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
    "ayamir/garbage-day.nvim",
    enabled = false,
    -- enabled = vim.fn.has("unix") == 0 or vim.fn.has("mac") == 1,
    lazy = true,
    event = "LspAttach",
    config = function()
      require("garbage-day").setup({
        excluded_lsp_clients = { "null-ls" },
        notifications = true,
        grace_period = 10 * 60,
      })
    end,
  },

  {
    "Wansmer/symbol-usage.nvim",
    lazy = true,
    event = "LspAttach",
    config = require("configs.symbol-usage"),
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
    cmd = {
      "BookmarksGoto",
      "BookmarksMark",
      "BookmarksQuickMark",
      "BookmarksGotoNext",
      "BookmarksGotoPrev",
    },
    dependencies = {
      { "kkharji/sqlite.lua" },
      { "stevearc/dressing.nvim" }, -- optional: better UI
    },
    config = function()
      require("bookmarks").setup({})
      pcall(dofile, vim.g.base46_cache .. "bookmarks")
      vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("BookmarksGroup", {}),
        pattern = { "*" },
        callback = helpers.find_or_create_project_bookmark_group,
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
    "mfussenegger/nvim-dap",
    lazy = true,
    cmd = {
      "DapSetLogLevel",
      "DapShowLog",
      "DapContinue",
      "DapToggleBreakpoint",
      "DapToggleRepl",
      "DapStepOver",
      "DapStepInto",
      "DapStepOut",
      "DapTerminate",
    },
    config = require("configs.dap"),
    dependencies = {
      "jay-babu/mason-nvim-dap.nvim",
      {
        "rcarriga/nvim-dap-ui",
        dependencies = "nvim-neotest/nvim-nio",
      },
    },
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
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        fps = 120,
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
      })
      vim.notify = notify
    end,
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

  {
    "akinsho/toggleterm.nvim",
    lazy = true,
    version = "*",
    cmd = {
      "ToggleTerm",
      "ToggleTermSetName",
      "ToggleTermToggleAll",
      "ToggleTermSendVisualLines",
      "ToggleTermSendCurrentLine",
      "ToggleTermSendVisualSelection",
    },
    config = require("configs.toggleterm"),
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = require("configs.tiny-inline-diagnostic"),
  },

  {
    "jake-stewart/normal-cmdline.nvim",
    event = "CmdlineEnter",
    config = function()
      -- make the cmdline insert mode a beam
      vim.opt.guicursor:append("ci:ver1,c:ver1")

      local cmd = require("normal-cmdline")
      cmd.setup({
        -- key to hit within cmdline to enter normal mode:
        key = "<esc>",
        -- the cmdline text highlight when in normal mode:
        hl = "Normal",
        -- these mappings only apply to normal mode in cmdline:
        mappings = {
          ["k"] = cmd.history.prev,
          ["j"] = cmd.history.next,
          ["<cr>"] = cmd.accept,
          ["<esc>"] = cmd.cancel,
          ["<c-c>"] = cmd.cancel,
          [":"] = cmd.reset,
        },
      })
    end,
  },

  {
    "aaronhallaert/advanced-git-search.nvim",
    cmd = { "AdvancedGitSearch" },
    config = function()
      require("telescope").setup({
        extensions = {
          advanced_git_search = {
            diff_plugin = "diff_view",
            show_builtin_git_pickers = false,
            entry_default_author_or_date = "both",
            keymaps = {
              toggle_date_author = "<C-w>",
              open_commit_in_browser = "<C-o>",
              copy_commit_hash = "<C-y>",
              copy_commit_patch = "<C-p>",
              show_entire_commit = "<C-e>",
            },
          },
        },
      })
      require("telescope").load_extension("advanced_git_search")
    end,
    dependencies = {
      {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose" },
        config = require("configs.diffview"),
      },
    },
  },

  {
    "nguyenvukhang/nvim-toggler",
    config = function()
      require("nvim-toggler").setup({
        -- your own inverses
        inverses = {
          ["vim"] = "emacs",
        },
        -- removes the default <leader>i keymap
        remove_default_keybinds = false,
        -- removes the default set of inverses
        remove_default_inverses = false,
        -- auto-selects the longest match when there are multiple matches
        autoselect_longest_match = true,
      })
    end,
  },

  {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = {
      nes = { enabled = false },
      cli = {
        tools = {
          coco = {
            cmd = { "claude" },
            title = "Coco AI",
          },
          claude = {
            cmd = { "claude" },
            title = "Claude Code",
          },
        },
      },
    },
  },

  {
    "ray-x/go.nvim",
    lazy = true,
    ft = { "go", "gomod", "gosum" },
    build = ":GoInstallBinaries",
    opts = {
      icons = false,
      diagnostic = false,
      lsp_cfg = false,
      lsp_gofumpt = false,
      lsp_keymaps = false,
      lsp_codelens = false,
      lsp_document_formatting = false,
      lsp_inlay_hints = { enable = false },
      -- DAP-related settings are also turned off here for the same reason
      dap_debug = false,
      dap_debug_keymap = false,
      textobjects = false,
      -- Miscellaneous options to seamlessly integrate with other plugins
      trouble = true,
      luasnip = false,
      run_in_floaterm = false,
    },
    dependencies = "ray-x/guihua.lua",
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
        progress = { enabled = false },
        signature = { enabled = false },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },

  {
    "andymass/vim-matchup",
    init = function()
      vim.g.matchup_transmute_enabled = 1
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
}
