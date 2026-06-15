local api = vim.api

local M = {}
local PREFERRED_BASE_REFS = { "main", "dev", "master" }

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

local function should_include_file(rel_path)
  return not (rel_path:match("_test%.go$") or rel_path:match("%.bazel$"))
end

local function collect_abs_files(git_root, paths)
  local files = {}
  local seen = {}

  for _, rel_path in ipairs(paths) do
    local normalized = vim.trim(rel_path)
    if normalized ~= "" and should_include_file(normalized) then
      local abs_path = git_root .. "/" .. normalized
      if vim.fn.filereadable(abs_path) == 1 and not seen[abs_path] then
        seen[abs_path] = true
        table.insert(files, abs_path)
      end
    end
  end

  return files
end

local function get_worktree_diff_files()
  local git_root = get_git_root()
  if not git_root then
    return nil, "当前目录不在 git 仓库中"
  end

  local git_root_escaped = vim.fn.shellescape(git_root)
  local tracked_files =
    git_systemlist(string.format("git -C %s diff --name-only HEAD -- 2>/dev/null", git_root_escaped))
  local untracked_files =
    git_systemlist(string.format("git -C %s ls-files --others --exclude-standard 2>/dev/null", git_root_escaped))

  return collect_abs_files(git_root, vim.list_extend(tracked_files, untracked_files)), nil
end

local function get_branch_diff_files(base_ref)
  local git_root = get_git_root()
  if not git_root then
    return nil, "当前目录不在 git 仓库中"
  end

  local git_root_escaped = vim.fn.shellescape(git_root)
  local base_ref_escaped = vim.fn.shellescape(base_ref)

  vim.fn.system(string.format("git -C %s rev-parse --verify %s >/dev/null 2>&1", git_root_escaped, base_ref_escaped))
  if vim.v.shell_error ~= 0 then
    return nil, string.format("git 基线分支不存在: %s", base_ref)
  end

  local changed_files = git_systemlist(
    string.format("git -C %s diff --name-only %s...HEAD -- 2>/dev/null", git_root_escaped, base_ref_escaped)
  )

  return collect_abs_files(git_root, changed_files), nil
end

local function resolve_base_ref()
  local git_root = get_git_root()
  if not git_root then
    return nil, "当前目录不在 git 仓库中"
  end

  local git_root_escaped = vim.fn.shellescape(git_root)

  for _, base_ref in ipairs(PREFERRED_BASE_REFS) do
    local base_ref_escaped = vim.fn.shellescape(base_ref)
    vim.fn.system(string.format("git -C %s rev-parse --verify %s >/dev/null 2>&1", git_root_escaped, base_ref_escaped))
    if vim.v.shell_error == 0 then
      return base_ref, nil
    end
  end

  return nil, string.format("git 基线分支不存在，可选顺序: %s", table.concat(PREFERRED_BASE_REFS, " > "))
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

local function clear_current_tab_buffers()
  require("nvchad.tabufline").closeAllBufs(true)
end

local function open_files(files, opts)
  opts = opts or {}

  if opts.clear_current_tab then
    clear_current_tab_buffers()
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
end

function M.open()
  local files, err = get_worktree_diff_files()
  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if #files == 0 then
    vim.notify("当前仓库没有 git diff 文件", vim.log.levels.INFO)
    return
  end

  open_files(files)
  vim.notify(string.format("已加入 %d 个 git diff 文件到当前会话", #files), vim.log.levels.INFO)
end

function M.open_branch_diff_against_base()
  local base_ref, base_err = resolve_base_ref()
  if base_err then
    vim.notify(base_err, vim.log.levels.WARN)
    return
  end

  local files, err = get_branch_diff_files(base_ref)
  if err then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if #files == 0 then
    vim.notify(string.format("当前分支相对于 %s 没有改动文件", base_ref), vim.log.levels.INFO)
    return
  end

  open_files(files, { clear_current_tab = true })
  vim.notify(string.format("已打开 %d 个相对于 %s 的改动文件", #files, base_ref), vim.log.levels.INFO)
end

return M
