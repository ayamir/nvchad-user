return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPre",
    build = function()
      if #vim.api.nvim_list_uis() > 0 then
        vim.api.nvim_command [[TSUpdate]]
      end
    end,
    config = function()
      require("nvim-treesitter").setup {
        ensure_installed = {
          "lua",
          "go",
          "toml",
          "json",
        },
      }
    end,
    dependencies = {
      "mfussenegger/nvim-treehopper",
      "nvim-treesitter/nvim-treesitter-context",
      { "andymass/vim-matchup", init = require "configs.matchup" },
      { "hiphish/rainbow-delimiters.nvim", config = require "configs.rainbow_delims" },
    },
  },

  -- tools
  {
    "olimorris/persisted.nvim",
    lazy = false,
    opts = {
      save_dir = vim.fn.expand(vim.fn.stdpath "data" .. "/sessions/"),
      autostart = true,
      autoload = true,
      follow_cwd = true,
      use_git_branch = true,
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
    config = require "configs.smartyank",
  },

  {
    "gelguy/wilder.nvim",
    lazy = true,
    event = "CmdlineEnter",
    config = require "configs.wilder",
    dependencies = "romgrk/fzy-lua-native",
  },

  {
    "mrjones2014/smart-splits.nvim",
    event = { "CursorHoldI", "CursorHold" },
    opts = require "configs.splits",
  },

  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleRefresh" },
    opts = require "configs.trouble",
  },

  {
    "ibhagwan/fzf-lua",
    lazy = true,
    cmd = "FzfLua",
    config = require "configs.fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  {
    "ayamir/lspsaga.nvim",
    lazy = true,
    event = "LspAttach",
    config = require "configs.lspsaga",
    dependencies = "nvim-tree/nvim-web-devicons",
  },

  {
    "kevinhwang91/nvim-bqf",
    lazy = true,
    ft = "qf",
    config = require "configs.bqf",
    dependencies = {
      { "junegunn/fzf", build = ":call fzf#install()" },
    },
  },
}
