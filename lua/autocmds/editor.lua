local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local function collect_treesitter_filetypes()
  local ft_ok = {}
  local deps = require("settings").treesitter_deps or {}

  for _, lang in ipairs(deps) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      ft_ok[ft] = true
    end
  end

  return ft_ok
end

local treesitter_filetypes = collect_treesitter_filetypes()

local function restore_last_cursor()
  local mark = api.nvim_buf_get_mark(0, '"')
  local line_count = api.nvim_buf_line_count(0)

  if mark[1] > 0 and mark[1] <= line_count then
    pcall(api.nvim_win_set_cursor, 0, mark)
  end
end

local function highlight_on_yank()
  vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
end

function M.setup()
  create_autocmd("FileType", {
    group = create_augroup("TSHighlight"),
    callback = function(args)
      if treesitter_filetypes[vim.bo[args.buf].filetype] then
        vim.treesitter.start(args.buf)
      end
    end,
  })

  create_autocmd("BufReadPost", {
    group = create_augroup("RestoreLastCursor"),
    callback = restore_last_cursor,
  })

  create_autocmd("TextYankPost", {
    group = create_augroup("YankHighlight"),
    callback = highlight_on_yank,
  })
end

return M
