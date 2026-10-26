# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

macOS/Linux dotfiles repo. One bootstrap script symlinks config files and runs numbered install scripts to go from a fresh machine to a configured terminal (Ghostty + herdr + zsh + Neovim).

herdr is the default terminal multiplexer and autostarts from `zsh/zshrc`. tmux is kept
configured and installed but no longer autostarts -- see the tmux section below.

## Install & Test Commands

```bash
# Full bootstrap (macOS)
./install.sh

# Full bootstrap (Linux server)
./install-server.sh

# Validate tmux config
tmux -L _cfg_check -f ~/.tmux.conf start-server \; kill-server

# Install new Homebrew packages
# Add to Brewfile, then:
brew bundle --file=~/dotfiles/Brewfile

# Reload tmux config (inside tmux)
# Prefix + q  (custom binding)

# Install tmux plugins (inside tmux)
# Prefix + I
```

## Architecture

**Orchestration:** `install.sh` (macOS) and `install-server.sh` (Linux) both source `install-common.sh`, which runs the shared pipeline:
1. Execute `scripts/*.sh` in sorted order (numbered prefixes: `01-`, `02-`, etc.) — runs BEFORE symlinks so installers don't overwrite managed configs
2. Read `symlinks` file (format: `src:dst`) and create symlinks via `symlink()` function, backing up existing files to `*.bak`
3. Create `~/.zshrc.local` and `~/.ssh/config.local` from examples (never committed)
4. Install tmux plugins via TPM, kill stale tmux server, validate config

**Config directories** map 1:1 to tools (`ghostty/`, `herdr/`, `tmux/`, `zsh/`, `nvim/`, `k9s/`, `yabai/`, `skhd/`, `ssh/`). The `symlinks` file is the single source of truth for what gets linked where.

**Machine-specific config** goes in `~/.zshrc.local` (from `zsh/zshrc.local.example`) — certs, language managers, private PATH entries. Never committed.

## Conventions

### Install scripts (`scripts/`)
- Numbered prefixes control execution order
- Must be idempotent: check if tool exists before installing
- Use exported helpers `info`, `ok`, `warn` for output
- Pattern: check existence -> install if missing -> print `ok`

### Adding a new tool
1. Create directory: `newtool/`
2. Add config files inside it
3. Add `src:dst` line to `symlinks` file
4. If install beyond Homebrew is needed, add a numbered script in `scripts/`

### Theming
Palette-driven approach: tmux uses Catppuccin plugin with Everforest Dark Hard color overrides (`@thm_*` variables in `tmux.conf`). Neovim uses `everforest` colorscheme. Ghostty has its own theme. herdr uses the `gruvbox` built-in with `[theme.custom]` overrides copied from the same `@thm_*` palette. To change theme, update all four locations.

### herdr (`herdr/config.toml`)
- Prefix: `Ctrl+Space`, deliberately identical to tmux so the muscle memory transfers
- Autostarts from the END of `zsh/zshrc` -- it needs `~/.local/bin` on PATH, which
  happens partway down the file, so the block cannot be moved up with the tmux one
- Guards: skipped when `DOTFILES_NO_HERDR=1`, inside an existing pane (`HERDR_ENV=1`),
  inside tmux (`$TMUX`), or without a TTY. Never fatal -- a failed launch leaves a shell
- Validate with `herdr config check` (strict: it reports unknown keys)
- Reload a running server without restarting: `hrdrrc`
- Aliases and completions come from the `herdr` Oh My Zsh plugin (see `plugins=` line)

### tmux
- Prefix: `Ctrl+Space` (backup: `Ctrl+b`)
- No longer autostarts. Run `tmux` directly, or `DOTFILES_TMUX_AUTOSTART=1 zsh -l`
- Inside a herdr pane, herdr takes `Ctrl+Space` first, so a nested tmux is driven by
  its backup prefix `Ctrl+b`. This is why `prefix2` is still set
- Vi mode for copy, vim-style pane navigation (`h/j/k/l`)
- Status bar at top, sessions auto-save/restore via resurrect + continuum
- Keyboard shortcuts documented in `cheatsheet.md` (symlinked to `~/tmux-cheatsheet.md`)

### Shell (`zsh/zshrc`)
- Auto-starts herdr (last block in the file); tmux autostart is opt-in
- Dev layout functions (`tdl`, `tdlm`, `tsl`) create tmux pane arrangements — must be run
  inside tmux. They guard on `$TMUX` and exit with a message otherwise, so they degrade
  cleanly under herdr. Not yet ported to herdr's `workspace`/`pane`/`agent` commands
