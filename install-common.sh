#!/usr/bin/env bash
# Shared install pipeline — sourced by install.sh (macOS) and install-server.sh (Linux).
# Expects $DOTFILES to be set and helpers (info, ok, warn) to be exported.

# ─── Tool install scripts ──────────────────────────────────
# Run BEFORE symlinks so that installers (e.g. Oh My Zsh) that create
# default dotfiles don't overwrite our managed symlinks.
info "Running install scripts..."
for script in "$DOTFILES/scripts/"*.sh; do
  [ -f "$script" ] || continue
  info "Running $(basename "$script")..."
  bash "$script"
done

# ─── Symlinks ───────────────────────────────────────────────
symlink() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "Backing up existing $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "Linked $dst -> $src"
}

info "Creating symlinks..."
while IFS=: read -r src dst || [[ -n "$src" ]]; do
  [[ "$src" =~ ^#|^[[:space:]]*$ ]] && continue
  dst="${dst/\$HOME/$HOME}"
  symlink "$DOTFILES/$src" "$dst"
done < "$DOTFILES/symlinks"

# ─── SSH socket dir ─────────────────────────────────────────
mkdir -p "$HOME/.ssh/socket"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/socket"
ok "SSH socket directory ready"

# ─── Local overrides ────────────────────────────────────────
if [ ! -f "$HOME/.zshrc.local" ]; then
  info "Creating ~/.zshrc.local from example..."
  cp "$DOTFILES/zsh/zshrc.local.example" "$HOME/.zshrc.local"
  warn "Edit ~/.zshrc.local for machine-specific config (certs, SDKMAN, NVM, etc.)"
fi

if [ ! -f "$HOME/.ssh/config.local" ]; then
  info "Creating ~/.ssh/config.local from example..."
  mkdir -p "$HOME/.ssh"
  cp "$DOTFILES/ssh/config.local.example" "$HOME/.ssh/config.local"
  warn "Edit ~/.ssh/config.local for machine-specific SSH hosts"
fi

# ─── TPM plugin install ──────────────────────────────────────
TPM_BIN="/opt/homebrew/opt/tpm/share/tpm/bin/install_plugins"
[ -x "$TPM_BIN" ] || TPM_BIN="$HOME/.tmux/plugins/tpm/bin/install_plugins"
if [ -x "$TPM_BIN" ]; then
  info "Installing tmux plugins via TPM..."
  "$TPM_BIN" || warn "TPM plugin install had issues (non-fatal)"
  ok "tmux plugins installed"
fi

# ─── Kill stale tmux server ──────────────────────────────────
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
  warn "Killing existing tmux server so new config takes effect on next launch"
  tmux kill-server 2>/dev/null || true
fi

# ─── Post-install validation ─────────────────────────────────
info "Validating configuration..."

if command -v tmux &>/dev/null; then
  if tmux -L _cfg_check -f "$HOME/.tmux.conf" start-server \; kill-server 2>/dev/null; then
    ok "tmux config is valid"
  else
    warn "tmux config has errors — run 'tmux source ~/.tmux.conf' to see details"
  fi
fi

if command -v herdr &>/dev/null; then
  if herdr config check 2>/dev/null | grep -q "^config: ok"; then
    ok "herdr config is valid"
  else
    warn "herdr config has issues — run 'herdr config check' to see details"
  fi
fi

# ─── Done ────────────────────────────────────────────────────
echo ""
ok "Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Edit ~/.zshrc.local for machine-specific settings"
echo "  2. Start a new shell session — herdr starts automatically"
echo "  3. Prefix is Ctrl+Space (same as tmux): Ctrl+Space ? for help, v to split"
echo "  4. tmux no longer autostarts — run 'tmux', or DOTFILES_TMUX_AUTOSTART=1 zsh -l"
echo "  5. Cheatsheet at ~/tmux-cheatsheet.md"
echo ""
