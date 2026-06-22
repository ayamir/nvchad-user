local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local TRANSIENT_SESSION_FILETYPES = {
  "zellij",
  "codecompanion",
  "snacks_picker",
  "snacks_picker_list",
  "snacks_picker_input",
  "snacks_picker_preview",
  "Trouble",
  "qf",
  "netrw",
  "neotest-summary",
  "neotest-output-panel",
  "NvTerm_sp",
  "NvTerm_vsp",
}

local function close_snacks_explorer()
  if not package.loaded.snacks then
    return
  end

  for _, picker in ipairs(Snacks.picker.get({ source = "explorer", tab = false })) do
    picker:close()
  end

  vim.wait(100, function()
    if #Snacks.picker.get({ source = "explorer", tab = false }) > 0 then
      return false
    end

    for _, win in ipairs(api.nvim_list_wins()) do
      local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
      if ft == "snacks_layout_box" or ft:match("^snacks_picker") then
        return false
      end
    end

    return true
  end, 5)

  pcall(require("edgy").close, "left")
end

local function cleanup_persisted_buffers()
  close_snacks_explorer()

  for _, buf in ipairs(api.nvim_list_bufs()) do
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype

    if bt == "terminal" or vim.tbl_contains(TRANSIENT_SESSION_FILETYPES, ft) then
      pcall(api.nvim_buf_delete, buf, { force = true })
    end
  end
end

function M.setup()
  create_autocmd("User", {
    group = create_augroup("PersistedCleanup"),
    pattern = "PersistedSavePre",
    callback = cleanup_persisted_buffers,
  })
end

return M
