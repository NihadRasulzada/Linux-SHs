#!/bin/bash

# Qlobal script üçün direktoriyanı təyin et
INSTALL_DIR="$HOME/bin"
SCRIPT_NAME="git-auto.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# 1. bin qovluğunu yoxla, yoxdursa yarat
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating directory $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
fi

# 2. git-auto.sh script-i həmin qovluğa kopyala (əgər artıq varsa overwrite et)
if [ ! -f "./$SCRIPT_NAME" ]; then
  echo "Error: $SCRIPT_NAME not found in current directory."
  exit 1
fi

cp "./$SCRIPT_NAME" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "$SCRIPT_NAME installed to $SCRIPT_PATH"

# 3. PATH-də olub olmadığını yoxla, əgər yoxdursa əlavə et
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Adding $INSTALL_DIR to PATH in .bashrc, .zshrc, and Fish config..."

  # Bash üçün
  if [ -f "$HOME/.bashrc" ]; then
    grep -qxF "export PATH=\$PATH:$INSTALL_DIR" "$HOME/.bashrc" || \
      echo "export PATH=\$PATH:$INSTALL_DIR" >> "$HOME/.bashrc"
  fi

  # Zsh üçün
  if [ -f "$HOME/.zshrc" ]; then
    grep -qxF "export PATH=\$PATH:$INSTALL_DIR" "$HOME/.zshrc" || \
      echo "export PATH=\$PATH:$INSTALL_DIR" >> "$HOME/.zshrc"
  fi

  # Fish üçün
  if [ -f "$HOME/.config/fish/config.fish" ]; then
    grep -qxF "set -U fish_user_paths $INSTALL_DIR \$fish_user_paths" "$HOME/.config/fish/config.fish" || \
      echo "set -U fish_user_paths $INSTALL_DIR \$fish_user_paths" >> "$HOME/.config/fish/config.fish"
  fi

  # PATH-i bu sessiyaya əlavə et
  export PATH=$PATH:$INSTALL_DIR
fi

# Fish üçün terminalı yeniləmək
echo "Reloading Fish config..."
if command -v fish &> /dev/null; then
  exec fish
fi

echo "Installation complete. You can now run '$SCRIPT_NAME' from any directory."
echo "If new terminal session is opened, PATH will be automatically set."

