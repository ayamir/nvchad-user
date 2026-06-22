# Snacks Full Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current overlapping FzfLua, Telescope, nvim-tree, nvim-notify, dressing, toggleterm, sidekick, project picker, and related NvChad integration points with `folke/snacks.nvim` where Snacks provides an equivalent feature.

**Architecture:** Add one focused Snacks plugin config, then move callers to `Snacks.picker`, `Snacks.explorer`, `Snacks.notifier`, `Snacks.input`, and `Snacks.terminal`. Remove user-layer plugin specs and config files that only exist for replaced features; override NvChad default plugins with `enabled = false` only after all runtime references are gone.

**Tech Stack:** Neovim Lua, NvChad v2.5 as a lazy.nvim plugin, lazy.nvim plugin specs, `folke/snacks.nvim`, StyLua.

## Global Constraints

- This repository is an NvChad user layer; prefer extending existing config shape over creating a parallel framework.
- All custom keymaps remain in `lua/mappings.lua` and should use the existing `map_callback` / `map_cr` helper style unless a plugin spec `keys` entry is already the natural location.
- Lua formatting is managed by StyLua; run `stylua lua/` before final verification.
- Do not remove core editing plugins that Snacks does not replace: `gitsigns.nvim`, `trouble.nvim`, `lspsaga.nvim`, `conform.nvim`, `nvim-lspconfig`, `mason`, `blink.cmp`, `nvim-treesitter`, `grug-far.nvim`, `edgy.nvim`, `persisted.nvim`, `bookmarks.nvim`, `diffview.nvim`.
- The user no longer needs `sidekick.nvim`; remove Sidekick plugin config, mappings, completion fallback, and statusline module.
- The final result must have no runtime references to `fzf-lua`, `telescope`, `nvim-tree`, `toggleterm`, `nvim-notify`, `dressing`, `fff`, `project.nvim`, `advanced-git-search`, or `sidekick` in user config unless the plan explicitly marks an external plugin dependency as retained.
- NvChad default plugins can be disabled from the user plugin layer with lazy.nvim specs using the same plugin name and `enabled = false`.

---

## File Structure

- Create `lua/configs/snacks.lua`: single setup-returning config for Snacks modules and styles. Owns `picker`, `explorer`, `input`, `notifier`, `terminal`, `dashboard`, `indent`, `bigfile`, `quickfile`, `words`, and optional `lazygit/gitbrowse` module options.
- Modify `lua/plugins/init.lua`: add `folke/snacks.nvim`; remove replaced user plugins; add `enabled = false` overrides for NvChad default plugins that are fully replaced; remove Sidekick and Telescope-dependent extension specs.
- Modify `lua/mappings.lua`: replace FzfLua/Telescope/fff picker maps with Snacks; replace nvim-tree maps with Snacks explorer maps; remove Sidekick maps; keep gitsigns, diffview, trouble, lspsaga, bookmarks, grug-far maps.
- Modify `lua/configs/lspconfig.lua`: replace FzfLua LSP pickers with Snacks LSP pickers and remove Telescope prompt/fzf options.
- Modify `lua/keymap/term.lua`: remove ToggleTerm object model and Telescope picker; reimplement the three zellij terminal slots using `Snacks.terminal` while preserving existing `<A-i>`, `<A-j>`, `<A-k>` behavior from `lua/mappings.lua`.
- Modify `lua/chadrc.lua`: remove Sidekick statusline module, remove `telescope`, `notify`, and `blankline` Base46 integrations, disable NvDash when Snacks dashboard is enabled.
- Modify `lua/configs/edgy.lua`: replace `NvimTree` and `toggleterm` layout rules with `snacks_explorer` / `snacks_terminal` rules where possible; keep Trouble/help/qf rules.
- Modify `lua/autocmds/session.lua`, `lua/autocmds/filetypes.lua`, `lua/configs/tiny-inline-diagnostic.lua`, `lua/configs/splits.lua`, `lua/utils/file_ref.lua`: update transient/special filetype names from old plugins to Snacks equivalents.
- Delete `lua/configs/fzf-lua.lua`, `lua/configs/project.lua`, `lua/configs/toggleterm.lua` when their specs are removed.
- Keep `lua/configs/diffview.lua` and `diffview.nvim`; remove `advanced-git-search.nvim` only, because it is a Telescope extension but Diffview is directly mapped.

---

### Task 1: Add Snacks as the replacement foundation

**Files:**
- Create: `lua/configs/snacks.lua`
- Modify: `lua/plugins/init.lua`
- Test: Headless Neovim load and `:checkhealth snacks`

**Interfaces:**
- Consumes: lazy.nvim plugin spec conventions from `lua/plugins/init.lua`.
- Produces: global `Snacks` table and modules used later: `Snacks.picker`, `Snacks.explorer`, `Snacks.notifier`, `Snacks.input`, `Snacks.terminal`, `Snacks.dashboard`, `Snacks.indent`, `Snacks.words`.

