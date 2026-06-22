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

local TIME_UNIT_SECONDS = {
  s = 1,
  sec = 1,
  secs = 1,
  second = 1,
  seconds = 1,
  m = 60,
  min = 60,
  mins = 60,
  minute = 60,
  minutes = 60,
  h = 3600,
  hr = 3600,
  hrs = 3600,
  hour = 3600,
  hours = 3600,
  d = 86400,
  day = 86400,
  days = 86400,
  w = 604800,
  week = 604800,
  weeks = 604800,
  mo = 2592000,
  month = 2592000,
  months = 2592000,
  y = 31536000,
  yr = 31536000,
  yrs = 31536000,
  year = 31536000,
  years = 31536000,
}

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

local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function ends_with(value, suffix)
  return suffix == "" or value:sub(-#suffix) == suffix
end

local function escape_lua_pattern(value)
  return value:gsub("([^%w])", "%%%1")
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

local function parse_zellij_created_seconds(meta)
  if not meta then
    return nil
  end

  local created = meta:match("^Created%s+(.+)%s+ago$")
  if not created then
    return nil
  end

  local total = 0
  local matched = false
  for value, unit in created:gmatch("(%d+)%s*([%a]+)") do
    local multiplier = TIME_UNIT_SECONDS[unit:lower()]
    if multiplier then
      total = total + tonumber(value) * multiplier
      matched = true
    end
  end

  return matched and total or nil
end

local function get_sessions(term_name)
  local legacy_project_prefix = string.format("%s_", sanitize_session_part(project_name))
  local sanitized_term_name = sanitize_session_part(term_name)
  local compact_term_name = trim_session_part(sanitized_term_name, TERM_TOKEN_MAX_LEN)
  local legacy_term_suffix = string.format("_%s", sanitized_term_name)
  local compact_project_prefix = string.format("%s_", project_token)
  local compact_term_suffix_pattern = string.format("_%s_[0-9a-f]+$", escape_lua_pattern(compact_term_name))
  local lines = vim.fn.systemlist(string.format("%s list-sessions -n 2>/dev/null", zellij_cli()))

  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}
  for _, line in ipairs(lines) do
    if line ~= "No active zellij sessions found." then
      local name, meta = line:match("^(.-)%s+%[(.+)%]%s*$")
      name = name or vim.trim(line)
      if name ~= "" then
        local is_legacy_project_session = starts_with(name, legacy_project_prefix)
          and ends_with(name, legacy_term_suffix)
        local is_compact_project_session = starts_with(name, compact_project_prefix)
          and name:find(compact_term_suffix_pattern)

        if is_legacy_project_session or is_compact_project_session then
          table.insert(sessions, {
            name = name,
            meta = meta,
            created_seconds = parse_zellij_created_seconds(meta),
          })
        end
      end
    end
  end

  table.sort(sessions, function(a, b)
    return (a.created_seconds or math.huge) < (b.created_seconds or math.huge)
  end)

  return sessions
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

local function select_session(index)
  local term_name = names[index]
  local sessions = get_sessions(term_name)
  local options = { "New Session" }
  local session_map = {}

  for _, session in ipairs(sessions) do
    local label = session.meta and string.format("%s [%s]", session.name, session.meta) or session.name
    options[#options + 1] = label
    session_map[label] = session.name
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers
    .new({
      layout_strategy = "vertical",
      layout_config = {
        width = 0.8,
        height = 0.9,
        preview_height = 0.8,
        prompt_position = "top",
      },
      sorting_strategy = "ascending",
    }, {
      prompt_title = string.format("Select zellij session for [%s]", term_name),
      finder = finders.new_table({ results = options }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          local choice = entry[1]
          if choice == "New Session" then
            return { "echo", "Create a new zellij session" }
          end

          local preview_cmd = string.format(
            "output=$(%s -s %s action dump-screen --full 2>/dev/null); if [ -n \"$output\" ]; then printf '%%s\\n' \"$output\"; else echo 'No screen content available'; fi",
            zellij_cli(),
            vim.fn.shellescape(session_map[choice])
          )
          return { "bash", "-lc", preview_cmd }
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end

          local choice = selection[1]
          current_sessions[index] = choice == "New Session" and session_name(term_name, true) or session_map[choice]
          open_slot(index)
        end)

        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end

          local choice = selection[1]
          if choice == "New Session" then
            vim.notify("Cannot delete 'New Session' option", vim.log.levels.WARN)
            return
          end

          vim.fn.system(string.format("%s kill-session %s", zellij_cli(), vim.fn.shellescape(session_map[choice])))
          actions.close(prompt_bufnr)
          vim.schedule(function()
            select_session(index)
          end)
        end)

        map({ "i", "n" }, "<A-j>", function()
          actions.close(prompt_bufnr)
          vim.schedule(function()
            M.move_term(1)
          end)
        end)

        map({ "i", "n" }, "<A-k>", function()
          actions.close(prompt_bufnr)
          vim.schedule(function()
            M.move_term(-1)
          end)
        end)

        map({ "i", "n" }, "<A-d>", function()
          actions.close(prompt_bufnr)
        end)

        return true
      end,
    })
    :find()
end

function M.toggle_all_terms()
  local open = false
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:buf_valid() and term:win_valid() then
      open = true
      term:hide()
    end
  end
  if not open then
    select_session(last_active)
  end
end

function M.move_term(delta)
  local next_index = ((last_active + delta - 1) % #names) + 1
  last_active = next_index
  select_session(next_index)
end

function M.new_session(index)
  index = index or last_active
  current_sessions[index] = session_name(names[index], true)
  open_slot(index)
end

return M
