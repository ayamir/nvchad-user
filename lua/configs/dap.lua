local function input_args()
  local argument_string = vim.fn.input("Program arg(s) (enter nothing to leave it null): ")
  return vim.fn.split(argument_string, " ", true)
end

local function input_exec_path()
  return vim.fn.input('Path to executable (default to "a.out"): ', vim.fn.expand("%:p:h") .. "/a.out", "file")
end

local function input_file_path()
  return vim.fn.input("Path to debuggee (default to the current file): ", vim.fn.expand("%:p"), "file")
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

return function()
  local dap = require("dap")
  local ok_dapui, dapui = pcall(require, "dapui")
  local ok_mason, mason_dap = pcall(require, "mason-nvim-dap")

  -- 配置 dap-ui 布局（来自 nvimdots，略微精简）
  if ok_dapui then
    dapui.setup({
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.3 },
            { id = "watches", size = 0.3 },
            { id = "stacks", size = 0.3 },
            { id = "breakpoints", size = 0.1 },
          },
          size = 0.3,
          position = "right",
        },
        {
          elements = {
            { id = "console", size = 0.55 },
            { id = "repl", size = 0.45 },
          },
          position = "bottom",
          size = 0.25,
        },
      },
      controls = {
        enabled = true,
        element = "repl",
      },
      floating = {
        border = "single",
        mappings = { close = { "q", "<Esc>" } },
      },
      render = { indent = 1, max_value_lines = 85 },
    })

    local debugging = false

    dap.listeners.after.event_initialized["dapui_config"] = function()
      debugging = true
      dapui.open({ reset = true })
    end

    local function on_terminate()
      if debugging then
        debugging = false
      end
    end

    dap.listeners.before.event_terminated["dapui_config"] = on_terminate
    dap.listeners.before.event_exited["dapui_config"] = on_terminate

    dap.listeners.before.disconnect["dapui_config"] = function()
      if debugging then
        debugging = false
        dapui.close()
      end
    end
  end

  -- 定义断点等符号（用简单字符替代 nvimdots 的图标）
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
  vim.fn.sign_define(
    "DapBreakpointCondition",
    { text = "◆", texthl = "DiagnosticSignWarn", linehl = "", numhl = "" }
  )
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticSignInfo", linehl = "", numhl = "" })
  vim.fn.sign_define(
    "DapBreakpointRejected",
    { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" }
  )
  vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticSignHint", linehl = "", numhl = "" })

  -- mason-nvim-dap 安装/管理调试适配器
  if ok_mason then
    mason_dap.setup({
      ensure_installed = { "codelldb", "python" },
      automatic_installation = false,
    })
  end

  -- C/C++/Rust 使用 codelldb（来自 nvimdots 的 codelldb.lua）
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = vim.fn.exepath("codelldb"),
      args = { "--port", "${port}" },
      detached = is_windows() and false or true,
    },
  }

  dap.configurations.c = {
    {
      name = "Debug",
      type = "codelldb",
      request = "launch",
      program = input_exec_path,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      terminal = "integrated",
    },
    {
      name = "Debug (with args)",
      type = "codelldb",
      request = "launch",
      program = input_exec_path,
      args = input_args,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      terminal = "integrated",
    },
    {
      name = "Attach to a running process",
      type = "codelldb",
      request = "attach",
      program = input_exec_path,
      stopOnEntry = false,
      waitFor = true,
    },
  }

  dap.configurations.cpp = dap.configurations.c
  dap.configurations.rust = dap.configurations.c

  -- Python 使用 debugpy（来自 nvimdots 的 python.lua，略微精简）
  local debugpy_root = vim.fn.expand("$MASON/packages/debugpy")

  dap.adapters.python = function(callback, config)
    if config.request == "attach" then
      local port = (config.connect or config).port
      local host = (config.connect or config).host or "127.0.0.1"
      callback({
        type = "server",
        port = assert(port, "`connect.port` is required for a python `attach` configuration"),
        host = host,
        options = { source_filetype = "python" },
      })
    else
      callback({
        type = "executable",
        command = is_windows() and debugpy_root .. "/venv/Scripts/pythonw.exe"
          or debugpy_root .. "/venv/bin/python",
        args = { "-m", "debugpy.adapter" },
        options = { source_filetype = "python" },
      })
    end
  end

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Debug",
      console = "integratedTerminal",
      program = input_file_path,
      pythonPath = function()
        local venv = vim.env.CONDA_PREFIX
        if venv then
          return is_windows() and venv .. "/Scripts/pythonw.exe" or venv .. "/bin/python"
        else
          return is_windows() and "pythonw.exe" or "python3"
        end
      end,
    },
    {
      type = "python",
      request = "launch",
      name = "Debug (using venv)",
      console = "integratedTerminal",
      program = input_file_path,
      pythonPath = function()
        local cwd = vim.uv.cwd()
        local venv = vim.env.VIRTUAL_ENV
        local python = venv and (is_windows() and venv .. "/Scripts/pythonw.exe" or venv .. "/bin/python") or ""
        if vim.fn.executable(python) == 1 then
          return python
        end

        venv = vim.fn.isdirectory(cwd .. "/venv") == 1 and cwd .. "/venv" or cwd .. "/.venv"
        python = is_windows() and venv .. "/Scripts/pythonw.exe" or venv .. "/bin/python"
        if vim.fn.executable(python) == 1 then
          return python
        else
          return is_windows() and "pythonw.exe" or "python3"
        end
      end,
    },
  }
end
