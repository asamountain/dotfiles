#!/usr/bin/env bash
# bootstrap.sh — set up Neovim + LazyVim + clangd
set -e

# Detect OS
OS="$(uname -s)"
# Detect script directory to find dotfiles
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

echo "Detected OS: $OS"
echo "Dotfiles directory: $DOTFILES"

# Helper to check if a command exists
exists() {
  command -v "$1" >/dev/null 2>&1
}

# ── 1. Neovim ────────────────────────────────────────────────────────────────
if ! exists nvim; then
  if [ "$OS" = "Darwin" ]; then
    echo "[1/5] Installing Neovim via Homebrew..."
    brew install neovim
  else
    echo "[1/5] Installing Neovim (AppImage)..."
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage -o /tmp/nvim.appimage
    chmod +x /tmp/nvim.appimage
    cd /tmp && /tmp/nvim.appimage --appimage-extract > /dev/null 2>&1
    rm -rf "$HOME/.local/nvim-appimage"
    cp -r /tmp/squashfs-root "$HOME/.local/nvim-appimage"
    ln -sf "$HOME/.local/nvim-appimage/usr/bin/nvim" "$BIN/nvim"
  fi
else
  echo "[1/5] Neovim already installed: $(nvim --version | head -1)"
fi

# ── 2. ripgrep ────────────────────────────────────────────────────────────────
if ! exists rg; then
  if [ "$OS" = "Darwin" ]; then
    echo "[2/5] Installing ripgrep via Homebrew..."
    brew install ripgrep
  else
    echo "[2/5] Installing ripgrep..."
    RG_VER="14.1.1"
    curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C /tmp/
    cp "/tmp/ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" "$BIN/"
    chmod +x "$BIN/rg"
  fi
else
  echo "[2/5] ripgrep already installed: $(rg --version | head -1)"
fi

# ── 3. fd ─────────────────────────────────────────────────────────────────────
if ! exists fd; then
  if [ "$OS" = "Darwin" ]; then
    echo "[3/5] Installing fd via Homebrew..."
    brew install fd
  else
    echo "[3/5] Installing fd..."
    FD_VER="v10.2.0"
    curl -fsSL "https://github.com/sharkdp/fd/releases/download/${FD_VER}/fd-${FD_VER}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C /tmp/
    cp "/tmp/fd-${FD_VER}-x86_64-unknown-linux-musl/fd" "$BIN/"
    chmod +x "$BIN/fd"
  fi
else
  echo "[3/5] fd already installed: $(fd --version | head -1)"
fi

# ── 4. PATH configuration ─────────────────────────────────────────────────────
# Only add if not already in PATH
if [[ ":$PATH:" != *":$BIN:"* ]]; then
  SHELL_RC="$HOME/.bashrc"
  # On macOS, zsh is the default. Check for both.
  if [ "$OS" = "Darwin" ]; then
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
  fi
  
  if ! grep -q '\.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "[4/5] Added ~/.local/bin to PATH in $SHELL_RC"
  else
    echo "[4/5] PATH already configured in $SHELL_RC"
  fi
else
  echo "[4/5] ~/.local/bin already in current PATH"
fi
export PATH="$BIN:$PATH"

# ── 5. LazyVim config + plugins ───────────────────────────────────────────────
echo "[5/5] Setting up Neovim config..."

# Ensure ~/.config exists
mkdir -p "$HOME/.config"

# Backup existing config if it's not already our symlink
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  → Backed up existing config"
fi

# Symlink our config
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
echo "  → Linked $DOTFILES/nvim → ~/.config/nvim"

# Find nvim binary (either local or system)
NVIM_CMD="$(command -v nvim)"

# Bootstrap plugins
echo "  → Installing LazyVim plugins (this takes a minute)..."
"$NVIM_CMD" --headless "+Lazy! sync" +qa 2>&1 | grep -E "Installed|Error|error" || true

# Install clangd
echo "  → Installing clangd via Mason..."
"$NVIM_CMD" --headless \
  -c "lua require('mason-registry').refresh()" \
  -c "MasonInstall clangd" \
  +qa 2>&1 | grep -E "clangd|Error|error" || true

echo ""
echo "Done! Open a new shell and run: nvim"
