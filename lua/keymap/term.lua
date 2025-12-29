local M = {}

local Terminal = require("toggleterm.terminal").Terminal

local names = { "coco", "lazygit", "main" }
local project_root = vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(project_root, ":t")
local pid = vim.fn.getpid()

-- 记录“上一次活跃的 term”，用于 toggle 关闭/再次打开时恢复
local last_active = 1

local terms = {}
for i = 1, 3 do
  local term_name = names[i]
  local default_session_name = string.format("%s_%s_%d", project_name, term_name, pid):gsub("%.", "_")
  local default_cmd = string.format("tmux new -As %s -c %s", default_session_name, vim.fn.shellescape(project_root))

  terms[i] = Terminal:new({
    id = i,
    direction = "float",
    name = term_name,
    cmd = default_cmd,
    on_open = function(term)
      last_active = term.id
      vim.opt_local.winbar = "  " .. term_name

      -- 动态确定当前使用的 session_name
      local current_session = default_session_name
      if term.cmd:find("tmux attach -t") then
        current_session = term.cmd:match("tmux attach %-t%s+([^%s]+)")
      end

      vim.defer_fn(function()
        if term.job_id then
          vim.fn.system(string.format("tmux set-option -t %s status off", current_session))
          vim.fn.system(string.format("tmux refresh-client -t %s", current_session))
          vim.cmd("startinsert!")
        end
      end, 50)
    end,
    on_exit = function(term)
      -- 退出后重置为默认命令
      term.cmd = default_cmd
    end,
  })
end

local function get_sessions(term_name)
  local prefix = string.format("%s_%s_", project_name, term_name):gsub("%.", "_")
  local lines = vim.fn.systemlist("tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}
  for _, line in ipairs(lines) do
    local name, attached = line:match("^([^%s]+)%s+(%d+)")
    if name and name:find("^" .. prefix) then
      table.insert(sessions, {
        name = name,
        attached = tonumber(attached) > 0,
      })
    end
  end
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

M.activate_term = function(term)
  if not term.job_id then
    local sessions = get_sessions(term.name)
    local idle_sessions = {}
    for _, s in ipairs(sessions) do
      if not s.attached then
        table.insert(idle_sessions, s)
      end
    end

    if #idle_sessions == 1 then
      -- 只有一个空闲会话，自动重连
      term.cmd = string.format("tmux attach -t %s", idle_sessions[1].name)
      open_or_focus(term)
      return
    elseif #sessions > 0 then
      -- 有多个会话（或虽有会话但都在使用中），提供选择
      local options = { "New Session" }
      local session_map = {}
      for _, s in ipairs(sessions) do
        local label = s.name .. (s.attached and " (active)" or " (idle)")
        table.insert(options, label)
        session_map[label] = s.name
      end

      vim.ui.select(options, {
        prompt = string.format("Select tmux session for [%s]:", term.name),
      }, function(choice)
        if not choice then
          return
        end
        if choice ~= "New Session" then
          term.cmd = string.format("tmux attach -t %s", session_map[choice])
        end
        open_or_focus(term)
      end)
      return
    end
  end
  open_or_focus(term)
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
