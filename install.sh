#!/usr/bin/env bash
# airev installer — downloads the single-file CLI to a dir on your PATH.
#   curl -fsSL https://raw.githubusercontent.com/Dshuishui/airev/main/install.sh | bash
set -euo pipefail

REPO="Dshuishui/airev"
BIN_DIR="${AIREV_BIN:-$HOME/.local/bin}"
URL="https://raw.githubusercontent.com/$REPO/main/airev"

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
