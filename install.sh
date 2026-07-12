#!/usr/bin/env bash
# airev installer — downloads the single-file CLI to a dir on your PATH.
#   curl -fsSL https://raw.githubusercontent.com/Dshuishui/airev/main/install.sh | bash
set -euo pipefail

REPO="Dshuishui/airev"
URL="https://raw.githubusercontent.com/$REPO/main/airev"

# Pick an install dir. Prefer one already on PATH so airev works IMMEDIATELY —
# no new terminal, no `source`. Fall back to ~/.local/bin (+ PATH setup) only
# if nothing writable is already on PATH.
pick_dir() {
  [ -n "${AIREV_BIN:-}" ] && { printf '%s' "$AIREV_BIN"; return; }
  local d oldifs="$IFS"
  # clean, preferred spots if they're already on PATH
  for d in "$HOME/.local/bin" "$HOME/bin"; do
    case ":$PATH:" in *":$d:"*) [ -d "$d" ] && [ -w "$d" ] && { printf '%s' "$d"; return; } ;; esac
  done
  # any writable dir already on PATH (prefer $HOME-owned)
  IFS=:; for d in $PATH; do case "$d" in "$HOME"/*) [ -d "$d" ] && [ -w "$d" ] && { IFS="$oldifs"; printf '%s' "$d"; return; } ;; esac; done
  for d in $PATH; do [ -n "$d" ] && [ -d "$d" ] && [ -w "$d" ] && { IFS="$oldifs"; printf '%s' "$d"; return; }; done
  IFS="$oldifs"
  printf '%s' "$HOME/.local/bin"
}
BIN_DIR="$(pick_dir)"

mkdir -p "$BIN_DIR"
echo "airev: downloading -> $BIN_DIR/airev"
curl -fsSL "$URL" -o "$BIN_DIR/airev"
chmod +x "$BIN_DIR/airev"

echo "airev: installed. version: $("$BIN_DIR/airev" version)"
case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "airev: ready — run 'airev init' inside a repo."
    ;;
  *)
    # not on PATH yet — add it to the user's shell rc automatically
    case "${SHELL##*/}" in
      zsh)  RC="$HOME/.zshrc" ;;
      bash) RC="$HOME/.bashrc" ;;
      *)    RC="$HOME/.profile" ;;
    esac
    if ! grep -qsF "$BIN_DIR" "$RC" 2>/dev/null; then
      printf '\n# added by airev installer\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$RC"
      echo "airev: added $BIN_DIR to PATH in $RC"
    fi
    echo "airev: open a new terminal (or run: source $RC), then 'airev init'."
    ;;
esac
