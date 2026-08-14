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

local function tmux_cli()
  return "tmux"
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

-- tmux session 名保持短且稳定，避免 target 名称太长时选择器难读。
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

local function build_tmux_cmd(session_name)
  return string.format(
    "cd %s && %s new-session -A -s %s",
    vim.fn.shellescape(project_root),
    tmux_cli(),
    vim.fn.shellescape(session_name)
  )
end

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
  local default_cmd = build_tmux_cmd(initial_prefix)

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
      term.cmd = build_tmux_cmd(get_session_name(get_term_key(term)))
      term.current_session = nil
    end,
  })
end

local function get_sessions(term_name)
  local legacy_project_prefix = string.format("%s_", sanitize_session_part(project_name))
  local sanitized_term_name = sanitize_session_part(term_name)
  local compact_term_name = trim_session_part(sanitized_term_name, TERM_TOKEN_MAX_LEN)
  local legacy_term_suffix = string.format("_%s", sanitized_term_name)
  local compact_project_prefix = string.format("%s_", project_token)
  local compact_term_suffix_pattern = string.format("_%s_[0-9a-f]+$", escape_lua_pattern(compact_term_name))
  local lines = vim.fn.systemlist(
    string.format(
      "%s list-sessions -F %s 2>/dev/null",
      tmux_cli(),
      vim.fn.shellescape("#{session_name}\t#{session_created}\t#{session_windows} window(s)")
    )
  )

  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}
  for _, line in ipairs(lines) do
    local name, created, windows = line:match("^([^\t]+)\t(%d+)\t(.+)$")
    name = name or vim.trim(line)
    if name ~= "" then
      local is_legacy_project_session = starts_with(name, legacy_project_prefix)
        and ends_with(name, legacy_term_suffix)
      local is_compact_project_session = starts_with(name, compact_project_prefix)
        and name:find(compact_term_suffix_pattern)

      if is_legacy_project_session or is_compact_project_session then
        local created_at = tonumber(created)
        table.insert(sessions, {
          name = name,
          meta = created_at and string.format("%s, %s", os.date("%Y-%m-%d %H:%M", created_at), windows) or nil,
          created_at = created_at,
        })
      end
    end
  end

  table.sort(sessions, function(a, b)
    return (a.created_at or 0) > (b.created_at or 0)
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

local function select_session_with_snacks(term)
  local term_key = get_term_key(term)
  local sessions = get_sessions(term_key)
  local items = {
    {
      text = "New Session",
      preview = { text = "Create a new tmux session", ft = "text", loc = false },
    },
  }

  for _, session in ipairs(sessions) do
    local label = session.meta and string.format("%s [%s]", session.name, session.meta) or session.name
    local output = vim.fn.system({ tmux_cli(), "capture-pane", "-p", "-J", "-S", "-200", "-t", session.name })
    items[#items + 1] = {
      text = label,
      session_name = session.name,
      preview = { text = output ~= "" and output or "No screen content available", ft = "text", loc = false },
    }
  end

  Snacks.picker.pick({
    source = "tmux_sessions",
    title = string.format("Select tmux session for [%s]", term_key),
    finder = function()
      return items
    end,
    format = "text",
    layout = { preset = "vertical" },
    actions = {
      confirm = function(picker, item)
        picker:close()
        if item.session_name then
          term.cmd = build_tmux_cmd(item.session_name)
          term.current_session = item.session_name
        else
          term.cmd = build_tmux_cmd(get_new_session_name(term_key))
          term.current_session = nil
        end
        open_or_focus(term)
      end,
      delete_session = function(picker, item)
        if not item or not item.session_name then
          vim.notify("Cannot delete 'New Session' option", vim.log.levels.WARN)
          return
        end
        vim.fn.system({ tmux_cli(), "kill-session", "-t", item.session_name })
        picker:close()
        select_session_with_snacks(term)
      end,
      next_term = function(picker)
        picker:close()
        vim.schedule(function()
          M.move_term(1)
        end)
      end,
      prev_term = function(picker)
        picker:close()
        vim.schedule(function()
          M.move_term(-1)
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete_session", mode = { "n", "i" } },
          ["<A-j>"] = { "next_term", mode = { "n", "i" } },
          ["<A-k>"] = { "prev_term", mode = { "n", "i" } },
          ["<A-d>"] = { "close", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-d>"] = "delete_session",
          ["<A-j>"] = "next_term",
          ["<A-k>"] = "prev_term",
          ["<A-d>"] = "close",
        },
      },
    },
  })
end

M.activate_term = function(term)
  last_active = term.id
  if not term.job_id then
    -- 总是弹出 Snacks 选择会话（包括新建）
    select_session_with_snacks(term)
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
