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
  -- 使用项目名 + 终端名 + PID 保证不同 nvim 实例间的 tmux 会话隔离
  -- 替换掉 tmux 不喜欢的字符（如点号）
  local session_name = string.format("%s_%s_%d", project_name, names[i], pid):gsub("%.", "_")
  terms[i] = Terminal:new({
    id = i,
    direction = "float",
    name = names[i],
    -- -A: 如果会话已存在则 attach，否则新建
    -- -s: 指定会话名称
    -- -c: 指定启动目录
    cmd = string.format("tmux new -As %s -c %s", session_name, vim.fn.shellescape(project_root)),
    on_open = function(term)
      last_active = term.id
      vim.opt_local.winbar = "  " .. term.name

      -- 修复 tmux 视图偏移/畸变问题
      -- 1. 强制关闭 tmux 的状态栏，减少行数干扰
      -- 2. 强制刷新客户端以适应当前窗口大小
      vim.defer_fn(function()
        if term.job_id then
          vim.fn.system(string.format("tmux set-option -t %s status off", session_name))
          vim.fn.system(string.format("tmux refresh-client -t %s", session_name))
          vim.cmd("startinsert!")
        end
      end, 50)
    end,
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

M.activate_term = function(term)
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
