local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

function M.enable_on_save(is_configured)
  create_autocmd("BufWritePre", {
    group = create_augroup("FormatOnSave"),
    pattern = "*",
    callback = function(args)
      require("conform").format({ bufnr = args.buf })
    end,
  })

  if not is_configured then
    vim.notify("FormatOnSave is enabled", vim.log.levels.INFO, { title = "FormatOnSave" })
  end
end

function M.disable_on_save(is_configured)
  local ok = pcall(api.nvim_del_augroup_by_name, "FormatOnSave")
  if ok and not is_configured then
    vim.notify("FormatOnSave is disabled", vim.log.levels.INFO, { title = "FormatOnSave" })
  end
end

function M.toggle_on_save()
  local ok, autocmds = pcall(api.nvim_get_autocmds, {
    group = "FormatOnSave",
    event = "BufWritePre",
  })

  if not ok or #autocmds == 0 then
    M.enable_on_save(false)
  else
    M.disable_on_save(false)
  end
end

function M.format_buffer()
  require("conform").format({
    async = false,
    timeout_ms = 500,
    lsp_fallback = true,
  })
end

function M.setup()
  M.enable_on_save(true)
end

return M
