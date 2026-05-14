local M = {}

local modules = {
  "commands.format",
  "commands.git",
}

function M.setup()
  for _, module_name in ipairs(modules) do
    require(module_name).setup()
  end
end

return M
