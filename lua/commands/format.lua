local api = vim.api
local format = require("features.format")

local M = {}

function M.setup()
  format.setup()

  api.nvim_create_user_command("Format", function()
    format.format_buffer()
  end, {})

  api.nvim_create_user_command("FormatToggle", function()
    format.toggle_on_save()
  end, {})
end

return M
