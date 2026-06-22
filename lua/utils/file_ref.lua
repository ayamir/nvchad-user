local M = {}

local OPENERS = { ['"'] = true, ["'"] = true, ["("] = true, ["["] = true, ["{"] = true, ["<"] = true }
local CLOSERS = {
  ['"'] = true,
  ["'"] = true,
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
  [">"] = true,
  [","] = true,
  [";"] = true,
  [":"] = true,
}

local function trim_token(token, start_col, finish_col)
  while #token > 0 do
    local ch = token:sub(1, 1)
    if not OPENERS[ch] then
      break
    end
    token = token:sub(2)
    start_col = start_col + 1
  end

  while #token > 0 do
    local ch = token:sub(-1)
    if not CLOSERS[ch] then
      break
    end
    token = token:sub(1, -2)
    finish_col = finish_col - 1
  end

  return token, start_col, finish_col
end

local function looks_like_path(token)
  return token:find("/", 1, true)
    or token:find("\\", 1, true)
    or token:match("^~[/\\]")
    or token:match("^%.%.?[/\\]")
    or token:match("^%a:[/\\]")
    or token:match("[%w_.-]%.[%w_-]+$")
end

local function parse_file_ref(token)
  -- Match "file:line" and "file:line:column". The file part may contain
  -- colons too (for example URI-like paths); use the last numeric fields.
  local file, lnum, col = token:match("^(.+):(%d+):(%d+)$")
  if not file then
    file, lnum = token:match("^(.+):(%d+)$")
  end

  if file and file ~= "" then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = col and tonumber(col) or 1,
    }
  end

  -- Also support plain file paths like "lua/utils/file_ref.lua". They open
  -- at the first line, and the later fs_stat check filters out non-files.
  if looks_like_path(token) then
    return {
      file = token,
      lnum = 1,
      col = 1,
    }
  end
end

---@param line string
---@param col number 1-based byte column
---@return table|nil
function M.ref_at(line, col)
  local idx = 1
  while idx <= #line do
    local start_col, finish_col = line:find("%S+", idx)
    if not start_col then
      break
    end

    local token = line:sub(start_col, finish_col)
    token, start_col, finish_col = trim_token(token, start_col, finish_col)

    if start_col <= col and col <= finish_col then
      return parse_file_ref(token)
    end

    idx = finish_col + 1
  end
end

local function resolve_path(path, base_winid)
  path = vim.fn.expand(path)
  if vim.fn.fnamemodify(path, ":p") == path then
    return path
  end

  local current_file_dir = ""
  if base_winid and vim.api.nvim_win_is_valid(base_winid) then
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(base_winid))
    if bufname ~= "" then
      current_file_dir = vim.fn.fnamemodify(bufname, ":p:h")
    end
  end

  if current_file_dir ~= "" then
    local from_current_file = vim.fs.normalize(current_file_dir .. "/" .. path)
    if vim.uv.fs_stat(from_current_file) then
      return from_current_file
    end
  end

  return vim.fs.normalize(vim.fn.getcwd() .. "/" .. path)
end

local SPECIAL_FILETYPES = {
  ["neo-tree"] = true,
  aerial = true,
  alpha = true,
  dashboard = true,
  edgy = true,
  help = true,
  lazy = true,
  man = true,
  noice = true,
  qf = true,
  snacks_notif = true,
  snacks_notif_history = true,
  snacks_picker = true,
  snacks_picker_input = true,
  snacks_picker_list = true,
  snacks_picker_preview = true,
  trouble = true,
}

local function is_main_window(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return false
  end

  if vim.api.nvim_win_get_config(winid).relative ~= "" then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  local buftype = vim.bo[bufnr].buftype
  local filetype = vim.bo[bufnr].filetype

  return buftype == "" and not SPECIAL_FILETYPES[filetype]
end

local restore_terminal_group = vim.api.nvim_create_augroup("FileRefRestoreTerminalInsert", { clear = false })

local function ensure_terminal_insert(term_bufnr)
  if not vim.api.nvim_buf_is_valid(term_bufnr) or vim.api.nvim_get_current_buf() ~= term_bufnr then
    return false
  end

  if vim.bo[term_bufnr].buftype ~= "terminal" then
    return false
  end

  if vim.fn.mode():sub(1, 1) == "t" then
    return true
  end

  vim.cmd("startinsert!")

  if vim.fn.mode():sub(1, 1) ~= "t" then
    local i = vim.api.nvim_replace_termcodes("i", true, false, true)
    vim.api.nvim_feedkeys(i, "n", false)
  end

  return true
end

local function restore_terminal_insert_on_return(winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local term_bufnr = vim.api.nvim_win_get_buf(winid)
  if vim.bo[term_bufnr].buftype ~= "terminal" then
    return
  end

  vim.b[term_bufnr].file_ref_restore_terminal_insert = true

  vim.api.nvim_clear_autocmds({
    group = restore_terminal_group,
    buffer = term_bufnr,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = restore_terminal_group,
    buffer = term_bufnr,
    callback = function(args)
      if not vim.b[args.buf].file_ref_restore_terminal_insert then
        return
      end

      local function try_restore()
        if ensure_terminal_insert(args.buf) then
          vim.b[args.buf].file_ref_restore_terminal_insert = false
          vim.api.nvim_clear_autocmds({
            group = restore_terminal_group,
            buffer = args.buf,
          })
        end
      end

      vim.schedule(try_restore)
      vim.defer_fn(try_restore, 30)
      vim.defer_fn(try_restore, 100)
    end,
  })
end

local function goto_main_window(clicked_winid)
  local previous_winid = vim.fn.win_getid(vim.fn.winnr("#"))
  if previous_winid ~= clicked_winid and is_main_window(previous_winid) and vim.fn.win_gotoid(previous_winid) == 1 then
    return true
  end

  if is_main_window(clicked_winid) and vim.fn.win_gotoid(clicked_winid) == 1 then
    return true
  end

  local best_winid
  local best_area = -1
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_main_window(winid) then
      local area = vim.api.nvim_win_get_width(winid) * vim.api.nvim_win_get_height(winid)
      if area > best_area then
        best_winid = winid
        best_area = area
      end
    end
  end

  if best_winid and vim.fn.win_gotoid(best_winid) == 1 then
    return true
  end

  vim.cmd("botright new")
  return true
end

function M.open_in_buffer_from_mouse()
  local mouse = vim.fn.getmousepos()
  if mouse.winid == 0 or mouse.line == 0 then
    return
  end

  if not vim.api.nvim_win_is_valid(mouse.winid) then
    return
  end

  local line = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(mouse.winid), mouse.line - 1, mouse.line, false)[1]
  if not line then
    return
  end

  local ref = M.ref_at(line, mouse.column)
  if not ref then
    vim.notify("No file:line reference under cursor", vim.log.levels.INFO)
    return
  end

  local file = resolve_path(ref.file, mouse.winid)
  if not vim.uv.fs_stat(file) then
    vim.notify("File not found: " .. file, vim.log.levels.WARN)
    return
  end

  restore_terminal_insert_on_return(mouse.winid)

  if not goto_main_window(mouse.winid) then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(file))

  local last_line = vim.api.nvim_buf_line_count(0)
  local target_line = math.max(1, math.min(ref.lnum, last_line))
  local target_col = math.max(0, (ref.col or 1) - 1)
  vim.api.nvim_win_set_cursor(0, { target_line, target_col })
  vim.cmd("normal! zz")
end

return M
