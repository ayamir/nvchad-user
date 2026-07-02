local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = require("utils.autocmd").create_augroup

local M = {}

local GO_FILETYPES = {
  go = true,
  gomod = true,
  gosum = true,
  gowork = true,
  gotmpl = true,
  gohtmltmpl = true,
  gotexttmpl = true,
}

local function force_italic(group)
  local ok, current = pcall(api.nvim_get_hl, 0, { name = group, link = false })
  local next_hl = { bold = true, italic = true, cterm = { italic = true } }

  if ok and type(current) == "table" then
    next_hl = vim.tbl_extend("force", current, next_hl)
  end

  api.nvim_set_hl(0, group, next_hl)
end

local function patch_go_keyword_italics()
  -- ponytail: base46 hl_override only merges groups it already knows, so
  -- keep the actual Go treesitter keyword groups italic here.
  local groups = {
    "@keyword.function",
    "@keyword.type",
    "@keyword.function.go",
    "@keyword.type.go",
  }

  for _, group in ipairs(groups) do
    force_italic(group)
  end
end

local function patch_go_keyword_italics_later()
  vim.schedule(patch_go_keyword_italics)
end

local function disable_go_semantic_tokens(bufnr)
  if not vim.lsp.semantic_tokens then
    return
  end

  if vim.lsp.semantic_tokens.enable then
    vim.lsp.semantic_tokens.enable(false, { bufnr = bufnr })
  elseif vim.lsp.semantic_tokens.stop then
    vim.lsp.semantic_tokens.stop(bufnr)
  end
end

function M.setup()
  create_autocmd("User", {
    group = create_augroup("HighlightPatches"),
    pattern = "NvThemeReload",
    callback = patch_go_keyword_italics_later,
  })

  create_autocmd("FileType", {
    group = create_augroup("GoKeywordItalicPatches"),
    pattern = { "go", "gomod", "gosum", "gowork", "gotmpl", "gohtmltmpl", "gotexttmpl" },
    callback = patch_go_keyword_italics_later,
  })

  create_autocmd("LspAttach", {
    group = create_augroup("GoKeywordItalicPatches"),
    callback = function(args)
      if GO_FILETYPES[vim.bo[args.buf].filetype] then
        disable_go_semantic_tokens(args.buf)
        patch_go_keyword_italics_later()
      end
    end,
  })

  patch_go_keyword_italics()
end

return M
