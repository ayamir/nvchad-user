require("nvchad.autocmds")

local autocmd = {}

local modules = {
  "autocmds.editor",
  "autocmds.session",
  "autocmds.filetypes",
  "autocmds.dap",
}

function autocmd.load_autocmds()
  for _, module_name in ipairs(modules) do
    require(module_name).setup()
  end
end

require("commands").setup()
autocmd.load_autocmds()

return autocmd
