# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a [NvChad](https://github.com/NvChad/NvChad)-based Neovim configuration. NvChad itself is loaded as a lazy.nvim plugin (v2.5 branch), and this repo contains the user-layer customizations on top of it.

## Code Style

Lua formatting is managed by **StyLua** (config in `.stylua.toml`). Format with:

```sh
stylua lua/
```

## Architecture

### Entry Point: `init.lua`

Bootstraps lazy.nvim (auto-installs if missing), then loads plugins in two layers:
1. NvChad base — provides core UI, base plugins, and theme infrastructure
2. Custom plugins — declared in `lua/plugins/init.lua`

After plugins, it loads: `lua/options.lua` → `lua/autocmds.lua` → `lua/mappings.lua`.

### Plugin System

**lazy.nvim** is the plugin manager. All plugins default to `lazy = true`. Key loading patterns used throughout `lua/plugins/init.lua`:
- `event = "BufReadPost"` — load after opening a buffer
- `event = "LspAttach"` — load when an LSP attaches
- `cmd = "..."` — load on command invocation

Plugin declarations live in `lua/plugins/init.lua`. Plugin-specific configs live in `lua/configs/<plugin-name>.lua` and are referenced via `config = function() require("configs.<name>") end`.

### LSP Configuration (`lua/configs/lspconfig.lua`)

LSP servers are configured individually using `nvim-lspconfig`. Currently configured servers: `gopls`, `jsonls`, `pyright`, `nixd`, `lua_ls`, and `clangd`. The `nixd` server uses pinned GitHub flake URLs (not local `/etc/nixos`) for portability.

### Key Files

| File | Purpose |
|------|---------|
| `lua/plugins/init.lua` | All plugin declarations (~70 plugins) |
| `lua/configs/lspconfig.lua` | LSP server setup |
| `lua/configs/conform.lua` | Formatter configuration |
| `lua/mappings.lua` | All custom keymaps |
| `lua/autocmds.lua` | Autocommands |
| `lua/chadrc.lua` | NvChad theme/UI overrides (colorscheme: catppuccin) |
| `lua/settings.lua` | Treesitter language dependencies |

### Adding a Plugin

1. Add the plugin spec to `lua/plugins/init.lua`
2. If it needs non-trivial config, create `lua/configs/<plugin-name>.lua`
3. Reference it in the spec: `config = function() require("configs.<name>") end`

### Keymaps

All custom keymaps are in `lua/mappings.lua`, organized by category. The helper in `lua/keymap/bind.lua` provides a `map()` utility used throughout.
