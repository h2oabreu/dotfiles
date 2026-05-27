#!/usr/bin/env bash

if ! command -v granted &>/dev/null; then
  warn "granted not installed; skipping completion setup"
  exit 0
fi

# granted writes _assume and _granted into ~/.granted/zsh_autocomplete/{assume,granted}/
# Idempotent: skip if already generated.
if [ -f "$HOME/.granted/zsh_autocomplete/assume/_assume" ]; then
  ok "granted zsh completions already generated"
  exit 0
fi

info "Generating granted zsh completions..."
granted completion -s zsh >/dev/null 2>&1
ok "granted completions ready at ~/.granted/zsh_autocomplete"
