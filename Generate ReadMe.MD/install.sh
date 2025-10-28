#!/bin/bash

# ---------------------------
# Idempotent global install script for enhanced generate-readme
# ---------------------------

# 1️⃣ Skriptin yerləşdiyi direktoriyadan fayl adı
MAIN_SCRIPT="generate-readme-github-auto.sh"
GLOBAL_DIR="/usr/local/bin"
GLOBAL_SCRIPT="$GLOBAL_DIR/generate-readme"

# 2️⃣ Check if main script exists in current directory
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "❌ $MAIN_SCRIPT not found in current directory!"
    exit 1
fi

# 3️⃣ Copy script to global directory (overwrite if exists)
sudo cp "$MAIN_SCRIPT" "$GLOBAL_SCRIPT"

# 4️⃣ Make it executable
sudo chmod +x "$GLOBAL_SCRIPT"

# 5️⃣ Confirm installation
echo "✅ '$MAIN_SCRIPT' installed globally as 'generate-readme'"

# 6️⃣ Info message about idempotency
echo "ℹ️ You can safely run install.sh multiple times. Global script is ready."
echo "Use it in any git repository with:"
echo "   generate-readme"

# 7️⃣ Optional: Verify installation
if command -v generate-readme >/dev/null 2>&1; then
    echo "✅ Verification passed: 'generate-readme' is executable globally."
else
    echo "⚠️ Verification failed: 'generate-readme' not found in PATH."
fi
