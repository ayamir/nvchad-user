local M = {}

local helper = require("utils.helpers")
local names = { "agent", "git", "main" }
local project_root = vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(project_root, ":t")
local SESSION_NAME_MAX_LEN = 36
local PROJECT_TOKEN_MAX_LEN = 12
local BRANCH_TOKEN_MAX_LEN = 10
local HASH_LEN = 6
local TERM_TOKEN_MAX_LEN = SESSION_NAME_MAX_LEN - PROJECT_TOKEN_MAX_LEN - BRANCH_TOKEN_MAX_LEN - HASH_LEN - 3

local last_active = 1
local current_sessions = {}

local function get_zellij_socket_dir()
  local existing = vim.env.ZELLIJ_SOCKET_DIR
  if existing and existing ~= "" then
    return existing
  end

  if vim.fn.has("unix") ~= 1 then
    return nil
  end

  local uv = vim.uv or vim.loop
  if uv and type(uv.os_get_passwd) == "function" then
    local ok, passwd = pcall(uv.os_get_passwd)
    if ok and passwd and passwd.uid ~= nil then
      return string.format("/tmp/zellij-%s", tostring(passwd.uid))
    end
  end

  local uid = vim.env.UID
  if uid and uid ~= "" then
    return string.format("/tmp/zellij-%s", uid)
  end

  return "/tmp/zellij"
end

local ZELLIJ_SOCKET_DIR = get_zellij_socket_dir()

local function sanitize_session_part(value)
  return tostring(value):gsub("[^%w_-]", "_")
end

local function trim_session_part(value, max_len)
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len)
end

local function ensure_zellij_socket_dir()
  if ZELLIJ_SOCKET_DIR and ZELLIJ_SOCKET_DIR ~= "" and vim.fn.isdirectory(ZELLIJ_SOCKET_DIR) == 0 then
    vim.fn.mkdir(ZELLIJ_SOCKET_DIR, "p")
  end
end

local function zellij_cli()
  ensure_zellij_socket_dir()
  if ZELLIJ_SOCKET_DIR and ZELLIJ_SOCKET_DIR ~= "" then
    return string.format("env ZELLIJ_SOCKET_DIR=%s zellij", vim.fn.shellescape(ZELLIJ_SOCKET_DIR))
  end
  return "zellij"
end

local project_token = trim_session_part(sanitize_session_part(project_name), PROJECT_TOKEN_MAX_LEN)

local function get_git_branch()
  local branch = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error == 0 and #branch > 0 then
    return sanitize_session_part(branch[1])
  end
  return "main"
end

local function session_name(term_name, unique)
  local branch = trim_session_part(get_git_branch(), BRANCH_TOKEN_MAX_LEN)
  local term = trim_session_part(sanitize_session_part(term_name), TERM_TOKEN_MAX_LEN)
  local seed = { project_root, get_git_branch(), term }
  if unique then
    local uv = vim.uv or vim.loop
    vim.list_extend(seed, { tostring(vim.fn.getpid()), tostring(os.time()), uv and tostring(uv.hrtime()) or "" })
  end
  local fingerprint = vim.fn.sha256(table.concat(seed, "|")):sub(1, HASH_LEN)
  return string.format("%s_%s_%s_%s", project_token, branch, term, fingerprint)
end

local function build_zellij_cmd(name)
  return string.format(
    "cd %s && %s attach -c %s",
    vim.fn.shellescape(project_root),
    zellij_cli(),
    vim.fn.shellescape(name)
  )
end

local function terminal_opts(index, title)
  return {
    count = index,
    interactive = true,
    auto_insert = true,
    start_insert = true,
    auto_close = false,
    win = {
      style = "terminal",
      title = " " .. title .. " ",
      wo = { number = false, relativenumber = false },
    },
  }
end

local function open_slot(index)
  local name = names[index]
  last_active = index
  current_sessions[index] = current_sessions[index] or session_name(name, false)
  local cmd = build_zellij_cmd(current_sessions[index])
  local term = Snacks.terminal.toggle(cmd, terminal_opts(index, name))

  if not helper.is_linux() then
    vim.schedule(function()
      vim.cmd("hi NormalFloat guibg=NONE")
      vim.cmd("hi FloatBorder guibg=NONE")
    end)
  end

  return term
end

function M.toggle_all_terms()
  local open = false
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:is_valid() and term:win_valid() then
      open = true
      term:hide()
    end
  end
  if not open then
    open_slot(last_active)
  end
end

function M.move_term(delta)
  local next_index = ((last_active + delta - 1) % #names) + 1
  open_slot(next_index)
end

function M.new_session(index)
  index = index or last_active
  current_sessions[index] = session_name(names[index], true)
  open_slot(index)
end

return M
