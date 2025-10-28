#!/bin/bash

# ---------------------------
# Idempotent global install script for enhanced generate-readme
# ---------------------------

MAIN_SCRIPT="generate-readme-github-auto.sh"
GLOBAL_DIR="/usr/local/bin"
GLOBAL_SCRIPT="$GLOBAL_DIR/generate-readme"

echo "🔧 Checking for dependencies..."

# 1️⃣ gawk yoxdursa, avtomatik quraşdır
if ! command -v gawk >/dev/null 2>&1; then
    echo "📦 'gawk' not found. Installing..."
    sudo apt update -y && sudo apt install gawk -y
else
    echo "✅ 'gawk' is already installed."
fi

# 2️⃣ ollama yoxdursa xəbərdarlıq
if ! command -v ollama >/dev/null 2>&1; then
    echo "⚠️ 'ollama' is not installed!"
    echo "Please install Ollama manually from: https://ollama.com/download"
    exit 1
else
    echo "✅ 'ollama' is installed."
fi

# 3️⃣ Check if main script exists in current directory
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "❌ $MAIN_SCRIPT not found in current directory!"
    exit 1
fi

# 4️⃣ Copy script to global directory (overwrite if exists)
sudo cp "$MAIN_SCRIPT" "$GLOBAL_SCRIPT"

# 5️⃣ Make it executable
sudo chmod +x "$GLOBAL_SCRIPT"

# 6️⃣ Confirm installation
echo "✅ '$MAIN_SCRIPT' installed globally as 'generate-readme'"

# 7️⃣ Info message about idempotency
echo "ℹ️ You can safely run install.sh multiple times."
echo "Use it in any git repository with:"
echo "   generate-readme"

# 8️⃣ Optional: Verify installation
if command -v generate-readme >/dev/null 2>&1; then
    echo "✅ Verification passed: 'generate-readme' is executable globally."
else
    echo "⚠️ Verification failed: 'generate-readme' not found in PATH."
fi
