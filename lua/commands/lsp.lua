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
  -- Neovim 0.11+ 移除了内置 :LspInfo（且 0.12 的 `checkhealth vim.lsp` 有 Funcref bug）。
  -- 这里直接输出活跃 LSP client 信息，效果等价于旧版 :LspInfo。
  api.nvim_create_user_command("LspInfo", function()
    local lines = { "Active LSP clients:" }
    local clients = vim.lsp.get_clients()
    if vim.tbl_isempty(clients) then
      lines[#lines + 1] = "  (none)"
    else
      for _, client in ipairs(clients) do
        local root = client.config.root_dir
        if type(root) == "function" then
          local okr, r = pcall(root, vim.api.nvim_get_current_buf())
          root = okr and r or nil
        end
        local line = string.format("  %s (id=%d)", client.name, client.id)
        if root then
          line = line .. "  root=" .. (type(root) == "table" and vim.inspect(root) or tostring(root))
        end
        lines[#lines + 1] = line
      end
    end
    vim.api.nvim_echo({ { table.concat(lines, "\n"), "Normal" } }, false, {})
  end, { desc = "Show active LSP clients" })

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
