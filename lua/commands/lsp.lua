local api = vim.api

local M = {}

local function get_active_client_names()
  local seen = {}
  local names = {}

  for _, client in ipairs(vim.lsp.get_clients()) do
    if not seen[client.name] then
      seen[client.name] = true
      table.insert(names, client.name)
    end
  end

  table.sort(names)

  return names
end

function M.setup()
  api.nvim_create_user_command("LspRestart", function(opts)
    local names = vim.split(opts.args, "%s+", { trimempty = true })

    if vim.tbl_isempty(names) then
      names = get_active_client_names()
    end

    if vim.tbl_isempty(names) then
      vim.notify("No active LSP clients to restart", vim.log.levels.WARN)
      return
    end

    vim.cmd({ cmd = "lsp", args = vim.list_extend({ "restart" }, names) })
  end, {
    desc = "Restart active LSP clients in current session",
    nargs = "*",
    complete = function(arg_lead)
      return vim.tbl_filter(function(name)
        return vim.startswith(name, arg_lead)
      end, get_active_client_names())
    end,
  })
end

return M
