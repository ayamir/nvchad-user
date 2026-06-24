local M = {}

function M.is_linux()
  return M.is_nixos() or M.is_archlinux()
end

-- 检查当前系统是否为 NixOS
function M.is_nixos()
  local f = io.open("/etc/os-release", "r")
  if f then
    local content = f:read("*all")
    f:close()
    return content:match("ID=nixos") ~= nil
  end
  return false
end

-- 检查当前系统是否为 Arch Linux
function M.is_archlinux()
  local f = io.open("/etc/os-release", "r")
  if f then
    local content = f:read("*all")
    f:close()
    return content:match("ID=arch") ~= nil or content:match("ID_LIKE=arch") ~= nil
  end
  return false
end

function M.find_or_create_project_bookmark_group()
  local current_file = vim.api.nvim_buf_get_name(0)
  local start = current_file ~= "" and current_file or vim.uv.cwd()
  local project_root = vim.fs.root(start, { ".git" }) or vim.uv.cwd()

  local project_name = project_root
    :gsub("^" .. vim.pesc(os.getenv("HOME")) .. "/", "")
    :gsub("^/data00/home/[^/]+/", "")
    :gsub("^/[^/]+/[^/]+/", "")
  local Service = require("bookmarks.domain.service")
  local Repo = require("bookmarks.domain.repo")
  local bookmark_list = nil

  for _, bl in ipairs(Repo.find_lists()) do
    if bl.name == project_name then
      bookmark_list = bl
      break
    end
  end

  if not bookmark_list then
    bookmark_list = Service.create_list(project_name)
  end
  Service.set_active_list(bookmark_list.id)
  require("bookmarks.sign").safe_refresh_signs()
end

return M
