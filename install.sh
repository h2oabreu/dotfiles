#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES

info()  { printf "\033[1;34m[dotfiles]\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m[dotfiles]\033[0m %s\n" "$1"; }
warn()  { printf "\033[1;33m[dotfiles]\033[0m %s\n" "$1"; }
export -f info ok warn

# ─── Homebrew ───────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info "Installing packages from Brewfile..."
# Non-fatal so symlinks still get created, but the failure is re-reported at the
# end of install-common.sh -- otherwise "Setup complete!" hides missing tools.
DOTFILES_BUNDLE_FAILED=0
if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$DOTFILES/Brewfile"; then
  DOTFILES_BUNDLE_FAILED=1
  warn "brew bundle failed — continuing; missing packages are listed at the end"
fi

source "$DOTFILES/install-common.sh"
