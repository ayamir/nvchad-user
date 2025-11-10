require("nvchad.autocmds")

local autocmd = {}

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})

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
