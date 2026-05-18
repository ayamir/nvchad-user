local create_autocmd = vim.api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local CLOSE_WITH_Q_FILETYPES = {
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
}

local NO_UNDO_PATTERNS = {
  "*~",
  "/tmp/*",
  "*.tmp",
  "*.bak",
  "MERGE_MSG",
  "description",
  "COMMIT_EDITMSG",
}


local function startinsert_in_terminal(event)
  vim.schedule(function()
    if vim.api.nvim_get_current_buf() ~= event.buf then
      return
    end

    if vim.bo[event.buf].buftype ~= "terminal" then
      return
    end

    if vim.fn.mode():sub(1, 1) ~= "t" then
      vim.cmd("startinsert!")
    end
  end)
end

local function close_buffer_with_q(event)
  vim.bo[event.buf].buflisted = false
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = event.buf, silent = true })
end

function M.setup()
  local filetype_tweaks_group = create_augroup("FiletypeTweaks")

  create_autocmd("FileType", {
    group = create_augroup("CloseWithQ"),
    pattern = CLOSE_WITH_Q_FILETYPES,
    callback = close_buffer_with_q,
  })

  create_autocmd({ "BufEnter", "WinEnter", "TermOpen" }, {
    group = create_augroup("TerminalAutoInsert"),
    callback = startinsert_in_terminal,
  })

  create_autocmd("BufWritePre", {
    group = create_augroup("NoUndoForTempBuffers"),
    pattern = NO_UNDO_PATTERNS,
    command = "setlocal noundofile",
  })

  create_autocmd("FileType", {
    group = filetype_tweaks_group,
    pattern = "*",
    command = "setlocal formatoptions-=cro",
  })

  create_autocmd("FileType", {
    group = filetype_tweaks_group,
    pattern = "markdown",
    command = "setlocal wrap",
  })
end

return M
