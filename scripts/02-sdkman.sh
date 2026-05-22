#!/usr/bin/env bash

if [ -d "$HOME/.sdkman" ]; then
  ok "SDKMAN already installed"
  exit 0
fi

# SDKMAN requires bash 4+. macOS ships bash 3.2, so prefer Homebrew's bash.
BASH_BIN="bash"
for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
  [ -x "$candidate" ] && BASH_BIN="$candidate" && break
done

if ! "$BASH_BIN" -c '[ "${BASH_VERSINFO[0]}" -ge 4 ]'; then
  warn "SDKMAN needs bash 4+. Install with: brew install bash"
  exit 0
fi

info "Installing SDKMAN..."
if curl -fsSL "https://get.sdkman.io?rcupdate=false" | "$BASH_BIN"; then
  ok "SDKMAN installed. Run 'sdk install java' to install a JDK"
else
  warn "SDKMAN install failed"
  exit 0
fi
