local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local TRANSIENT_SESSION_FILETYPES = {
  "zellij",
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

local function cleanup_persisted_buffers()
  for _, buf in ipairs(api.nvim_list_bufs()) do
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype

    if bt == "terminal" or vim.tbl_contains(TRANSIENT_SESSION_FILETYPES, ft) then
      pcall(api.nvim_buf_delete, buf, { force = true })
    end
  end
end

local function maybe_close_nvim_tree()
  local layout = vim.fn.winlayout()

  if
    layout[1] == "leaf"
    and vim.bo[api.nvim_win_get_buf(layout[2])].filetype == "NvimTree"
    and layout[3] == nil
  then
    vim.cmd("confirm quit")
  end
end

function M.setup()
  create_autocmd("User", {
    group = create_augroup("PersistedCleanup"),
    pattern = "PersistedSavePre",
    callback = cleanup_persisted_buffers,
  })

  create_autocmd("BufEnter", {
    group = create_augroup("NvimTreeAutoClose"),
    pattern = "NvimTree_*",
    callback = maybe_close_nvim_tree,
  })
end

return M