- [ ] **Step 1: Create the Snacks config file**

Create `lua/configs/snacks.lua` with this exact content:

```lua
return {
  bigfile = { enabled = true },
  dashboard = { enabled = true },
  explorer = {
    enabled = true,
    replace_netrw = true,
  },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 1000,
    style = "compact",
    width = { min = 50, max = 0.4 },
  },
  picker = {
    enabled = true,
    ui_select = true,
    layout = {
      preset = function()
        return vim.o.columns >= 120 and "default" or "vertical"
      end,
    },
    matcher = {
      fuzzy = true,
      smartcase = true,
      ignorecase = true,
      filename_bonus = true,
      frecency = true,
      history_bonus = true,
    },
    sources = {
      explorer = {
        layout = { preset = "sidebar", preview = false },
      },
    },
  },
  quickfile = { enabled = true },
  terminal = {
    enabled = true,
    win = { style = "terminal" },
  },
  words = { enabled = true },
  styles = {
    terminal = {
      position = "float",
      relative = "editor",
      row = 0.1,
      col = 0.1,
      width = 0.8,
      height = 0.8,
      border = "single",
      wo = { number = false, relativenumber = false },
    },
  },
}
```

- [ ] **Step 2: Add the Snacks plugin spec**

In `lua/plugins/init.lua`, insert this spec near the top after `local helpers = require("utils.helpers")` and before existing plugin specs that may use UI modules:

```lua
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = require("configs.snacks"),
  },
```

The beginning of the file should look like this:

```lua
local helpers = require("utils.helpers")

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = require("configs.snacks"),
  },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require("configs.conform"),
  },
```

- [ ] **Step 3: Run the first load check**

Run:

```bash
nvim --headless -u init.lua '+lua assert(Snacks ~= nil, "Snacks did not load")' '+checkhealth snacks' +qa
```

Expected: exit code `0`. Health output may include optional tool warnings, but there must be no Lua error and no missing `Snacks` assertion.

- [ ] **Step 4: Format and commit foundation**

Run:

```bash
stylua lua/plugins/init.lua lua/configs/snacks.lua
git add lua/plugins/init.lua lua/configs/snacks.lua
git commit -m "feat: add snacks foundation"
```

Expected: commit succeeds.

---

### Task 2: Replace all picker mappings and LSP pickers with Snacks

**Files:**
- Modify: `lua/mappings.lua:428-470`
- Modify: `lua/configs/lspconfig.lua:1-60`
- Delete after specs are removed in Task 6: `lua/configs/fzf-lua.lua`
- Test: headless load plus grep for old picker calls

**Interfaces:**
- Consumes: `Snacks.picker` from Task 1.
- Produces: search and LSP keymaps that no longer require FzfLua, Telescope, fff.nvim, or telescope-frecency.

- [ ] **Step 1: Replace the `plugin_search` mapping table**

In `lua/mappings.lua`, replace the whole `plugin_search = { ... }` block with:

```lua
  -- 插件映射：搜索工具
  plugin_search = {
    ["v|<leader>fs"] = map_callback(function()
        Snacks.picker.grep_word()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Grep selection"),
    ["n|<leader>fs"] = map_callback(function()
        Snacks.picker.grep_word()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Grep cword"),
    ["n|<leader>fr"] = map_callback(function()
        Snacks.picker.resume()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Resume picker"),
    ["n|<leader>fm"] = map_callback(function()
        Snacks.notifier.show_history()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Notify history"),
    ["n|<leader>s"] = map_cr("GrugFar"):with_noremap():with_silent():with_desc("Grep/replace (GrugFar)"),
    ["n|<leader>ff"] = map_callback(function()
        local ok = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
        if vim.trim(ok) == "true" then
          Snacks.picker.git_files()
        else
          Snacks.picker.files()
        end
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Find files (git_files / files)"),
    ["n|<leader>fw"] = map_callback(function()
        Snacks.picker.grep()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Live grep"),
    ["n|<leader>fb"] = map_callback(function()
        Snacks.picker.buffers()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Find buffers"),
    ["n|<leader>fo"] = map_callback(function()
        Snacks.picker.recent()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Find oldfiles"),
    ["n|<leader>fc"] = map_callback(function()
        Snacks.picker.smart()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Find files (smart)"),
    ["n|<leader>fz"] = map_callback(function()
        Snacks.picker.lines()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Fuzzy current buffer"),
    ["n|<leader>cm"] = map_callback(function()
        Snacks.picker.git_log()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Git commits"),
    ["n|<leader>gt"] = map_callback(function()
        Snacks.picker.git_status()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Git status"),
    ["n|<leader>ma"] = map_callback(function()
        Snacks.picker.marks()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Find marks"),
  },
```

This intentionally removes duplicate `<leader>fR`; `<leader>fr` becomes the single resume mapping.

- [ ] **Step 2: Replace LSP picker callbacks**

In `lua/configs/lspconfig.lua`, delete these two top-level locals:

