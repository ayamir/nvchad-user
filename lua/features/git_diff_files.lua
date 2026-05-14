local api = vim.api

local M = {}

local function git_systemlist(cmd)
  return vim.fn.systemlist(cmd)
end

local function get_git_root()
  local output = git_systemlist("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 or #output == 0 then
    return nil
  end

  return vim.trim(output[1])
end

local function get_git_diff_files()
  local git_root = get_git_root()
  if not git_root then
    return nil, "当前目录不在 git 仓库中"
  end

  local git_root_escaped = vim.fn.shellescape(git_root)
  local tracked_files = git_systemlist(string.format("git -C %s diff --name-only HEAD -- 2>/dev/null", git_root_escaped))
  local untracked_files = git_systemlist(
    string.format("git -C %s ls-files --others --exclude-standard 2>/dev/null", git_root_escaped)
  )

  local files = {}
  local seen = {}

  for _, rel_path in ipairs(vim.list_extend(tracked_files, untracked_files)) do
    local normalized = vim.trim(rel_path)
    if normalized ~= "" then
      local abs_path = git_root .. "/" .. normalized
      if vim.fn.filereadable(abs_path) == 1 and not seen[abs_path] then
        seen[abs_path] = true
        table.insert(files, abs_path)
      end
    end
  end

  return files, nil
end

local function can_switch_from_current_buffer()
  local current_buf = api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(current_buf) then
    return true
  end

  return not vim.bo[current_buf].modified
end

local function add_file_to_current_session(file)
  vim.cmd("badd " .. vim.fn.fnameescape(file))
  return vim.fn.bufnr(file)
end

function M.open()
  local files, err = get_git_diff_files()
  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if #files == 0 then
    vim.notify("当前仓库没有 git diff 文件", vim.log.levels.INFO)
    return
  end

  local first_bufnr = nil
  for _, file in ipairs(files) do
    local bufnr = add_file_to_current_session(file)
    if not first_bufnr then
      first_bufnr = bufnr
    end
  end

  if first_bufnr and can_switch_from_current_buffer() then
    require("nvchad.tabufline").goto_buf(first_bufnr)
  end

  vim.cmd("redrawtabline")
  vim.notify(string.format("已加入 %d 个 git diff 文件到当前会话", #files), vim.log.levels.INFO)
end

return M
