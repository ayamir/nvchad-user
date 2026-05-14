local create_autocmd = vim.api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local function attach_dap_repl_completion()
  require("dap.ext.autocompl").attach()
end

local function cleanup_dap_on_exit()
  local ok_dapui, dapui = pcall(require, "dapui")
  if ok_dapui then
    pcall(dapui.close)
  end

  local ok_dap, dap = pcall(require, "dap")
  if ok_dap then
    pcall(dap.close)
    pcall(dap.terminate)
  end
end

function M.setup()
  create_autocmd("FileType", {
    group = create_augroup("DapFiletypeTweaks"),
    pattern = "dap-repl",
    callback = attach_dap_repl_completion,
  })

  create_autocmd("VimLeavePre", {
    group = create_augroup("DapCleanup"),
    callback = cleanup_dap_on_exit,
  })
end

return M