```lua
local prompt_position = require("telescope.config").values.layout_config.horizontal.prompt_position
local fzf_opts = { ["--layout"] = prompt_position == "top" and "reverse" or "default" }
```

Then replace the three FzfLua callbacks in `on_attach` with:

```lua
  map("n", "gp", function()
    Snacks.picker.lsp_symbols()
  end, opts())
```

```lua
  map("n", "gh", function()
    Snacks.picker.lsp_references()
  end, opts())
```

```lua
  map("n", "gm", function()
    Snacks.picker.lsp_implementations()
  end, opts())
```

- [ ] **Step 3: Run picker reference checks**

Run:

```bash
rg -n "FzfLua|fzf-lua|Telescope|telescope|fff|telescope-frecency|telescope-fzf" lua/mappings.lua lua/configs/lspconfig.lua lua/configs/fzf-lua.lua lua/plugins/init.lua
```

Expected after this task: matches still exist in `lua/plugins/init.lua` and `lua/configs/fzf-lua.lua`, but no matches in `lua/mappings.lua` or `lua/configs/lspconfig.lua`.

- [ ] **Step 4: Run load checks**

Run:

```bash
stylua lua/mappings.lua lua/configs/lspconfig.lua
nvim --headless -u init.lua '+lua require("mappings"); require("configs.lspconfig")' +qa
```

Expected: exit code `0`.

- [ ] **Step 5: Commit picker migration**

Run:

```bash
git add lua/mappings.lua lua/configs/lspconfig.lua
git commit -m "feat: move picker mappings to snacks"
```

Expected: commit succeeds.

---

### Task 3: Remove Sidekick completely

**Files:**
- Modify: `lua/plugins/init.lua:23-70,722-758`
- Modify: `lua/mappings.lua:492-534`
- Modify: `lua/chadrc.lua:7-35,100-106`
- Test: grep and headless load

**Interfaces:**
- Consumes: user decision that Sidekick is no longer needed.
- Produces: no user config requires `sidekick`.

- [ ] **Step 1: Remove Sidekick completion fallback**

In `lua/plugins/init.lua`, inside the `saghen/blink.cmp` opts function, replace this keymap list:

```lua
      opts.keymap["<Tab>"] = {
        "select_next",
        "snippet_forward",
        function()
          return require("sidekick").nes_jump_or_apply()
        end,
        function()
          return vim.lsp.inline_completion and vim.lsp.inline_completion.get and vim.lsp.inline_completion.get()
        end,
        "fallback",
      }
```

with:

```lua
      opts.keymap["<Tab>"] = {
        "select_next",
        "snippet_forward",
        function()
          return vim.lsp.inline_completion and vim.lsp.inline_completion.get and vim.lsp.inline_completion.get()
        end,
        "fallback",
      }
```

- [ ] **Step 2: Delete the Sidekick plugin spec**

In `lua/plugins/init.lua`, remove the whole spec beginning with:

```lua
  {
    "folke/sidekick.nvim",
```

and ending at its matching `},` after the `tools` table.

- [ ] **Step 3: Delete Sidekick keymaps**

In `lua/mappings.lua`, delete the whole `plugin_sidekick = { ... },` table.

- [ ] **Step 4: Remove Sidekick statusline code**

In `lua/chadrc.lua`, delete the whole `local function sidekick_statusline()` function near the top.

Then replace the current statusline config:

```lua
  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "sidekick", "%=", "diagnostics", "lsp", "cwd", "cursor" },
    modules = {
      sidekick = sidekick_statusline,
    },
  },
```

with:

```lua
  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor" },
  },
```

- [ ] **Step 5: Verify Sidekick is gone**

Run:

```bash
rg -n "sidekick|Sidekick" lua
stylua lua/plugins/init.lua lua/mappings.lua lua/chadrc.lua
nvim --headless -u init.lua '+lua require("mappings"); require("chadrc")' +qa
```

Expected: `rg` prints no matches; Neovim exits `0`.

- [ ] **Step 6: Commit Sidekick removal**

Run:

```bash
git add lua/plugins/init.lua lua/mappings.lua lua/chadrc.lua
git commit -m "refactor: remove sidekick integration"
```

Expected: commit succeeds.

---

### Task 4: Remove replaced picker plugins and Telescope extension dependencies

**Files:**
- Modify: `lua/plugins/init.lua`
- Delete: `lua/configs/fzf-lua.lua`
- Delete: `lua/configs/project.lua`
- Test: grep for removed picker plugins

**Interfaces:**
- Consumes: Snacks picker mappings from Task 2.
- Produces: no FzfLua, Telescope, fff.nvim, telescope-fzf-native, telescope-frecency, project.nvim, or advanced-git-search plugin specs in user config.

- [ ] **Step 1: Remove the user Telescope spec**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "nvim-telescope/telescope.nvim",
```

and ending after `telescope.load_extension("frecency")`.

- [ ] **Step 2: Remove FzfLua spec**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "ibhagwan/fzf-lua",
```

