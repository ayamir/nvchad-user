# Snacks Ivy Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ordinary Snacks pickers use the built-in ivy layout while preserving the existing Explorer sidebar behavior.

**Architecture:** This is a single configuration change in the NvChad user-layer Snacks config. The global picker layout becomes the Snacks `ivy` preset; the Explorer source keeps its explicit `sidebar` layout override, so Edgy and tabufline behavior remain unchanged.

**Tech Stack:** Neovim Lua config, `folke/snacks.nvim`, NvChad user-layer plugin config, Stylua, headless Neovim regression scripts.

## Global Constraints

- Change only the default Snacks picker layout for ordinary pickers.
- Keep `sources.explorer.layout = { preset = "sidebar", preview = false }` unchanged.
- Do not change fff.nvim retention, terminal session picker behavior, Edgy integration, or session handling.
- Use `stylua lua/configs/snacks.lua` for formatting.
- Do not push; this branch is local-ahead and push requires explicit user request.

---

## File Structure

- Modify: `lua/configs/snacks.lua`
  - Responsibility: configures Snacks modules and picker defaults. This plan only changes `picker.layout.preset`.
- Create temporarily outside the repo: `/tmp/test-snacks-picker-ivy-layout.lua`
  - Responsibility: asserts that ordinary picker layout resolves to ivy while Explorer remains sidebar. This file is not committed.

---

### Task 1: Switch Snacks picker default layout to ivy

**Files:**
- Modify: `lua/configs/snacks.lua:16-21`
- Test: `/tmp/test-snacks-picker-ivy-layout.lua`

**Interfaces:**
- Consumes: Snacks config loaded through `require("configs.snacks")` from the existing plugin spec.
- Produces: `require("configs.snacks").picker.layout.preset == "ivy"`; `require("configs.snacks").picker.sources.explorer.layout.preset == "sidebar"` remains true.

- [ ] **Step 1: Write the failing test**

Create `/tmp/test-snacks-picker-ivy-layout.lua` with this content:

```lua
local opts = require("configs.snacks")

assert(opts.picker, "Snacks picker config should exist")
assert(opts.picker.layout, "Snacks picker layout config should exist")
assert(opts.picker.layout.preset == "ivy", "ordinary Snacks pickers should use ivy layout")

local explorer = opts.picker.sources and opts.picker.sources.explorer
assert(explorer, "Snacks Explorer source config should exist")
assert(explorer.layout, "Snacks Explorer layout config should exist")
assert(explorer.layout.preset == "sidebar", "Snacks Explorer should stay on sidebar layout")
assert(explorer.layout.preview == false, "Snacks Explorer preview should remain disabled")

local layouts = require("snacks.picker.config.layouts")
assert(layouts.ivy, "Snacks should provide an ivy layout preset")
assert(layouts.sidebar, "Snacks should provide a sidebar layout preset")

vim.cmd("qa!")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
nvim --headless -u init.lua -S /tmp/test-snacks-picker-ivy-layout.lua
```

Expected: FAIL with `ordinary Snacks pickers should use ivy layout`, because current config returns `"default"` on wide screens or `"vertical"` on narrow screens.

- [ ] **Step 3: Write minimal implementation**

In `lua/configs/snacks.lua`, replace:

```lua
    layout = {
      preset = function()
        return vim.o.columns >= 120 and "default" or "vertical"
      end,
    },
```

with:

```lua
    layout = {
      preset = "ivy",
    },
```

Do not edit the existing Explorer block:

```lua
      explorer = {
        layout = { preset = "sidebar", preview = false },
```

- [ ] **Step 4: Format**

Run:

```bash
stylua lua/configs/snacks.lua
```

Expected: exit 0.

- [ ] **Step 5: Run the focused test to verify it passes**

Run:

```bash
nvim --headless -u init.lua -S /tmp/test-snacks-picker-ivy-layout.lua
```

Expected: PASS with exit 0 and no assertion output.

- [ ] **Step 6: Run regression checks**

Run:

```bash
nvim --headless -u init.lua -S /tmp/test-snacks-explorer-toggle.lua
nvim --headless -u init.lua -S /tmp/test-tabufline-offset-snacks-explorer.lua
nvim --headless -u init.lua -S /tmp/test-alt-d-opens-terminal-session-picker.lua
git diff --check
```

Expected: all commands exit 0. Explorer-related commands may print the known `[smart-splits.nvim] tmux init: failed to detect pane_id` warning; that warning is environmental and does not fail the check.

- [ ] **Step 7: Commit**

Stage only the Snacks config change. Do not stage unrelated dirty files.

Run:

```bash
git add lua/configs/snacks.lua
git diff --cached -- lua/configs/snacks.lua
git commit -m "fix: use ivy layout for snacks pickers" -m "Co-Authored-By: Aiden"
```

Expected staged diff contains only the `picker.layout.preset = "ivy"` change in `lua/configs/snacks.lua`.

---

## Self-Review

- Spec coverage: Task 1 changes only the ordinary Snacks picker default layout, keeps Explorer sidebar unchanged, avoids fff/terminal/Edgy/session behavior changes, and includes the requested validation.
- Placeholder scan: no unfinished markers, incomplete tasks, or vague test instructions remain.
- Type consistency: the plan uses existing Lua table fields only: `picker.layout.preset`, `picker.sources.explorer.layout.preset`, and `picker.sources.explorer.layout.preview`.
