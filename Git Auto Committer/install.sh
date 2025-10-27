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

# 2. git-auto.sh script-i həmin qovluğa kopyala
# Qeyd: git-auto.sh eyni qovluqda yerləşməlidir
if [ ! -f "./$SCRIPT_NAME" ]; then
  echo "Error: $SCRIPT_NAME not found in current directory."
  exit 1
fi

cp "./$SCRIPT_NAME" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "$SCRIPT_NAME installed to $SCRIPT_PATH"

# 3. PATH-də olub olmadığını yoxla
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Warning: $INSTALL_DIR is not in your PATH."
  echo "You can add it by running:"
  echo "  export PATH=\$PATH:$INSTALL_DIR"
fi

echo "Installation complete. You can now run '$SCRIPT_NAME' from any directory."