- [ ] **Step 3: Remove project.nvim spec**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "DrKJeff16/project.nvim",
```

The replacement is `Snacks.picker.projects()` if a project picker mapping is later desired. No mapping currently exists, so do not add one unless requested.

- [ ] **Step 4: Remove advanced-git-search spec but keep Diffview**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "aaronhallaert/advanced-git-search.nvim",
```

Then add a standalone Diffview spec in the same area:

```lua
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    config = require("configs.diffview"),
  },
```

This keeps existing `<leader>gd`, `<leader>gD`, and `<leader>gf` mappings working.

- [ ] **Step 5: Remove fff.nvim spec**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "dmtrKovalenko/fff.nvim",
```

- [ ] **Step 6: Delete obsolete config files**

Run:

```bash
rm lua/configs/fzf-lua.lua lua/configs/project.lua
```

- [ ] **Step 7: Add lazy.nvim overrides for NvChad default Telescope**

In `lua/plugins/init.lua`, add this spec near the top after the Snacks spec:

```lua
  { "nvim-telescope/telescope.nvim", enabled = false },
```

Do not disable `nvim-tree/nvim-web-devicons`; Snacks can use devicons and other plugins still depend on it.

- [ ] **Step 8: Verify picker plugin references are gone**

Run:

```bash
rg -n "fzf-lua|FzfLua|telescope|Telescope|fff|project.nvim|advanced-git-search|telescope-fzf|telescope-frecency" lua
```

Expected: no matches except comments you intentionally kept. If matches appear in `helix/config.toml`, ignore them because this task checks only `lua`.

- [ ] **Step 9: Load and commit**

Run:

```bash
stylua lua/plugins/init.lua
nvim --headless -u init.lua '+lua require("mappings")' +qa
git add lua/plugins/init.lua lua/configs/fzf-lua.lua lua/configs/project.lua
git add -u lua/configs
git commit -m "refactor: remove replaced picker plugins"
```

Expected: Neovim exits `0`; commit succeeds.

---

### Task 5: Replace notification and input/select UI plugins

**Files:**
- Modify: `lua/plugins/init.lua`
- Modify: `lua/chadrc.lua`
- Modify: `lua/configs/tiny-inline-diagnostic.lua`
- Modify: `lua/autocmds/filetypes.lua`
- Modify: `lua/utils/file_ref.lua`
- Test: headless notification call and grep

**Interfaces:**
- Consumes: `Snacks.notifier`, `Snacks.input`, and `picker.ui_select = true` from Task 1.
- Produces: `vim.notify`, notification history, `vim.ui.input`, and `vim.ui.select` handled by Snacks.

- [ ] **Step 1: Delete dressing.nvim spec**

In `lua/plugins/init.lua`, remove this whole spec:

```lua
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      select = {
        backend = { "telescope", "builtin" },
      },
    },
  },
