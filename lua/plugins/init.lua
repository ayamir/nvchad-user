local helpers = require("utils.helpers")

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = require("configs.snacks"),
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      return {
        defaults = require("telescope.themes").get_ivy({
          sorting_strategy = "ascending",
        }),
      }
    end,
    config = function(_, opts)
      require("telescope").setup(opts)
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    cmd = {
      "NvimTreeToggle",
      "NvimTreeOpen",
      "NvimTreeFindFile",
      "NvimTreeFindFileToggle",
      "NvimTreeRefresh",
    },
    opts = {
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        local preview_win
        local preview_buf
        local preview_autocmd
        local preview_augroup = vim.api.nvim_create_augroup("NvimTreeFloatPreview", { clear = false })

        local function close_preview()
          if preview_autocmd then
            pcall(vim.api.nvim_del_autocmd, preview_autocmd)
            preview_autocmd = nil
          end

          if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            vim.api.nvim_win_close(preview_win, true)
          end

          preview_win = nil
          preview_buf = nil
        end

        local function update_preview()
          if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
            close_preview()
            return
          end

          local node = api.tree.get_node_under_cursor()
          if not node or node.type ~= "file" then
            return
          end

          vim.api.nvim_win_set_config(preview_win, {
            title = " " .. vim.fn.fnamemodify(node.absolute_path, ":~:.") .. " ",
            title_pos = "center",
          })

          local previous_buf = preview_buf
          preview_buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_win_set_buf(preview_win, preview_buf)
          vim.bo[preview_buf].bufhidden = "wipe"
          vim.bo[preview_buf].swapfile = false
          vim.bo[preview_buf].modifiable = true
          vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { "Loading preview..." })

          if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
            vim.api.nvim_buf_delete(previous_buf, { force = true })
          end

          require("telescope.config").values.buffer_previewer_maker(node.absolute_path, preview_buf, {
            winid = preview_win,
            preview = {
              timeout = 250,
              filesize_limit = 10,
              highlight_limit = 1,
            },
            callback = function(buf)
              if vim.api.nvim_buf_is_valid(buf) then
                vim.bo[buf].modifiable = false
                vim.bo[buf].readonly = true
              end
            end,
          })
          vim.api.nvim_win_set_cursor(preview_win, { 1, 0 })
        end

        local function preview_float()
          if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            close_preview()
            return
          end

          local width = math.floor(vim.o.columns * 0.72)
          local height = math.floor(vim.o.lines * 0.72)
          preview_win = vim.api.nvim_open_win(0, false, {
            relative = "editor",
            width = width,
            height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = "minimal",
            border = "rounded",
          })

          vim.wo[preview_win].number = false
          vim.wo[preview_win].relativenumber = false
          vim.wo[preview_win].signcolumn = "no"
          vim.wo[preview_win].wrap = true
          vim.wo[preview_win].linebreak = true

          update_preview()
          preview_autocmd = vim.api.nvim_create_autocmd("CursorMoved", {
            group = preview_augroup,
            buffer = bufnr,
            callback = update_preview,
          })
        end

        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.del("n", "<C-e>", { buffer = bufnr })
        vim.keymap.set("n", "gp", preview_float, opts("Toggle Float Preview"))
        vim.keymap.set("n", "gP", close_preview, opts("Close Float Preview"))
        vim.keymap.set("n", "<Esc>", close_preview, opts("Close Float Preview"))
      end,
    },
  },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require("configs.conform"),
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
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
    },
    opts = function(_, opts)
      opts = opts or {}

      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = {
        "select_next",
        "snippet_forward",
        function()
          return vim.lsp.inline_completion and vim.lsp.inline_completion.get and vim.lsp.inline_completion.get()
        end,
        "fallback",
      }

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
      opts.sources.providers = opts.sources.providers or {}

      return opts
    end,
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

  -- {
  --   "karb94/neoscroll.nvim",
  --   lazy = true,
  --   event = { "BufReadPost" },
  --   opts = {
  --     hide_cursor = true,
  --     stop_eof = true,
  --     use_local_scrolloff = false,
  --     respect_scrolloff = false,
  --     cursor_scrolls_alone = true,
  --     mappings = {
  --       "<C-u>",
  --       "<C-d>",
  --       "<C-b>",
  --       "<C-f>",
  --       "<C-y>",
  --       "<C-e>",
  --       "zt",
  --       "zz",
  --       "zb",
  --     },
  --     easing_function = "quadratic",
  --   },
  -- },

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
        return vim.bo.filetype ~= "snacks_dashboard"
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
  },

  {
    "nacro90/numb.nvim",
    config = function()
      require("numb").setup()
    end,
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

  -- {
  --   "jake-stewart/normal-cmdline.nvim",
  --   event = "CmdlineEnter",
  --   config = function()
  --     -- make the cmdline insert mode a beam
  --     vim.opt.guicursor:append("ci:ver1,c:ver1")
  --
  --     local cmd = require("normal-cmdline")
  --     cmd.setup({
  --       -- key to hit within cmdline to enter normal mode:
  --       key = "<esc>",
  --       -- the cmdline text highlight when in normal mode:
  --       hl = "Normal",
  --       -- these mappings only apply to normal mode in cmdline:
  --       mappings = {
  --         ["k"] = cmd.history.prev,
  --         ["j"] = cmd.history.next,
  --         ["<cr>"] = cmd.accept,
  --         ["<esc>"] = cmd.cancel,
  --         ["<c-c>"] = cmd.cancel,
  --         [":"] = cmd.reset,
  --       },
  --     })
  --   end,
  -- },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    config = require("configs.diffview"),
  },

  {
    "aaronhallaert/advanced-git-search.nvim",
    cmd = { "AdvancedGitSearch" },
    config = function()
      require("advanced_git_search.snacks").setup({
        diff_plugin = "diffview",
        show_builtin_git_pickers = false,
        entry_default_author_or_date = "both",
        keymaps = {
          toggle_date_author = "<C-w>",
          open_commit_in_browser = "<C-o>",
          copy_commit_hash = "<C-y>",
          copy_commit_patch = "<C-p>",
          show_entire_commit = "<C-e>",
        },
      })
    end,
    dependencies = {
      "folke/snacks.nvim",
      "sindrets/diffview.nvim",
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

  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     lsp = {
  --       -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
  --       override = {
  --         ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
  --         ["vim.lsp.util.stylize_markdown"] = true,
  --         ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
  --       },
  --       progress = { enabled = false },
  --       signature = { enabled = false },
  --     },
  --     -- you can enable a preset for easier configuration
  --     presets = {
  --       bottom_search = false, -- use a classic bottom cmdline for search
  --       command_palette = false, -- position the cmdline and popupmenu together
  --       long_message_to_split = true, -- long messages will be sent to a split
  --       inc_rename = true, -- enables an input dialog for inc-rename.nvim
  --       lsp_doc_border = true, -- add a border to hover docs and signature help
  --     },
  --   },
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --   },
  -- },

  {
    "andymass/vim-matchup",
    init = function()
      vim.g.matchup_transmute_enabled = 1
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },

  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    version = "0.5.2",
    opts = {},
    config = function(_, opts)
      require("configs.fff").setup(opts)
    end,
    keys = {
      {
        "ff",
        function()
          require("fff").find_files()
        end,
        desc = "FFFind files",
      },
      {
        "fw",
        function()
          require("fff").live_grep()
        end,
        desc = "LiFFFe grep",
      },
      {
        "fp",
        function()
          require("fff").live_grep({
            grep = {
              modes = { "fuzzy", "plain" },
            },
          })
        end,
        desc = "Live fffuzy grep",
      },
      {
        "fs",
        function()
          require("fff").live_grep({ query = vim.fn.expand("<cword>") })
        end,
        desc = "Search current word",
      },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    ft = { "markdown", "codecompanion" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      enabled = true,
      max_file_size = 2.0,
      debounce = 100,
      render_modes = { "n", "c", "t" },
      anti_conceal = { enabled = true },
      log_level = "error",
    },
  },
}
