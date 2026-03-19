local M = {}

local helper = require("utils.helpers")
local Terminal = require("toggleterm.terminal").Terminal
local vibe = "coco"
if helper.is_linux() then
  vibe = "claude"
end

local names = { vibe, "git", "main" }
local project_root = vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(project_root, ":t")

-- 获取当前 git 分支名（用于 session name）
local function get_git_branch()
  local branch = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error == 0 and #branch > 0 then
    return branch[1]:gsub("[^%w_-]", "_")
  end
  return "main"
end

-- 根据当前分支生成 session name 前缀
local function get_session_prefix(term_name)
  local branch = get_git_branch()
  return string.format("%s_%s_%s", project_name, branch, term_name)
end

-- 清理配置：超过多少秒的会话会被认为是过期的（默认 7 天）
local INACTIVE_THRESHOLD_SECONDS = 7 * 24 * 60 * 60

-- 记录“上一次活跃的 term”，用于 toggle 关闭/再次打开时恢复
local last_active = 1

local terms = {}
for i = 1, 3 do
  local term_name = names[i]
  -- 使用闭包捕获初始的 session_prefix
  local function get_initial_prefix()
    return get_session_prefix(term_name)
  end
  local initial_prefix = get_initial_prefix()
  local default_cmd = string.format("tmux new -As %s -c %s", initial_prefix, vim.fn.shellescape(project_root))

  terms[i] = Terminal:new({
    id = i,
    direction = "float",
    name = term_name,
    cmd = default_cmd,
    on_open = function(term)
      last_active = term.id
      vim.opt_local.winbar = "  " .. term_name

      if helper.is_linux() then
        -- 设置浮窗背景不透明，因为 linux 上已经配置整体透明
        vim.api.nvim_set_option_value("winblend", 0, { scope = "local" })
        vim.cmd("hi NormalFloat guibg=NONE")
        vim.cmd("hi FloatBorder guibg=NONE")
      end

      local function refresh()
        if term.job_id then
          -- 动态确定当前使用的 session_name
          local current_session = term.current_session or get_initial_prefix()
          if not term.current_session and term.cmd:find("tmux attach -t") then
            current_session = term.cmd:match("tmux attach %-t%s+([^%s]+)")
          end

          vim.fn.system(string.format("tmux set-option -t %s status off", current_session))
          vim.fn.system(string.format("tmux refresh-client -t %s", current_session))
          vim.cmd("redraw!")
        end
      end

      -- 延迟多次刷新，确保在浮窗大小稳定后 tmux 能正确对齐
      vim.defer_fn(refresh, 50)
      vim.defer_fn(refresh, 200)

      vim.defer_fn(function()
        if term.job_id then
          vim.cmd("startinsert!")
        end
      end, 100)
    end,
    on_exit = function(term)
      -- 退出后重置为创建新会话的命令
      term.cmd = string.format("tmux new -As %s -c %s", get_session_prefix(term.name), vim.fn.shellescape(project_root))
      term.current_session = nil
    end,
  })
end

