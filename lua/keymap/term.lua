local M = {}

local helper = require("utils.helpers")
local Terminal = require("toggleterm.terminal").Terminal
local names = { "agent", "git", "main" }
local project_root = vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(project_root, ":t")
local SESSION_NAME_MAX_LEN = 36
local PROJECT_TOKEN_MAX_LEN = 12
local BRANCH_TOKEN_MAX_LEN = 10
local HASH_LEN = 6
local TERM_TOKEN_MAX_LEN = SESSION_NAME_MAX_LEN - PROJECT_TOKEN_MAX_LEN - BRANCH_TOKEN_MAX_LEN - HASH_LEN - 3

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

local function get_term_key(term)
  return term.term_key or term.name
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
  if not ZELLIJ_SOCKET_DIR or ZELLIJ_SOCKET_DIR == "" then
    return
  end

  if vim.fn.isdirectory(ZELLIJ_SOCKET_DIR) == 0 then
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

-- 获取当前 git 分支名（用于 session name）
local function get_git_branch()
  local branch = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error == 0 and #branch > 0 then
    return sanitize_session_part(branch[1])
  end
  return "main"
end

-- zellij session name 最长支持 36 个字符，这里生成稳定且受限长度的名字。
local function get_session_name(term_name)
  local branch = trim_session_part(get_git_branch(), BRANCH_TOKEN_MAX_LEN)
  local term = trim_session_part(sanitize_session_part(term_name), TERM_TOKEN_MAX_LEN)
  local fingerprint = vim.fn.sha256(table.concat({ project_root, get_git_branch(), term }, "|")):sub(1, HASH_LEN)
  return string.format("%s_%s_%s_%s", project_token, branch, term, fingerprint)
end

local function get_new_session_name(term_name)
  local branch = trim_session_part(get_git_branch(), BRANCH_TOKEN_MAX_LEN)
  local term = trim_session_part(sanitize_session_part(term_name), TERM_TOKEN_MAX_LEN)
  local uv = vim.uv or vim.loop
  local unique_seed = table.concat({
    project_root,
    get_git_branch(),
    term,
    tostring(vim.fn.getpid()),
    tostring(os.time()),
    uv and type(uv.hrtime) == "function" and tostring(uv.hrtime()) or "",
  }, "|")
  local fingerprint = vim.fn.sha256(unique_seed):sub(1, HASH_LEN)
  return string.format("%s_%s_%s_%s", project_token, branch, term, fingerprint)
end

local function build_zellij_cmd(session_name)
  return string.format(
    "cd %s && %s attach -c %s",
    vim.fn.shellescape(project_root),
    zellij_cli(),
    vim.fn.shellescape(session_name)
  )
end

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

-- 记录“上一次活跃的 term”，用于 toggle 关闭/再次打开时恢复
local last_active = 1

local terms = {}
for i = 1, 3 do
  local term_name = names[i]
  -- 使用闭包捕获初始的 session_prefix
  local function get_initial_prefix()
    return get_session_name(term_name)
  end
  local initial_prefix = get_initial_prefix()
  local default_cmd = build_zellij_cmd(initial_prefix)

  terms[i] = Terminal:new({
    id = i,
    direction = "float",
    name = term_name,
    term_key = term_name,
    cmd = default_cmd,
    on_open = function(term)
      last_active = term.id
      vim.opt_local.winbar = ""

      if not helper.is_linux() then
        -- 设置浮窗背景不透明，因为 linux 上已经配置整体透明
        vim.api.nvim_set_option_value("winblend", 0, { scope = "local" })
        vim.cmd("hi NormalFloat guibg=NONE")
        vim.cmd("hi FloatBorder guibg=NONE")
      end

      vim.defer_fn(function()
        if term.job_id then
          vim.cmd("startinsert!")
        end
      end, 100)
    end,
    on_exit = function(term)
      -- 退出后重置为创建新会话的命令
      term.cmd = build_zellij_cmd(get_session_name(get_term_key(term)))
      term.current_session = nil
    end,
  })
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

  if matched then
    return total
  end

  return nil
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

local function open_or_focus(term)
  -- 优先使用 open：不会在已打开时误关掉
  if type(term.open) == "function" then
    term:open()
    return
  end

  -- 兼容旧版本：没有 open 方法时退化为 toggle
  if term.is_open and term:is_open() then
    return
  end
  term:toggle()
end

local function select_session_with_telescope(term)
  local term_key = get_term_key(term)
  local sessions = get_sessions(term_key)
  local options = { "New Session" }
  local session_map = {}
  for _, s in ipairs(sessions) do
    local label = s.meta and string.format("%s [%s]", s.name, s.meta) or s.name
    table.insert(options, label)
    session_map[label] = s.name
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
      prompt_title = string.format("Select zellij session for [%s]", term_key),
      finder = finders.new_table({
        results = options,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          local choice = entry[1]
          if choice == "New Session" then
            return { "echo", "Create a new zellij session" }
          end
          local session_name = session_map[choice]
          local preview_cmd = string.format(
            "output=$(%s -s %s action dump-screen --full 2>/dev/null); if [ -n \"$output\" ]; then printf '%%s\\n' \"$output\"; else echo 'No screen content available'; fi",
            zellij_cli(),
            vim.fn.shellescape(session_name)
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
          if choice ~= "New Session" then
            term.cmd = build_zellij_cmd(session_map[choice])
            term.current_session = session_map[choice]
          else
            term.cmd = build_zellij_cmd(get_new_session_name(term_key))
            term.current_session = nil
          end
          open_or_focus(term)
        end)

        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end
          local choice = selection[1]
          if choice ~= "New Session" then
            local session_name = session_map[choice]
            vim.fn.system(string.format("%s kill-session %s", zellij_cli(), vim.fn.shellescape(session_name)))
            actions.close(prompt_bufnr)
            -- 重新打开选择器以刷新列表
            select_session_with_telescope(term)
          else
            vim.notify("Cannot delete 'New Session' option", vim.log.levels.WARN)
          end
        end)

        -- 允许在选择器开启时通过 <A-j>/<A-k> 切换终端
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

        -- 允许在选择器开启时通过 <A-d> 直接关闭界面（取消操作）
        map({ "i", "n" }, "<A-d>", function()
          actions.close(prompt_bufnr)
        end)

        return true
      end,
    })
    :find()
end

M.activate_term = function(term)
  last_active = term.id
  if not term.job_id then
    -- 总是弹出 telescope 选择会话（包括新建）
    select_session_with_telescope(term)
    return
  end
  open_or_focus(term)
end

-- 手动清理过期会话的公开接口

M.any_term_open = function()
  for _, t in ipairs(terms) do
    if t:is_open() then
      return true
    end
  end
  return false
end

-- Toggle 全部
M.toggle_all_terms = function()
  if M.any_term_open() then
    -- 记录关闭前所在的 term（如果当前就在 toggleterm 里）
    if vim.b.toggle_number then
      last_active = vim.b.toggle_number
    end
    for _, t in ipairs(terms) do
      t:close()
    end
  else
    -- 重新打开时：只打开上次活跃的那个 term，其他 term 按需再打开（切换时会自动打开）
    local target = terms[last_active] or terms[1]
    M.activate_term(target)
  end
end

M.move_term = function(delta)
  local current = vim.b.toggle_number or last_active or 1
  local next = ((current + delta - 1) % 3) + 1
  M.activate_term(terms[next])
end

return M
