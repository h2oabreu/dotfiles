# dotfiles

Opinionated, terminal-first developer environment for macOS and headless Linux machines. Tmux keybindings and layout functions inspired by [Omarchy](https://github.com/basecamp/omarchy). One command bootstrap on either platform.

## What's included

- **Ghostty** -- GPU-accelerated terminal (macOS), Everforest Dark Hard theme
- **herdr** -- default multiplexer, built for AI coding agents; `Ctrl+Space` prefix, Everforest palette
- **tmux** -- Omarchy-inspired keybindings, Catppuccin status bar with Everforest palette, auto-save/restore via Continuum (no longer autostarts)
- **Neovim** -- LazyVim with bamboo.nvim colorscheme
- **zsh** -- Oh My Zsh with robbyrussell theme, herdr autostart
- **1Password SSH** -- SSH agent backed by 1Password on macOS (auto-skipped on Linux)
- **k9s** -- Kubernetes TUI with Everforest Dark Hard skin
- **Kubernetes tools** -- kubectl, helm, kind, k9s (Brewfile on macOS, binary downloads on Linux)
- **fzf** -- fuzzy finder for history, files, and directories
- **Dev layouts** -- `tdl`, `tdlm`, `tsl` functions for editor + AI + terminal pane arrangements

## Quick start

### macOS

```bash
git clone https://github.com/hugomiguelabreu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Linux (headless dev machine)

```bash
git clone https://github.com/hugomiguelabreu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-server.sh
```

Supports Debian/Ubuntu (apt) and Fedora/RHEL (dnf). Sets zsh as default shell and installs k8s tools from official binaries.

Then edit `~/.zshrc.local` for machine-specific config (corporate certs, SDKMAN, NVM, etc.).

## Architecture

Two entry points, one shared pipeline -- no OS branching in config files:

```
install.sh          # macOS: Homebrew + Brewfile → source install-common.sh
install-server.sh   # Linux: apt/dnf packages + chsh → source install-common.sh
install-common.sh   # Shared: scripts, symlinks, TPM, validation
```

Config files use each tool's native conditional syntax instead of bash if/else:
- **zsh** -- `command -v` and path existence guards
- **tmux** -- `if-shell` blocks for clipboard and TPM path
- **SSH** -- `Match exec` for 1Password agent socket detection

## Structure

```
dotfiles/
├── install.sh              # macOS entry point (Homebrew)
├── install-server.sh       # Linux entry point (apt/dnf)
├── install-common.sh       # Shared pipeline
├── Brewfile                # Homebrew packages (macOS only)
├── symlinks                # source:destination mappings
├── scripts/                # Tool installers (run in sorted order)
│   ├── 01-oh-my-zsh.sh
│   ├── 02-sdkman.sh
│   ├── 03-nvm.sh
│   ├── 04-tpm.sh
│   └── 05-k8s-tools.sh
├── ghostty/config          # Ghostty terminal config
├── k9s/
│   ├── config.yaml         # k9s config (mouse, skin)
│   └── skins/
│       └── everforest-dark-hard.yaml
├── nvim/init.lua           # Neovim config (lazy.nvim + bamboo.nvim)
├── ssh/
│   ├── config              # SSH config (1Password via Match exec)
│   └── config.local.example
├── herdr/config.toml       # herdr config (prefix, theme, agent sessions)
├── tmux/tmux.conf          # tmux config
├── zsh/
│   ├── zshrc               # Main shell config
│   └── zshrc.local.example
└── cheatsheet.md           # Keyboard shortcuts reference
```

## How it works

Both `install.sh` and `install-server.sh` install platform-specific packages, then source `install-common.sh` which:

1. Runs `scripts/*.sh` in sorted order (Oh My Zsh, SDKMAN, NVM, TPM, k8s tools)
2. Creates symlinks from the `symlinks` file (backs up existing configs to `*.bak`)
3. Sets up SSH socket directory and local override files
4. Installs tmux plugins via TPM
5. Validates tmux config

## Adding new install scripts

Add a numbered script under `scripts/`. Use the exported helpers `info`, `ok`, `warn` and guard with an existence check:

```bash
#!/usr/bin/env bash

if [ ! -d "$HOME/.my-tool" ]; then
  info "Installing my-tool..."
  # your install commands
  ok "my-tool installed"
else
  ok "my-tool already installed"
fi
```

## Adding new tool configs

1. Create a folder: `mkdir ~/dotfiles/newtool`
2. Add config files inside it
3. Add a line to `symlinks`: `newtool/config:$HOME/.config/newtool/config`

## Machine-specific config

Anything that shouldn't be in the repo goes in `~/.zshrc.local`:

- Corporate SSL certificates
- Work-specific scripts
- SDKMAN, NVM, language version managers
- Private PATH additions

See `zsh/zshrc.local.example` for a full template. SSH host config goes in `~/.ssh/config.local`.

## 1Password SSH (macOS)

SSH authentication is handled by the 1Password SSH agent. The config uses `Match exec` to detect the agent socket -- on Linux where the socket doesn't exist, these directives are automatically skipped.

1. Open **1Password** → **Settings** → **Developer**
2. Enable **Use the SSH Agent**
3. Add your SSH keys to 1Password