```

- [ ] **Step 2: Delete nvim-notify spec**

In `lua/plugins/init.lua`, remove the whole spec beginning with:

```lua
  {
    "rcarriga/nvim-notify",
```

- [ ] **Step 3: Remove nvim-notify from Noice dependencies**

In the `folke/noice.nvim` spec, replace:

```lua
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
```

with:

```lua
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
```

- [ ] **Step 4: Remove notify Base46 integration**

In `lua/chadrc.lua`, delete this entry from `M.base46.integrations`:

```lua
    "notify",
```

- [ ] **Step 5: Update filetype exclusions**

In `lua/configs/tiny-inline-diagnostic.lua`, replace:

```lua
      "notify",
```

with:

```lua
      "snacks_notif",
      "snacks_notif_history",
```

In `lua/autocmds/filetypes.lua`, replace the `"notify",` entry in `CLOSE_WITH_Q_FILETYPES` with:

```lua
  "snacks_notif_history",
```

Do not add `snacks_notif`; transient notification windows should be managed by Snacks.

In `lua/utils/file_ref.lua`, replace:

```lua
  notify = true,
```

with:

```lua
  snacks_notif = true,
  snacks_notif_history = true,
```

- [ ] **Step 6: Verify notification/input replacement**

Run:

```bash
rg -n "dressing|nvim-notify|require\(\"notify\"\)|notify = true|\"notify\"" lua
nvim --headless -u init.lua '+lua vim.notify("snacks notify smoke", vim.log.levels.INFO); assert(vim.ui.input ~= nil); assert(vim.ui.select ~= nil)' +qa
```

Expected: no old notification/dressing plugin references; Neovim exits `0`.

- [ ] **Step 7: Commit UI replacement**

Run:

```bash
stylua lua/plugins/init.lua lua/chadrc.lua lua/configs/tiny-inline-diagnostic.lua lua/autocmds/filetypes.lua lua/utils/file_ref.lua
git add lua/plugins/init.lua lua/chadrc.lua lua/configs/tiny-inline-diagnostic.lua lua/autocmds/filetypes.lua lua/utils/file_ref.lua
git commit -m "refactor: use snacks for notifications and input"
```

Expected: commit succeeds.

---

### Task 6: Replace nvim-tree with Snacks explorer

**Files:**
- Modify: `lua/plugins/init.lua`
- Modify: `lua/mappings.lua`
- Modify: `lua/autocmds/session.lua`
- Modify: `lua/configs/edgy.lua`
- Modify: `lua/configs/tiny-inline-diagnostic.lua`
- Modify: `lua/configs/splits.lua`
- Modify: `lua/utils/file_ref.lua`
- Test: grep for `NvimTree` and open explorer headlessly

**Interfaces:**
- Consumes: `Snacks.explorer.open(opts)` and `Snacks.explorer.reveal(opts)`.
- Produces: file explorer actions without `nvim-tree.lua`.

- [ ] **Step 1: Remove user nvim-tree customization spec**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "nvim-tree/nvim-tree.lua",
```

This also deletes the custom Telescope-based floating preview implementation. Snacks explorer has built-in preview toggle `P`.

- [ ] **Step 2: Disable NvChad default nvim-tree**

In `lua/plugins/init.lua`, add this spec near other disabled NvChad defaults:

```lua
  { "nvim-tree/nvim-tree.lua", enabled = false },
```

- [ ] **Step 3: Add explorer mappings**

In `lua/mappings.lua`, add a new table near `plugin_search`:

```lua
  plugin_explorer = {
    ["n|<leader>e"] = map_callback(function()
        Snacks.explorer.open()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Explorer"),
    ["n|<leader>E"] = map_callback(function()
        Snacks.explorer.reveal()
      end)
      :with_noremap()
      :with_silent()
      :with_desc("Explorer reveal file"),
  },
```

If `<leader>e` already exists in `plugin_lsputils` as `map_cr("e")`, remove that old entry because it is not a meaningful LSP refresh command.

- [ ] **Step 4: Update session cleanup filetypes**

In `lua/autocmds/session.lua`, replace `"NvimTree",` in `TRANSIENT_SESSION_FILETYPES` with:

```lua
  "snacks_picker",
  "snacks_picker_list",
  "snacks_picker_input",
  "snacks_picker_preview",
```

Then delete the entire `maybe_close_nvim_tree()` function and the `BufEnter` autocmd with group `NvimTreeAutoClose`. Snacks explorer is a picker and does not need that special last-window quit rule.

- [ ] **Step 5: Update Edgy explorer rule**

In `lua/configs/edgy.lua`, replace the left-side `NvimTree` block:

```lua
      {
        ft = "NvimTree",
        pinned = true,
        collapsed = false,
        size = { height = 0.6, width = 0.15 },
        open = "NvimTreeOpen",
      },
```

with:

```lua
      {
        ft = "snacks_picker_list",
        pinned = true,
        collapsed = false,
        size = { height = 0.6, width = 0.2 },
        filter = function(_, win)
          return vim.w[win].snacks_picker ~= nil
        end,
        open = function()
          Snacks.explorer.open()
        end,
      },
```

If this rule makes regular Snacks pickers appear in Edgy during manual testing, remove the Edgy explorer block entirely and let Snacks explorer manage its own sidebar layout.

- [ ] **Step 6: Update filetype ignore lists**

In `lua/configs/tiny-inline-diagnostic.lua`, replace `"NvimTree",` with:

```lua
      "snacks_picker",
      "snacks_picker_list",
      "snacks_picker_input",
      "snacks_picker_preview",
```

In `lua/configs/splits.lua`, replace:

```lua
  ignored_filetypes = { "NvimTree" },
```

with:

```lua
  ignored_filetypes = { "snacks_picker", "snacks_picker_list", "snacks_picker_input", "snacks_picker_preview" },
```

In `lua/utils/file_ref.lua`, replace `NvimTree = true,` with:

```lua
  snacks_picker = true,
  snacks_picker_list = true,
  snacks_picker_input = true,
  snacks_picker_preview = true,
```

- [ ] **Step 7: Verify nvim-tree is gone**

Run:

```bash
rg -n "NvimTree|nvim-tree|NvimTreeOpen|NvimTreeToggle|nvimtree" lua
nvim --headless -u init.lua '+lua Snacks.explorer.open(); vim.schedule(function() vim.cmd("qa") end)' 
```

Expected: `rg` prints no matches; Neovim exits `0`.

- [ ] **Step 8: Commit explorer replacement**

Run:

```bash
stylua lua/plugins/init.lua lua/mappings.lua lua/autocmds/session.lua lua/configs/edgy.lua lua/configs/tiny-inline-diagnostic.lua lua/configs/splits.lua lua/utils/file_ref.lua
git add lua/plugins/init.lua lua/mappings.lua lua/autocmds/session.lua lua/configs/edgy.lua lua/configs/tiny-inline-diagnostic.lua lua/configs/splits.lua lua/utils/file_ref.lua
git commit -m "refactor: use snacks explorer"
```

Expected: commit succeeds.

---

### Task 7: Replace ToggleTerm with Snacks terminal while preserving zellij slots

**Files:**
- Modify: `lua/keymap/term.lua`
- Modify: `lua/plugins/init.lua`
- Delete: `lua/configs/toggleterm.lua`
- Modify: `lua/configs/rust.lua`
- Modify: `lua/configs/edgy.lua`
- Modify: `lua/configs/tiny-inline-diagnostic.lua`
- Modify: `lua/autocmds/filetypes.lua`
- Test: Lua module smoke tests and grep

**Interfaces:**
- Consumes: `Snacks.terminal.toggle(cmd, opts)`, `Snacks.terminal.get(cmd, opts)`, `Snacks.terminal.list()`.
- Produces: `term.toggle_all_terms()` and `term.move_term(delta)` still used by `lua/mappings.lua`.

- [ ] **Step 1: Replace `lua/keymap/term.lua` implementation**

Replace the entire file with this implementation:

```lua
local M = {}

local helper = require("utils.helpers")
local names = { "agent", "git", "main" }
local project_root = vim.fn.getcwd()
local project_name = vim.fn.fnamemodify(project_root, ":t")
local SESSION_NAME_MAX_LEN = 36
local PROJECT_TOKEN_MAX_LEN = 12
local BRANCH_TOKEN_MAX_LEN = 10
local HASH_LEN = 6
local TERM_TOKEN_MAX_LEN = SESSION_NAME_MAX_LEN - PROJECT_TOKEN_MAX_LEN - BRANCH_TOKEN_MAX_LEN - HASH_LEN - 3

local last_active = 1
local current_sessions = {}

local function get_zellij_socket_dir()
  local existing = vim.env.ZELLIJ_SOCKET_DIR
  if existing and existing ~= "" then
    return existing
  end

  if vim.fn.has("unix") ~= 1 then
    return nil
  end

  local uv = vim.uv or vim.loop
  if uv and type(uv.os_get_passwd) == "function" then
    local ok, passwd = pcall(uv.os_get_passwd)
    if ok and passwd and passwd.uid ~= nil then
      return string.format("/tmp/zellij-%s", tostring(passwd.uid))
    end
  end

  local uid = vim.env.UID
  if uid and uid ~= "" then
    return string.format("/tmp/zellij-%s", uid)
  end

  return "/tmp/zellij"
end

local ZELLIJ_SOCKET_DIR = get_zellij_socket_dir()

local function sanitize_session_part(value)
  return tostring(value):gsub("[^%w_-]", "_")
end

local function trim_session_part(value, max_len)
  if #value <= max_len then
    return value
  end
  return value:sub(1, max_len)
end

local function ensure_zellij_socket_dir()
  if ZELLIJ_SOCKET_DIR and ZELLIJ_SOCKET_DIR ~= "" and vim.fn.isdirectory(ZELLIJ_SOCKET_DIR) == 0 then
    vim.fn.mkdir(ZELLIJ_SOCKET_DIR, "p")
  end
end

local function zellij_cli()
  ensure_zellij_socket_dir()
  if ZELLIJ_SOCKET_DIR and ZELLIJ_SOCKET_DIR ~= "" then
    return string.format("env ZELLIJ_SOCKET_DIR=%s zellij", vim.fn.shellescape(ZELLIJ_SOCKET_DIR))
  end
  return "zellij"
end

local project_token = trim_session_part(sanitize_session_part(project_name), PROJECT_TOKEN_MAX_LEN)

local function get_git_branch()
  local branch = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error == 0 and #branch > 0 then
    return sanitize_session_part(branch[1])
  end
  return "main"
end

local function session_name(term_name, unique)
  local branch = trim_session_part(get_git_branch(), BRANCH_TOKEN_MAX_LEN)
  local term = trim_session_part(sanitize_session_part(term_name), TERM_TOKEN_MAX_LEN)
  local seed = { project_root, get_git_branch(), term }
  if unique then
    local uv = vim.uv or vim.loop
    vim.list_extend(seed, { tostring(vim.fn.getpid()), tostring(os.time()), uv and tostring(uv.hrtime()) or "" })
  end
  local fingerprint = vim.fn.sha256(table.concat(seed, "|")):sub(1, HASH_LEN)
  return string.format("%s_%s_%s_%s", project_token, branch, term, fingerprint)
end

local function build_zellij_cmd(name)
  return string.format("cd %s && %s attach -c %s", vim.fn.shellescape(project_root), zellij_cli(), vim.fn.shellescape(name))
end

local function terminal_opts(index, title)
  return {
    count = index,
    interactive = true,
    auto_insert = true,
    start_insert = true,
    auto_close = false,
    win = {
      style = "terminal",
      title = " " .. title .. " ",
      wo = { number = false, relativenumber = false },
    },
  }
end

local function open_slot(index)
  local name = names[index]
  last_active = index
  current_sessions[index] = current_sessions[index] or session_name(name, false)
  local cmd = build_zellij_cmd(current_sessions[index])
  local term = Snacks.terminal.toggle(cmd, terminal_opts(index, name))

  if not helper.is_linux() then
    vim.schedule(function()
      vim.cmd("hi NormalFloat guibg=NONE")
      vim.cmd("hi FloatBorder guibg=NONE")
    end)
  end

  return term
end

function M.toggle_all_terms()
  local open = false
  for _, term in ipairs(Snacks.terminal.list()) do
    if term:is_valid() and term:win_valid() then
      open = true
      term:hide()
    end
  end
  if not open then
    open_slot(last_active)
  end
end

function M.move_term(delta)
  local next_index = ((last_active + delta - 1) % #names) + 1
  open_slot(next_index)
end

function M.new_session(index)
  index = index or last_active
  current_sessions[index] = session_name(names[index], true)
  open_slot(index)
end

return M
```

This intentionally drops the old Telescope session chooser. It keeps the three named zellij slots and adds `M.new_session(index)` for future mapping if needed.

- [ ] **Step 2: Remove ToggleTerm plugin spec and config**

In `lua/plugins/init.lua`, delete the whole spec beginning with:

```lua
  {
    "akinsho/toggleterm.nvim",
```

Then run:

```bash
rm lua/configs/toggleterm.lua
```

- [ ] **Step 3: Update rustaceanvim executor**

In `lua/configs/rust.lua`, replace:

```lua
      executor = require("rustaceanvim.executors").toggleterm,
```

with:

```lua
      executor = require("rustaceanvim.executors").termopen,
```

- [ ] **Step 4: Update Edgy terminal rule**

In `lua/configs/edgy.lua`, replace the `toggleterm` bottom block with:

```lua
      {
        ft = "snacks_terminal",
        size = { height = 0.3 },
        filter = function(_, win)
          return vim.w[win].snacks_win and vim.w[win].snacks_win.position == "bottom"
        end,
      },
```

If terminals are only floating after Task 1 styles, this rule is harmless and may not match.

- [ ] **Step 5: Update terminal filetype exclusions**

In `lua/autocmds/filetypes.lua`, replace `"toggleterm",` with:

```lua
  "snacks_terminal",
```

In `lua/configs/tiny-inline-diagnostic.lua`, replace `"toggleterm",` with:

```lua
      "snacks_terminal",
```

- [ ] **Step 6: Verify ToggleTerm is gone**

Run:

```bash
rg -n "toggleterm|ToggleTerm|toggle_number|require\(\"toggleterm" lua
nvim --headless -u init.lua '+lua local term = require("keymap.term"); assert(type(term.toggle_all_terms) == "function"); assert(type(term.move_term) == "function")' +qa
```

Expected: `rg` prints no matches; Neovim exits `0`.

- [ ] **Step 7: Commit terminal replacement**

Run:

```bash
stylua lua/keymap/term.lua lua/plugins/init.lua lua/configs/rust.lua lua/configs/edgy.lua lua/configs/tiny-inline-diagnostic.lua lua/autocmds/filetypes.lua
git add lua/keymap/term.lua lua/plugins/init.lua lua/configs/rust.lua lua/configs/edgy.lua lua/configs/tiny-inline-diagnostic.lua lua/autocmds/filetypes.lua lua/configs/toggleterm.lua
git add -u lua/configs
git commit -m "refactor: use snacks terminal"
```

Expected: commit succeeds.

---

### Task 8: Replace NvChad UI integrations that Snacks covers

**Files:**
- Modify: `lua/plugins/init.lua`
- Modify: `lua/chadrc.lua`
- Test: grep for disabled/replaced NvChad plugin names and headless load

**Interfaces:**
- Consumes: `Snacks.dashboard` and `Snacks.indent` from Task 1.
- Produces: no NvDash startup and no indent-blankline plugin.

- [ ] **Step 1: Disable NvChad indent-blankline**

In `lua/plugins/init.lua`, add this spec near other disabled NvChad default plugin overrides:

```lua
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
```

- [ ] **Step 2: Remove blankline Base46 integrations**

In `lua/chadrc.lua`, remove both duplicate entries:

```lua
    "blankline",
```

- [ ] **Step 3: Disable NvDash startup**

In `lua/chadrc.lua`, replace:

```lua
M.nvdash = { load_on_startup = true }
```

with:

```lua
M.nvdash = { load_on_startup = false }
```

- [ ] **Step 4: Remove Telescope UI options**

In `lua/chadrc.lua`, delete this table from `M.ui`:

```lua
  telescope = {
    style = "bordered",
  },
```

Also remove this entry from `M.base46.integrations`:

```lua
    "telescope",
```

- [ ] **Step 5: Verify UI integration cleanup**

Run:

```bash
rg -n "blankline|telescope|Telescope|nvdash|Nvdash|indent-blankline" lua/chadrc.lua lua/plugins/init.lua
nvim --headless -u init.lua '+lua require("chadrc")' +qa
```

Expected: matches only for disabled plugin override lines if present; Neovim exits `0`.

- [ ] **Step 6: Commit UI integration cleanup**

Run:

```bash
stylua lua/plugins/init.lua lua/chadrc.lua
git add lua/plugins/init.lua lua/chadrc.lua
git commit -m "refactor: use snacks for dashboard and indent"
```

Expected: commit succeeds.

---

### Task 9: Final plugin cleanup, lockfile refresh, and full verification

**Files:**
- Modify: `lazy-lock.json` via lazy.nvim after plugin sync
- Inspect: `lua/**`, `lazy-lock.json`
- Test: full grep, format, headless load, lazy sync/checkhealth

**Interfaces:**
- Consumes: all previous tasks.
- Produces: final repo state with Snacks as the replacement layer and no stale runtime references.

- [ ] **Step 1: Run a whole-config stale reference scan**

Run:

```bash
rg -n "fzf-lua|FzfLua|telescope|Telescope|telescope-fzf|telescope-frecency|nvim-tree|NvimTree|toggleterm|ToggleTerm|nvim-notify|require\(\"notify\"\)|dressing|sidekick|fff.nvim|require\(\"fff\"\)|project.nvim|advanced-git-search|indent-blankline|blankline" lua init.lua
```

Expected: no matches except acceptable words in comments that describe migration history. Prefer deleting those comments instead of keeping stale names.

- [ ] **Step 2: Sync plugins and refresh lockfile**

Run:

```bash
nvim --headless -u init.lua '+Lazy! sync' +qa
```

Expected: exit code `0`. `lazy-lock.json` should add `snacks.nvim` and remove lock entries for removed plugins once Lazy sync prunes them.

- [ ] **Step 3: Run health and load checks**

Run:

```bash
nvim --headless -u init.lua '+checkhealth snacks' '+lua require("mappings"); require("configs.lspconfig"); require("keymap.term")' +qa
```

Expected: exit code `0`. Optional health warnings are acceptable only if they are for optional external tools; Lua errors are not acceptable.

- [ ] **Step 4: Format all Lua**

Run:

```bash
stylua lua/
stylua --check lua/
```

Expected: both commands exit `0`.

- [ ] **Step 5: Run final lockfile stale reference scan**

Run:

```bash
rg -n '"(fzf-lua|telescope-frecency.nvim|telescope-fzf-native.nvim|telescope.nvim|nvim-tree.lua|toggleterm.nvim|nvim-notify|dressing.nvim|sidekick.nvim|fff.nvim|project.nvim|advanced-git-search.nvim|indent-blankline.nvim)"' lazy-lock.json
rg -n '"snacks.nvim"' lazy-lock.json
```

Expected: first command has no matches; second command prints the Snacks lock entry.

- [ ] **Step 6: Manual smoke checklist inside Neovim**

Run `nvim` normally and check:

```text
<leader>ff opens Snacks file picker.
<leader>fw opens Snacks grep picker.
<leader>fb opens Snacks buffer picker.
<leader>fm opens Snacks notification history.
gp/gh/gm on an LSP-attached buffer open Snacks LSP symbol/reference/implementation pickers.
<leader>e opens Snacks explorer.
<leader>E reveals current file in Snacks explorer.
<A-i> toggles the active zellij terminal slot through Snacks terminal.
<A-j>/<A-k> cycle the three terminal slots.
vim.notify("hello") shows a Snacks notification.
No startup error mentions missing telescope, fzf-lua, nvim-tree, toggleterm, sidekick, dressing, or notify modules.
```

- [ ] **Step 7: Commit final cleanup**

Run:

```bash
git status --short
git add lazy-lock.json lua docs/superpowers/plans/2026-06-22-snacks-full-replacement.md
git commit -m "refactor: complete snacks replacement"
```

Expected: commit succeeds.

---

## Self-Review

- Spec coverage: This plan covers all explicit replacement targets identified in the current config: FzfLua, Telescope user specs and NvChad default Telescope, fff.nvim, project.nvim, advanced-git-search, dressing.nvim, nvim-notify, nvim-tree, toggleterm, sidekick, NvDash, and indent-blankline. It keeps non-equivalent plugins such as gitsigns, Trouble, Lspsaga, GrugFar, Edgy, Persisted, Bookmarks, Diffview, core LSP/completion/formatting, and Treesitter.
- Placeholder scan: No task uses unfinished marker text. Each code-changing step names exact files and concrete code.
- Interface consistency: Later tasks rely on `Snacks.*` APIs introduced in Task 1. `lua/mappings.lua` continues to consume `term.toggle_all_terms()` and `term.move_term(delta)`, which Task 7 preserves.
- Known risk: Snacks explorer filetypes and Edgy interaction may need one manual adjustment after smoke testing. The plan includes a concrete fallback: remove the Edgy explorer block if regular Snacks pickers are captured.
