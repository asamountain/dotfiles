#!/usr/bin/env bash
# bootstrap.sh — set up Neovim + LazyVim + clangd on any Linux (no sudo needed)
set -e

DOTFILES="$HOME/.dotfiles"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

# ── 1. Neovim (AppImage, extracted for WSL2 / no-FUSE envs) ──────────────────
if ! "$BIN/nvim" --version 2>/dev/null | grep -q "NVIM v0\.[9-9]\|NVIM v[1-9]"; then
  echo "[1/5] Installing Neovim..."
  curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage \
    -o /tmp/nvim.appimage
  chmod +x /tmp/nvim.appimage
  cd /tmp && /tmp/nvim.appimage --appimage-extract > /dev/null 2>&1
  rm -rf "$HOME/.local/nvim-appimage"
  cp -r /tmp/squashfs-root "$HOME/.local/nvim-appimage"
  ln -sf "$HOME/.local/nvim-appimage/usr/bin/nvim" "$BIN/nvim"
  echo "  → Neovim $("$BIN/nvim" --version | head -1) installed"
else
  echo "[1/5] Neovim already installed, skipping"
fi

# ── 2. ripgrep ────────────────────────────────────────────────────────────────
if ! "$BIN/rg" --version > /dev/null 2>&1; then
  echo "[2/5] Installing ripgrep..."
  RG_VER="14.1.1"
  curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz" \
    | tar xz -C /tmp/
  cp "/tmp/ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" "$BIN/"
  chmod +x "$BIN/rg"
  echo "  → $("$BIN/rg" --version | head -1) installed"
else
  echo "[2/5] ripgrep already installed, skipping"
fi

# ── 3. fd ─────────────────────────────────────────────────────────────────────
if ! "$BIN/fd" --version > /dev/null 2>&1; then
  echo "[3/5] Installing fd..."
  FD_VER="v10.2.0"
  curl -fsSL "https://github.com/sharkdp/fd/releases/download/${FD_VER}/fd-${FD_VER}-x86_64-unknown-linux-musl.tar.gz" \
    | tar xz -C /tmp/
  cp "/tmp/fd-${FD_VER}-x86_64-unknown-linux-musl/fd" "$BIN/"
  chmod +x "$BIN/fd"
  echo "  → $("$BIN/fd" --version) installed"
else
  echo "[3/5] fd already installed, skipping"
fi

# ── 4. PATH in .bashrc ────────────────────────────────────────────────────────
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "[4/5] Added ~/.local/bin to PATH in .bashrc"
else
  echo "[4/5] PATH already configured, skipping"
fi
export PATH="$BIN:$PATH"

# ── 5. LazyVim config + plugins ───────────────────────────────────────────────
echo "[5/5] Setting up Neovim config..."

# Backup existing config if it's not already our symlink
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"
  echo "  → Backed up existing config"
fi

# Symlink our config
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"
echo "  → Linked $DOTFILES/nvim → ~/.config/nvim"

# Bootstrap plugins
echo "  → Installing LazyVim plugins (this takes a minute)..."
"$BIN/nvim" --headless "+Lazy! sync" +qa 2>&1 | grep -E "Installed|Error|error" || true

# Install clangd
echo "  → Installing clangd via Mason..."
"$BIN/nvim" --headless \
  -c "lua require('mason-registry').refresh()" \
  -c "MasonInstall clangd" \
  +qa 2>&1 | grep -E "clangd|Error|error" || true

echo ""
echo "Done! Open a new shell and run: nvim"
