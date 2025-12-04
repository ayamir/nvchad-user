local M = {}

local Terminal = require("toggleterm.terminal").Terminal

local names = { "main", "lazygit", "coco" }

local terms = {}
for i = 1, 3 do
  terms[i] = Terminal:new({
    id = i,
    direction = "float",
    name = names[i],
  })
end

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*toggleterm#*",
  callback = function()
    local term = require("toggleterm.terminal").get(vim.b.toggle_number)
    if term then
      vim.opt_local.winbar = "  " .. term.name
    end
    -- 确保进入 terminal 模式
    vim.cmd("startinsert")
  end,
})

M.activate_term = function(term)
  term:toggle()
  vim.schedule(function()
    vim.cmd("startinsert!")
  end)
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
    for _, t in ipairs(terms) do
      t:close()
    end
  else
    for _, t in ipairs(terms) do
      M.activate_term(t)
    end
  end
end

M.move_term = function(delta)
  local current = vim.b.toggle_number or 1
  local next = ((current + delta - 1) % 3) + 1
  M.activate_term(terms[next])
end

return M
