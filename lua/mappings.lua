require("nvchad.mappings")

local bind = require("keymap.bind")
local term = require("keymap.term")
local map_cr = bind.map_cr
local map_cmd = bind.map_cmd
local map_callback = bind.map_callback

local function get_visual_selection()
  local save_reg = vim.fn.getreg("v") -- 备份 v 寄存器
  local save_type = vim.fn.getregtype("v")

  vim.cmd([[noau normal! "vy]]) -- 选区内容 -> v 寄存器
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", save_reg, save_type) -- 还原 v 寄存器

  text = text:gsub("\n", "") -- 去掉换行，防止搜索串断裂
  return #text > 0 and text or nil
end

local mappings = {
  -- NvChad 核心功能映射
  nvchad_core = {
    -- 文件树切换
    ["n|<C-n>"] = map_callback(function()
        require("edgy").toggle("left")
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Toggle filetree"),

    -- Buffer 管理
    ["n|<A-i>"] = map_callback(function()
        require("nvchad.tabufline").next()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Next buffer"),
    ["n|<A-o>"] = map_callback(function()
        require("nvchad.tabufline").prev()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Prev buffer"),
    ["n|<A-S-i>"] = map_callback(function()
        require("nvchad.tabufline").move_buf(1)
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Move buffer right"),
    ["n|<A-S-o>"] = map_callback(function()
        require("nvchad.tabufline").move_buf(-1)
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Move buffer left"),
    ["n|<A-q>"] = map_callback(function()
        require("nvchad.tabufline").close_buffer()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Close buffer"),
    ["n|<A-S-q>"] = map_callback(function()
        require("nvchad.tabufline").closeAllBufs(false)
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Close all buffers"),

    -- 终端管理
    ["nit|<C-\\>"] = map_callback(function()
        require("nvchad.term").toggle({ pos = "sp", id = "HorizontalTerm" })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Toggle horizontal term"),
    ["nit|<A-\\>"] = map_callback(function()
        require("nvchad.term").toggle({ pos = "vsp", id = "VerticalTerm" })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Toggle vertical term"),
    ["nt|<A-d>"] = map_callback(function()
        term.toggle_all_terms()
      end)
      :with_cmd()
      :with_noremap()
      :with_silent()
      :with_desc("Toggle floating term"),
    ["t|<C-i>"] = map_callback(function()
        term.move_term(1)
      end)
      :with_noremap()
      :with_silent(),
    ["t|<C-o>"] = map_callback(function()
        term.move_term(-1)
      end)
      :with_noremap()
      :with_silent(),

    -- LSP 快速操作
    ["n|<leader>lr"] = map_cr("LspStart"):with_noremap():with_silent():with_desc("Start LSP"),
    ["n|<leader>li"] = map_cr("LspInfo"):with_noremap():with_silent():with_desc("LSP info"),
    ["n|K"] = map_cr("EagleWin"):with_noremap():with_silent():with_desc("Eagle window"),
  },

  -- 窗口与分屏管理
  window_management = {
    -- 窗口大小调整
    ["n|<A-h>"] = map_cr("SmartResizeLeft"):with_noremap():with_silent():with_desc("Resize window left"),
    ["n|<A-l>"] = map_cr("SmartResizeRight"):with_noremap():with_silent():with_desc("Resize window right"),
    ["n|<A-j>"] = map_cr("SmartResizeDown"):with_noremap():with_silent():with_desc("Resize window down"),
    ["n|<A-k>"] = map_cr("SmartResizeUp"):with_noremap():with_silent():with_desc("Resize window up"),

    -- 窗口间移动
    ["t|<C-w>h"] = map_cmd("wincmd h")
      :with_cmd()
      :with_noremap()
      :with_silent()
      :with_desc("Move to left window (terminal)"),
    ["t|<C-w>l"] = map_cmd("wincmd l")
      :with_cmd()
      :with_noremap()
      :with_silent()
      :with_desc("Move to right window (terminal)"),
    ["t|<C-w>j"] = map_cmd("wincmd j")
      :with_cmd()
      :with_noremap()
      :with_silent()
      :with_desc("Move to lower window (terminal)"),
    ["t|<C-w>k"] = map_cmd("wincmd k")
      :with_cmd()
      :with_noremap()
      :with_silent()
      :with_desc("Move to upper window (terminal)"),

    -- 智能光标移动
    ["n|<C-h>"] = map_cr("SmartCursorMoveLeft"):with_noremap():with_silent():with_desc("Smart cursor left"),
    ["n|<C-l>"] = map_cr("SmartCursorMoveRight"):with_noremap():with_silent():with_desc("Smart cursor right"),
    ["n|<C-j>"] = map_cr("SmartCursorMoveDown"):with_noremap():with_silent():with_desc("Smart cursor down"),
    ["n|<C-k>"] = map_cr("SmartCursorMoveUp"):with_noremap():with_silent():with_desc("Smart cursor up"),
  },

  -- 编辑操作优化
  edit_operations = {
    -- 可视化模式增强
    ["v|J"] = map_cmd(":m '>+1<CR>gv=gv"):with_noremap():with_silent():with_desc("Move line down (visual)"),
    ["v|K"] = map_cmd(":m '<-2<CR>gv=gv"):with_noremap():with_silent():with_desc("Move line up (visual)"),
    ["v|<"] = map_cmd("<gv"):with_noremap():with_silent():with_desc("Indent left (visual)"),
    ["v|>"] = map_cmd(">gv"):with_noremap():with_silent():with_desc("Indent right (visual)"),

    -- 行操作增强
    ["n|Y"] = map_cmd("y$"):with_noremap():with_silent():with_desc("Yank to line end"),
    ["n|D"] = map_cmd("d$"):with_noremap():with_silent():with_desc("Delete to line end"),
    ["n|J"] = map_cmd("mzJ`z"):with_noremap():with_silent():with_desc("Join lines"),

    -- 搜索结果居中
    ["n|n"] = map_cmd("nzzzv"):with_noremap():with_silent():with_desc("Next search result (center)"),
    ["n|N"] = map_cmd("Nzzzv"):with_noremap():with_silent():with_desc("Prev search result (center)"),
  },

  -- 插件映射：快速跳转
  plugin_jump = {
    -- Hop.nvim 快速跳转
    ["n|<leader>w"] = map_cr("HopWordMW"):with_noremap():with_silent():with_desc("Hop to word"),
    ["n|<leader>j"] = map_cr("HopLineMW"):with_noremap():with_silent():with_desc("Hop to line (down)"),
    ["n|<leader>k"] = map_cr("HopLineMW"):with_noremap():with_silent():with_desc("Hop to line (up)"),

    -- Spider.nvim 智能单词跳转
    ["nox|w"] = map_callback(function()
        require("spider").motion("w")
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Spider: Next word"),
    ["nox|e"] = map_callback(function()
        require("spider").motion("e")
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Spider: End of word"),
    ["nox|b"] = map_callback(function()
        require("spider").motion("b")
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Spider: Prev word"),

    -- Treesitter 节点选择
    ["o|m"] = map_callback(function()
        require("tsht").nodes()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("TS: Select node"),
  },

  -- 插件映射：Git 功能
  plugin_git = {
    -- 代码变更导航
    ["n|]g"] = map_callback(function()
        if vim.wo.diff then
          return "]g"
        end
        vim.schedule(function()
          require("gitsigns").nav_hunk("next")
        end)
        return "<Ignore>"
      end)
      :with_noremap()
      :with_silent()
      :with_expr()
      :with_desc("Next git hunk"),

    ["n|[g"] = map_callback(function()
        if vim.wo.diff then
          return "[g"
        end
        vim.schedule(function()
          require("gitsigns").nav_hunk("prev")
        end)
        return "<Ignore>"
      end)
      :with_noremap()
      :with_silent()
      :with_expr()
      :with_desc("Prev git hunk"),

    ["n|<leader>fg"] = map_callback(function()
        require("telescope").extensions.advanced_git_search.search_log_content()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("[g]it log search"),

    ["nv|<leader>fd"] = map_callback(function()
        require("telescope").extensions.advanced_git_search.diff_commit_file()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("[d]iff git commit file search"),

    ["n|<leader>gf"] = map_cr("DiffviewFileHistory"):with_noremap():with_silent():with_desc("Diffview file history"),
    ["n|<leader>gd"] = map_cr("DiffviewOpen"):with_noremap():with_silent():with_desc("Diffview open"),
    ["n|<leader>gD"] = map_cr("DiffviewClose"):with_noremap():with_silent():with_desc("Diffview close"),

    -- 代码变更操作
    ["n|<leader>gs"] = map_callback(function()
        require("gitsigns").stage_hunk()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Stage git hunk"),
    ["v|<leader>gs"] = map_callback(function()
        require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Stage git hunk (visual)"),
    ["n|<leader>gr"] = map_callback(function()
        require("gitsigns").reset_hunk()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Reset git hunk"),
    ["v|<leader>gr"] = map_callback(function()
        require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Reset git hunk (visual)"),
    ["n|<leader>gR"] = map_callback(function()
        require("gitsigns").reset_buffer()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Reset git buffer"),
    ["n|<leader>gp"] = map_callback(function()
        require("gitsigns").preview_hunk()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Preview git hunk"),
    ["n|<leader>gb"] = map_callback(function()
        require("gitsigns").blame_line({ full = true })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Git blame"),
  },

  -- 插件映射：测试功能
  plugin_test = {
    ["n|<leader>tc"] = map_callback(function()
        require("neotest").run.run()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Run nearest test"),
    ["n|<leader>tf"] = map_callback(function()
        require("neotest").run.run(vim.fn.expand("%"))
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Run file tests"),
    ["n|<leader>td"] = map_callback(function()
        require("neotest").run.run({ strategy = "dap" })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug nearest test"),
    ["n|<leader>tl"] = map_callback(function()
        require("neotest").run.run_last()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Run last test"),
    ["n|<leader>to"] = map_cr("Neotest output-panel"):with_noremap():with_silent():with_desc("Toggle test output"),
  },

  -- 插件映射：调试功能（来自 nvimdots，做了少量适配）
  plugin_debug = {
    ["n|<F6>"] = map_callback(function()
        require("dap").continue()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Run/Continue"),
    ["n|<F7>"] = map_callback(function()
        require("dap").terminate()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Stop"),
    ["n|<F8>"] = map_callback(function()
        require("dap").toggle_breakpoint()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Toggle breakpoint"),
    ["n|<F9>"] = map_callback(function()
        require("dap").step_into()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Step into"),
    ["n|<F10>"] = map_callback(function()
        require("dap").step_out()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Step out"),
    ["n|<F11>"] = map_callback(function()
        require("dap").step_over()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Step over"),
    ["n|<F12>"] = map_callback(function()
        require("dap").step_over()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Step over (next line)"),
    ["n|<leader>db"] = map_callback(function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Conditional breakpoint"),
    ["n|<leader>dc"] = map_callback(function()
        require("dap").run_to_cursor()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Run to cursor"),
    ["n|<leader>dl"] = map_callback(function()
        require("dap").run_last()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Run last"),
    ["n|<leader>do"] = map_callback(function()
        require("dap").repl.open()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Open REPL"),
    ["n|<leader>du"] = map_callback(function()
        require("dapui").close()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Close DAP UI"),
    ["n|<leader>de"] = map_callback(function()
        require("dapui").eval()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Debug: Evaluate expression"),
  },

  -- 插件映射：书签功能
  plugin_bookmarks = {
    ["n|mx"] = map_cr("BookmarksMark"):with_noremap():with_silent():with_desc("Add bookmark"),
    ["n|mq"] = map_cr("BookmarksQuickMark"):with_noremap():with_silent():with_desc("Quick bookmark"),
    ["n|mj"] = map_cr("BookmarksGotoNext"):with_noremap():with_silent():with_desc("Next bookmark"),
    ["n|mk"] = map_cr("BookmarksGotoPrev"):with_noremap():with_silent():with_desc("Prev bookmark"),
    ["n|mo"] = map_cr("BookmarksGoto"):with_noremap():with_silent():with_desc("Goto bookmark"),
  },

  -- 插件映射：搜索工具
  plugin_search = {
    ["v|<leader>fs"] = map_callback(function()
        local text = get_visual_selection()
        if not text then
          return
        end
        require("telescope.builtin").grep_string({ search = text })
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Grep selection"),
    ["n|<leader>fs"] = map_cr("Telescope grep_string"):with_noremap():with_silent():with_desc("Grep cword"),
    ["n|<leader>fr"] = map_cr("Telescope resume"):with_noremap():with_silent():with_desc("Resume Telescope"),
    ["n|<leader>fm"] = map_cr("Telescope notify"):with_noremap():with_silent():with_desc("Notify history"),
    ["n|<leader>fR"] = map_cr("FzfLua resume"):with_noremap():with_silent():with_desc("Resume FzfLua"),
    ["n|<leader>s"] = map_cr("GrugFar"):with_noremap():with_silent():with_desc("Grep/replace (GrugFar)"),
  },

  plugin_pack = {
    ["n|<leader>ph"] = map_cr("Lazy"):with_silent():with_noremap():with_nowait():with_desc("package: Show"),
    ["n|<leader>ps"] = map_cr("Lazy sync"):with_silent():with_noremap():with_nowait():with_desc("package: Sync"),
    ["n|<leader>pu"] = map_cr("Lazy update"):with_silent():with_noremap():with_nowait():with_desc("package: Update"),
    ["n|<leader>pi"] = map_cr("Lazy install"):with_silent():with_noremap():with_nowait():with_desc("package: Install"),
    ["n|<leader>pl"] = map_cr("Lazy log"):with_silent():with_noremap():with_nowait():with_desc("package: Log"),
    ["n|<leader>pc"] = map_cr("Lazy check"):with_silent():with_noremap():with_nowait():with_desc("package: Check"),
    ["n|<leader>pd"] = map_cr("Lazy debug"):with_silent():with_noremap():with_nowait():with_desc("package: Debug"),
    ["n|<leader>pp"] = map_cr("Lazy profile"):with_silent():with_noremap():with_nowait():with_desc("package: Profile"),
    ["n|<leader>pr"] = map_cr("Lazy restore"):with_silent():with_noremap():with_nowait():with_desc("package: Restore"),
    ["n|<leader>px"] = map_cr("Lazy clean"):with_silent():with_noremap():with_nowait():with_desc("package: Clean"),
  },

  -- 其他功能映射
  plugin_lsputils = {
    ["n|<leader>e"] = map_cr("e"):with_noremap():with_silent():with_desc("Refresh LSP symbols"),
    -- 切换保存时自动格式化
    ["n|<A-f>"] = map_cr("FormatToggle"):with_noremap():with_silent():with_desc("Toggle format on save"),
    -- 手动格式化当前缓冲区
    ["n|<A-S-f>"] = map_cr("Format"):with_noremap():with_silent():with_desc("Format buffer"),
  },
}

-- Goto buffer with <A-number>
for i = 1, 9, 1 do
  mappings.nvchad_core[string.format("n|<A-%s>", i)] = map_callback(function()
      vim.api.nvim_set_current_buf(vim.t.bufs[i])
    end)
    :with_noremap()
    :with_silent()
    :with_desc("buffer: Goto buffer " .. tostring(i))
end

-- 加载所有映射
for _, mapping in pairs(mappings) do
  bind.nvim_load_mapping(mapping)
end

return mappings
