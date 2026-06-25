#!/bin/bash
set -e

# whisper-dictation — one-command setup
# https://github.com/YOUR_USER/whisper-dictation

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/whisper-dictation"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
MODEL_DIR="$INSTALL_DIR/models"
MODEL="small.en"
REPO="https://github.com/ggerganov/whisper.cpp.git"
SHORTCUT="<Control><Alt>space"

echo "==> whisper-dictation setup"
echo "    Installing to: $INSTALL_DIR"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  OS=$(uname -s)
fi

# Install system dependencies
install_deps() {
  if command -v apt &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq git cmake build-essential wget ydotool
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm git cmake base-devel wget ydotool
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y git cmake gcc-c++ wget ydotool
  else
    echo "Warning: unsupported package manager. Ensure git, cmake,"
    echo "         build tools, wget, and ydotool are installed."
  fi
}

# Build whisper.cpp
build_whisper() {
  if [ -f "$INSTALL_DIR/bin/whisper-cli" ]; then
    echo "==> whisper-cli already built, skipping"
    return
  fi

  echo "==> Building whisper.cpp..."
  local TMPDIR
  TMPDIR=$(mktemp -d)
  git clone --depth 1 "$REPO" "$TMPDIR/whisper.cpp"

  cmake -B "$TMPDIR/whisper.cpp/build" -S "$TMPDIR/whisper.cpp" \
    -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON \
    -DCMAKE_BUILD_TYPE=Release

  cmake --build "$TMPDIR/whisper.cpp/build" -j"$(nproc)" --target whisper-cli

  mkdir -p "$INSTALL_DIR/bin"
  cp "$TMPDIR/whisper.cpp/build/bin/whisper-cli" "$INSTALL_DIR/bin/"
  rm -rf "$TMPDIR"
}

# Download model
download_model() {
  if [ -f "$MODEL_DIR/ggml-$MODEL.bin" ]; then
    echo "==> Model already downloaded, skipping"
    return
  fi

  echo "==> Downloading $MODEL model (~466 MB)..."
  mkdir -p "$MODEL_DIR"

  if command -v curl &>/dev/null; then
    curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$MODEL.bin" \
      -o "$MODEL_DIR/ggml-$MODEL.bin"
  else
    wget -c "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$MODEL.bin" \
      -O "$MODEL_DIR/ggml-$MODEL.bin"
  fi
}

# Install toggle script
install_script() {
  mkdir -p "$BIN_DIR"
  cp "$(dirname "$0")/whisper-dictation" "$BIN_DIR/whisper-dictation"
  chmod +x "$BIN_DIR/whisper-dictation"

  # Update paths in the script
  sed -i "s|WHISPER=.*|WHISPER=\"$INSTALL_DIR/bin/whisper-cli\"|" "$BIN_DIR/whisper-dictation"
  sed -i "s|MODEL=.*|MODEL=\"$MODEL_DIR/ggml-$MODEL.bin\"|" "$BIN_DIR/whisper-dictation"

  # Add to PATH if needed
  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.profile"
    echo "==> Added $BIN_DIR to PATH in ~/.bashrc"
  fi
}

# Enable ydotoold service
setup_ydotoold() {
  if command -v ydotoold &>/dev/null; then
    systemctl --user enable ydotoold --now 2>/dev/null || true
    echo "==> ydotoold service enabled and started"
  fi
}

# Set GNOME keyboard shortcut
setup_shortcut() {
  local KEY="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whisper-dictation"
  local CMD="$BIN_DIR/whisper-dictation"

  # Read existing custom bindings
  local EXISTING
  EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "[]")

  # Add our binding if not already present
  if echo "$EXISTING" | grep -q "whisper-dictation"; then
    dconf write "$KEY/command" "'$CMD'"
    dconf write "$KEY/binding" "'$SHORTCUT'"
    dconf write "$KEY/name" "'Dictation'"
  else
    local NEW
    NEW=$(echo "$EXISTING" | sed "s/\]/, '$KEY\/']/" | sed "s/\[, /[/")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW"
    dconf write "$KEY/command" "'$CMD'"
    dconf write "$KEY/binding" "'$SHORTCUT'"
    dconf write "$KEY/name" "'Dictation'"
  fi
  echo "==> Keyboard shortcut set: Ctrl+Alt+Space"
}

# --- Main ---
install_deps
build_whisper
download_model
install_script
setup_ydotoold

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
  setup_shortcut
fi

echo ""
echo "============================================="
echo "  whisper-dictation installed!"
echo ""
echo "  Press Ctrl+Alt+Space to toggle dictation."
echo "  Run 'whisper-dictation' from terminal."
echo ""
echo "  First, make sure ydotoold is running:"
echo "    systemctl --user restart ydotoold"
echo "============================================="
