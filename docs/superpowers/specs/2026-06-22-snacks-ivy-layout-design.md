# Snacks ivy picker layout design

## Goal

Use Snacks picker with an ivy-style default layout so file/search picker UX stays close to the previous Telescope/FzfLua bottom-picker theme.

## Scope

- Change only the default Snacks picker layout for ordinary pickers.
- Keep the Snacks Explorer source on the existing sidebar layout.
- Do not change fff.nvim retention, terminal session picker behavior, Edgy integration, or session handling.

## Design

Update `lua/configs/snacks.lua` under `picker.layout` from the current responsive function:

```lua
preset = function()
  return vim.o.columns >= 120 and "default" or "vertical"
end
```

to a direct ivy preset:

```lua
preset = "ivy"
```

Snacks provides an `ivy` preset in `snacks.picker.config.layouts`. It renders the picker as a bottom-oriented vertical layout with input above the list and preview on the right, matching the known Telescope/FzfLua-style picker flow better than the current wide `default` layout.

`sources.explorer.layout = { preset = "sidebar", preview = false }` remains unchanged, so Explorer continues to open as an Edgy-managed left sidebar and keeps the current tabufline offset behavior.

## Validation

- Headless assertion that the configured default picker layout resolves to `ivy`.
- Existing Explorer toggle regression still passes.
- Existing tabufline offset regression still passes.
- Existing `<A-d>` terminal session picker regression still passes.
- `stylua lua/configs/snacks.lua` and `git diff --check` pass.

## Risks

The main intentional behavior change is that wide screens no longer use Snacks' `default` picker layout. This is expected because the goal is to keep the familiar ivy-style picker layout across ordinary Snacks pickers.
