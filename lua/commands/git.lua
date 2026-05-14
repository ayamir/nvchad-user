local api = vim.api
local git_diff_files = require("features.git_diff_files")

local M = {}

function M.setup()
  api.nvim_create_user_command("OpenGitDiffFiles", function()
    git_diff_files.open()
  end, {
    desc = "Open all git diff files in current session",
  })
end

return M
