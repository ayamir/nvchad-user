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

local function sanitize_session_part(value)
  return tostring(value):gsub("[^%w_-]", "_")
end

local function trim_session_part(value, max_len)
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len)
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
  local term = sanitize_session_part(term_name)
  local fingerprint = vim.fn.sha256(table.concat({ project_root, get_git_branch(), term }, "|")):sub(1, HASH_LEN)
  local session_name = string.format("%s_%s_%s_%s", project_token, branch, term, fingerprint)

  if #session_name > SESSION_NAME_MAX_LEN then
    error(string.format("Generated zellij session name is too long: %s", session_name))
  end

  return session_name
end

local function build_zellij_cmd(session_name)
  return string.format(
    "cd %s && zellij attach -c %s",
    vim.fn.shellescape(project_root),
    vim.fn.shellescape(session_name)
  )
end

-- zellij CLI 不暴露 last activity，这里只能按创建时间判断“过期”。
local INACTIVE_THRESHOLD_SECONDS = 7 * 24 * 60 * 60

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
    cmd = default_cmd,
    on_open = function(term)
      last_active = term.id
      vim.opt_local.winbar = ""

      if helper.is_linux() then
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
      term.cmd = build_zellij_cmd(get_session_name(term.name))
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
  local project_name_escaped = sanitize_session_part(project_name)
  local term_suffix = string.format("_%s$", sanitize_session_part(term_name))
  local compact_term_suffix = string.format("_%s_[0-9a-f]+$", sanitize_session_part(term_name))
  local lines = vim.fn.systemlist("zellij list-sessions -n 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}

  for _, line in ipairs(lines) do
    if line ~= "No active zellij sessions found." then
      local name, meta = line:match("^(.-)%s+%[(.+)%]%s*$")
      name = name or vim.trim(line)
      if name ~= "" then
        local is_legacy_project_session = name:find(string.format("^%s_", project_name_escaped)) and name:find(term_suffix)
        local is_compact_project_session = name:find(string.format("^%s_", project_token)) and name:find(compact_term_suffix)
        local is_project_session = is_legacy_project_session or is_compact_project_session

        if is_project_session then
          table.insert(sessions, {
            name = name,
            meta = meta,
            created_seconds = parse_zellij_created_seconds(meta),
          })
        end
      end
    end
  end
  return sessions
end

local function get_expired_sessions(term_name)
  local sessions = get_sessions(term_name)
  local expired_sessions = {}

  for _, session in ipairs(sessions) do
    if session.created_seconds and session.created_seconds > INACTIVE_THRESHOLD_SECONDS then
      table.insert(expired_sessions, {
        name = session.name,
        age_days = session.created_seconds / 86400,
        meta = session.meta,
      })
    end
  end

  return expired_sessions
end

local function confirm_and_cleanup_sessions(expired_sessions, title_lines)
  if #expired_sessions == 0 then
    return 0
  end

  local msg_lines = vim.deepcopy(title_lines)
  table.insert(msg_lines, "")
  for _, session in ipairs(expired_sessions) do
    local suffix = session.meta and string.format(" [%s]", session.meta) or ""
    table.insert(msg_lines, string.format("  - %s%s (创建于 %.1f 天前)", session.name, suffix, session.age_days))
  end
  table.insert(msg_lines, "")
  table.insert(
    msg_lines,
    "注意：zellij CLI 不提供最近活跃时间，这里按创建时间判断，可能包含仍在使用的会话。"
  )
  table.insert(msg_lines, "是否清理这些会话？")

  local choice = vim.fn.confirm(table.concat(msg_lines, "\n"), "&Yes\n&No", 2)
  if choice ~= 1 then
    return 0
  end

  local cleaned_count = 0
  for _, session in ipairs(expired_sessions) do
    vim.fn.system(string.format("zellij kill-session %s", vim.fn.shellescape(session.name)))
    if vim.v.shell_error == 0 then
      cleaned_count = cleaned_count + 1
      vim.notify(string.format("已清理: %s", session.name), vim.log.levels.INFO)
    else
      vim.notify(string.format("清理失败: %s", session.name), vim.log.levels.WARN)
    end
  end

  return cleaned_count
end

local function cleanup_inactive_sessions(term_name)
  local expired_sessions = get_expired_sessions(term_name)
  return confirm_and_cleanup_sessions(expired_sessions, {
    "以下 zellij 会话已过期（创建时间超过 7 天）：",
  })
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
  local sessions = get_sessions(term.name)
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
      prompt_title = string.format("Select zellij session for [%s]", term.name),
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
            "output=$(zellij -s %s action dump-screen --full 2>/dev/null); if [ -n \"$output\" ]; then printf '%%s\\n' \"$output\"; else echo 'No screen content available'; fi",
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
            term.cmd = build_zellij_cmd(get_session_name(term.name))
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
            vim.fn.system(string.format("zellij kill-session %s", vim.fn.shellescape(session_name)))
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
    -- 在查找会话前先清理过期会话
    cleanup_inactive_sessions(term.name)

    -- 总是弹出 telescope 选择会话（包括新建）
    select_session_with_telescope(term)
    return
  end
  open_or_focus(term)
end

-- 手动清理过期会话的公开接口
M.cleanup_expired_sessions = function()
  local all_expired = {}

  for _, term_name in ipairs(names) do
    local sessions = get_expired_sessions(term_name)
    for _, session in ipairs(sessions) do
      session.term_name = term_name
      table.insert(all_expired, session)
    end
  end

  if #all_expired == 0 then
    vim.notify("没有需要清理的过期 zellij 会话", vim.log.levels.INFO)
    return
  end

  local title_lines = { "以下 zellij 会话已过期（创建时间超过 7 天）：" }
  local scoped_sessions = {}
  for _, session in ipairs(all_expired) do
    table.insert(scoped_sessions, {
      name = string.format("[%s] %s", session.term_name, session.name),
      age_days = session.age_days,
      meta = session.meta,
      real_name = session.name,
    })
  end

  local msg_lines = vim.deepcopy(title_lines)
  table.insert(msg_lines, "")
  for _, session in ipairs(scoped_sessions) do
    local suffix = session.meta and string.format(" [%s]", session.meta) or ""
    table.insert(msg_lines, string.format("  - %s%s (创建于 %.1f 天前)", session.name, suffix, session.age_days))
  end
  table.insert(msg_lines, "")
  table.insert(
    msg_lines,
    "注意：zellij CLI 不提供最近活跃时间，这里按创建时间判断，可能包含仍在使用的会话。"
  )
  table.insert(msg_lines, "是否清理这些会话？")

  local choice = vim.fn.confirm(table.concat(msg_lines, "\n"), "&Yes\n&No", 2)
  if choice ~= 1 then
    return
  end

  local cleaned_count = 0
  for _, session in ipairs(scoped_sessions) do
    vim.fn.system(string.format("zellij kill-session %s", vim.fn.shellescape(session.real_name)))
    if vim.v.shell_error == 0 then
      cleaned_count = cleaned_count + 1
    else
      vim.notify(string.format("清理失败: %s", session.real_name), vim.log.levels.WARN)
    end
  end
  vim.notify(string.format("共清理了 %d 个过期会话", cleaned_count), vim.log.levels.INFO)
end

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