local function get_sessions(term_name)
  local project_name_escaped = project_name:gsub("%.", "_")
  local lines =
    vim.fn.systemlist("tmux list-sessions -F '#{session_name} #{session_attached} #{session_activity}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}
  local now = tonumber(vim.fn.strftime("%s"))

  for _, line in ipairs(lines) do
    local name, attached, activity = line:match("^([^%s]+)%s+(%d+)%s+(%d+)")
    if not name then
      name, attached, activity = line:match("^([^%s]+)%s+(%d+)")
    end
    if name and attached then
      -- 匹配新格式: <project>_<branch>_<type>
      local is_new_format = name:find(string.format("^%s_", project_name_escaped))
        and name:find(string.format("_%s$", term_name))

      -- 匹配旧格式: <project>_<type>_<pid> 或 <project>_<type>_<anything>
      local is_old_format = name:find(string.format("^%s_%s_", project_name_escaped, term_name))

      if is_new_format or is_old_format then
        table.insert(sessions, {
          name = name,
          attached = tonumber(attached) > 0,
          activity = tonumber(activity) or now,
        })
      end
    end
  end
  return sessions, now
end

-- 自动清理长时间未活跃的 tmux 会话
local function cleanup_inactive_sessions(term_name)
  local sessions, now = get_sessions(term_name)
  local expired_sessions = {}

  for _, s in ipairs(sessions) do
    -- 只清理未附加的会话
    if not s.attached then
      local inactive_seconds = now - s.activity
      if inactive_seconds > INACTIVE_THRESHOLD_SECONDS then
        table.insert(expired_sessions, {
          name = s.name,
          inactive_days = inactive_seconds / 86400,
        })
      end
    end
  end

  if #expired_sessions == 0 then
    return 0
  end

  -- 构建确认消息
  local msg_lines = { "以下 tmux 会话已过期（超过 7 天未活跃）：", "" }
  for _, s in ipairs(expired_sessions) do
    table.insert(msg_lines, string.format("  - %s (已空闲 %.1f 天)", s.name, s.inactive_days))
  end
  table.insert(msg_lines, "")
  table.insert(msg_lines, "是否清理这些会话？")

  local choice = vim.fn.confirm(table.concat(msg_lines, "\n"), "&Yes\n&No", 2)
  if choice ~= 1 then
    return 0
  end

  -- 执行清理
  local cleaned_count = 0
  for _, s in ipairs(expired_sessions) do
    vim.fn.system(string.format("tmux kill-session -t %s", s.name))
    cleaned_count = cleaned_count + 1
    vim.notify(string.format("已清理: %s", s.name), vim.log.levels.INFO)
  end

  return cleaned_count
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
    local label = s.name .. (s.attached and " (active)" or " (idle)")
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
      prompt_title = string.format("Select tmux session for [%s]", term.name),
      finder = finders.new_table({
        results = options,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          local choice = entry[1]
          if choice == "New Session" then
            return { "echo", "Create a new tmux session" }
          end
          local session_name = session_map[choice]
          -- 使用 tmux capture-pane 捕获内容并直接通过 termopen 显示
          -- -e 支持颜色，-p 输出到 stdout
          return { "tmux", "capture-pane", "-e", "-p", "-t", session_name }
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
            term.cmd = string.format("tmux attach -t %s", session_map[choice])
            term.current_session = session_map[choice]
          else
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
            vim.fn.system(string.format("tmux kill-session -t %s", session_name))
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

    local sessions = get_sessions(term.name)

    -- 总是弹出 telescope 选择会话（包括新建）
    select_session_with_telescope(term)
    return
  end
  open_or_focus(term)
end

-- 手动清理过期会话的公开接口
M.cleanup_expired_sessions = function()
  local all_expired = {}
  local now = tonumber(vim.fn.strftime("%s"))

  -- 先收集所有类型的过期会话
  for _, term_name in ipairs(names) do
    local sessions = get_sessions(term_name)
    for _, s in ipairs(sessions) do
      if not s.attached then
        local inactive_seconds = now - s.activity
        if inactive_seconds > INACTIVE_THRESHOLD_SECONDS then
          table.insert(all_expired, {
            name = s.name,
            inactive_days = inactive_seconds / 86400,
            term_name = term_name,
          })
        end
      end
    end
  end

  if #all_expired == 0 then
    vim.notify("没有需要清理的过期 tmux 会话", vim.log.levels.INFO)
    return
  end

  -- 构建确认消息
  local msg_lines = { "以下 tmux 会话已过期（超过 7 天未活跃）：", "" }
  for _, s in ipairs(all_expired) do
    table.insert(msg_lines, string.format("  [%s] %s (已空闲 %.1f 天)", s.term_name, s.name, s.inactive_days))
  end
  table.insert(msg_lines, "")
  table.insert(msg_lines, "是否清理这些会话？")

  local choice = vim.fn.confirm(table.concat(msg_lines, "\n"), "&Yes\n&No", 2)
  if choice ~= 1 then
    return
  end

  -- 执行清理
  local cleaned_count = 0
  for _, s in ipairs(all_expired) do
    vim.fn.system(string.format("tmux kill-session -t %s", s.name))
    cleaned_count = cleaned_count + 1
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
