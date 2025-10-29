#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Root yoxlaması
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Zəhmət olmasa sudo ilə işə salın.${NC}"
  exit 1
fi

# Sistem növünü müəyyən et
if [ -n "${DISPLAY:-}" ]; then
  MODE="desktop"
else
  MODE="server"
fi

echo -e "${YELLOW}🧠 Sistem növü aşkarlandı: ${MODE}${NC}"
echo

MODULE_DIR="$(dirname "$(realpath "$0")")"

bash "$MODULE_DIR/system-updater.sh" "$MODE"
bash "$MODULE_DIR/system-cleaner.sh" "$MODE"
bash "$MODULE_DIR/system-report.sh" "$MODE"

if [ "$MODE" = "server" ]; then
  bash "$MODULE_DIR/system-security.sh"
  bash "$MODULE_DIR/system-backup.sh"
fi

echo -e "\n${GREEN}✅ Bütün əməliyyatlar uğurla tamamlandı!${NC}"
