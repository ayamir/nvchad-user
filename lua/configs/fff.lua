local M = {}

local function is_non_empty_string(value)
  return type(value) == "string" and value ~= ""
end

local function join_under_base(base_path, relative_path)
  if not is_non_empty_string(relative_path) then
    return nil
  end

  if vim.fs and vim.fs.normalize then
    if is_non_empty_string(base_path) then
      return vim.fs.normalize(base_path .. "/" .. relative_path)
    end
    return vim.fs.normalize(relative_path)
  end

  if is_non_empty_string(base_path) then
    return base_path .. "/" .. relative_path
  end
  return relative_path
end

local function resolve_item_path(picker_ui, item)
  if type(item) ~= "table" then
    return nil
  end

  if is_non_empty_string(item.path) then
    return item.path
  end

  local base_path = picker_ui.state and picker_ui.state.config and picker_ui.state.config.base_path or nil

  if is_non_empty_string(item.relative_path) then
    return join_under_base(base_path, item.relative_path)
  end

  if is_non_empty_string(item.name) then
    local relative_path = item.name
    if is_non_empty_string(item.directory) then
      relative_path = item.directory .. "/" .. item.name
    end
    return join_under_base(base_path, relative_path)
  end

  return nil
end

local function describe_item(item)
  if type(item) ~= "table" then
    return tostring(item)
  end

  local parts = {}
  for _, key in ipairs({ "path", "relative_path", "name", "directory", "line_number", "col", "line_content" }) do
    local value = item[key]
    if value ~= nil then
      if type(value) == "string" then
        parts[#parts + 1] = key .. "=" .. vim.inspect(value)
      else
        parts[#parts + 1] = key .. "=" .. tostring(value)
      end
    end
  end

  return #parts > 0 and table.concat(parts, ", ") or "no known fields"
end

local function patch_select_nil_path()
  local ok, picker_ui = pcall(require, "fff.picker_ui")
  if not ok or picker_ui._ponytail_nil_path_guard then
    return
  end

  local original_select = picker_ui.select
  if type(original_select) ~= "function" then
    return
  end

  picker_ui.select = function(action)
    if not picker_ui.state or not picker_ui.state.active then
      return original_select(action)
    end

    local items = picker_ui.state.filtered_items or {}
    local item = items[picker_ui.state.cursor]
    if item then
      item.path = resolve_item_path(picker_ui, item)
    end

    if item and item.path == nil then
      vim.notify("fff.nvim: current selection has no file path (" .. describe_item(item) .. ")", vim.log.levels.WARN)
      return
    end

    return original_select(action)
  end
  picker_ui._ponytail_nil_path_guard = true
end

function M.setup(opts)
  require("fff").setup(opts or {})
  patch_select_nil_path()
end

function M._selfcheck()
  local picker_ui = {
    state = {
      config = { base_path = "/tmp/fff-base" },
    },
  }

  assert(
    resolve_item_path(picker_ui, { path = nil, relative_path = "lua/test.lua", name = "test.lua" })
      == "/tmp/fff-base/lua/test.lua",
    "expected relative_path to resolve into item.path"
  )
  assert(
    resolve_item_path(picker_ui, { path = nil, directory = "lua", name = "test.lua" }) == "/tmp/fff-base/lua/test.lua",
    "expected directory and name to resolve into item.path"
  )
  assert(
    resolve_item_path(picker_ui, { path = "/tmp/already.lua", name = "already.lua" }) == "/tmp/already.lua",
    "expected existing path to win"
  )
end

return M
