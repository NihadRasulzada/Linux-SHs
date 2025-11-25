#!/usr/bin/env bash
set -e

echo "🚀 Dotnet Analyzer Installer"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="dotnet_analyzer"

# Python skriptini tap
SCRIPT_PATH="$(pwd)/dotnet_analyzer.py"

# Python3 yoxla
if ! command -v python3 &> /dev/null; then
  echo "⚠️  python3 quraşdırılmayıb, əlavə olunur..."
  sudo apt update && sudo apt install -y python3 python3-pip
fi

# dotnet yoxla
if ! command -v dotnet &> /dev/null; then
  echo "⚠️  .NET SDK tapılmadı, əlavə olunur..."
  sudo apt update && sudo apt install -y dotnet-sdk-8.0
fi

# Ollama yoxla
if ! command -v ollama &> /dev/null; then
  echo "⚠️  Ollama tapılmadı, əlavə olunur..."
  curl -fsSL https://ollama.ai/install.sh | sh
fi

# Model yoxla
if ! ollama list | grep -q "qwen2.5-coder:32b"; then
  echo "📦 Qwen2.5-Coder:32B modeli yüklənir..."
  ollama pull qwen2.5-coder:32b
fi

# Global symlink
sudo cp "$SCRIPT_PATH" "$INSTALL_DIR/$SCRIPT_NAME"
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "✅ Quraşdırma tamamlandı!"
echo "İstifadə etmək üçün sadəcə yaz:"
echo "   dotnet_analyzer"
