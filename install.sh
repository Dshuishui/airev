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
  *":$BIN_DIR:"*) echo "airev: ready — run 'airev init' inside a repo." ;;
  *)
    echo "airev: $BIN_DIR is not on your PATH yet. Add it:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\"                     # this shell"
    echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc  # persist (use ~/.bashrc for bash)"
    ;;
esac
