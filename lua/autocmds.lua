require("nvchad.autocmds")

local autocmd = {}

-- 1. 取到已装 parser 的 language 列表
local deps = require("settings").treesitter_deps or {}

-- 2. language -> filetype 反向索引
local ft_ok = {} -- key: filetype, value: true
for _, lang in ipairs(deps) do
  -- 一个 language 可能对应多个 filetype
  for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
    ft_ok[ft] = true
  end
end

-- 3. 只给这些 filetype 启动高亮
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TSHighlight", { clear = true }),
  callback = function(args)
    if ft_ok[vim.bo[args.buf].filetype] then
      vim.treesitter.start(args.buf) -- 自动识别 language
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistedSavePre",
  callback = function()
    local fts = {
      "codecompanion",
      "NvimTree",
      "Trouble",
      "qf",
      "netrw",
      "neotest-summary",
      "neotest-output-panel",
      "NvTerm_sp",
      "NvTerm_vsp",
    }
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local ft = vim.bo[buf].filetype
      for _, ft_ in pairs(fts) do
        if ft == ft_ then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
  end,
})

-- format on save: 可动态开关
local function enable_format_on_save(is_configured)
  local group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = "*",
    callback = function(args)
      require("conform").format({ bufnr = args.buf })
    end,
  })
  if not is_configured then
    vim.notify("FormatOnSave is enabled", vim.log.levels.INFO, { title = "FormatOnSave" })
  end
end

local function disable_format_on_save(is_configured)
  local ok = pcall(vim.api.nvim_del_augroup_by_name, "FormatOnSave")
  if ok and not is_configured then
    vim.notify("FormatOnSave is disabled", vim.log.levels.INFO, { title = "FormatOnSave" })
  end
end

local function toggle_format_on_save()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = "FormatOnSave",
    event = "BufWritePre",
  })
  if not ok or #autocmds == 0 then
    enable_format_on_save(false)
  else
    disable_format_on_save(false)
  end
end

-- 启动时默认启用一次（保持原来的行为）
enable_format_on_save(true)

-- 用户命令：手动格式化 + 动态开关
vim.api.nvim_create_user_command("Format", function()
  require("conform").format({
    async = false,
    timeout_ms = 500,
    lsp_fallback = true,
  })
end, {})

vim.api.nvim_create_user_command("FormatToggle", function()
  toggle_format_on_save()
end, {})

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NvimTreeAutoClose", { clear = true }),
  pattern = "NvimTree_*",
  callback = function()
    local layout = vim.api.nvim_call_function("winlayout", {})
    if
      layout[1] == "leaf"
      and vim.bo[vim.api.nvim_win_get_buf(layout[2])].filetype == "NvimTree"
      and layout[3] == nil
    then
      vim.api.nvim_command([[confirm quit]])
    end
  end,
})

-- Autoclose some filetype with <q>
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "qf",
    "help",
    "man",
    "notify",
    "nofile",
    "terminal",
    "prompt",
    "toggleterm",
    "copilot",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.api.nvim_buf_set_keymap(event.buf, "n", "q", "<Cmd>close<CR>", { silent = true })
  end,
})

-- Autojump to last edit
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

function autocmd.nvim_create_augroups(definitions)
  for group_name, definition in pairs(definitions) do
    -- Prepend an underscore to avoid name clashes
    vim.api.nvim_command("augroup _" .. group_name)
    vim.api.nvim_command("autocmd!")
    for _, def in ipairs(definition) do
      local command = table.concat(vim.iter({ "autocmd", def }):flatten(math.huge):totable(), " ")
      vim.api.nvim_command(command)
    end
    vim.api.nvim_command("augroup END")
  end
end

function autocmd.load_autocmds()
  local definitions = {
    bufs = {
      { "BufWritePre", "*~", "setlocal noundofile" },
      { "BufWritePre", "/tmp/*", "setlocal noundofile" },
      { "BufWritePre", "*.tmp", "setlocal noundofile" },
      { "BufWritePre", "*.bak", "setlocal noundofile" },
      { "BufWritePre", "MERGE_MSG", "setlocal noundofile" },
      { "BufWritePre", "description", "setlocal noundofile" },
      { "BufWritePre", "COMMIT_EDITMSG", "setlocal noundofile" },
      -- Auto change directory
      -- { "BufEnter", "*", "silent! lcd %:p:h" },
      -- Auto toggle fcitx5
      -- {"InsertLeave", "* :silent", "!fcitx5-remote -c"},
      -- {"BufCreate", "*", ":silent !fcitx5-remote -c"},
      -- {"BufEnter", "*", ":silent !fcitx5-remote -c "},
      -- {"BufLeave", "*", ":silent !fcitx5-remote -c "}
    },
    ft = {
      { "FileType", "*", "setlocal formatoptions-=cro" },
      { "FileType", "markdown", "setlocal wrap" },
      { "FileType", "dap-repl", "lua require('dap.ext.autocompl').attach()" },
    },
    yank = {
      {
        "TextYankPost",
        "*",
        [[silent! lua vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 300 })]],
      },
    },
  }

  autocmd.nvim_create_augroups(definitions)
end

autocmd.load_autocmds()
