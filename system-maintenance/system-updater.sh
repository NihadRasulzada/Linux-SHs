#!/bin/bash
set -euo pipefail
MODE=${1:-server}
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}[1/5] APT yenilənməsi...${NC}"
apt update -y && apt full-upgrade -y
apt autoremove -y && apt autoclean -y && apt clean -y

echo -e "${YELLOW}[2/5] Snap və Flatpak yenilənməsi...${NC}"
command -v snap &>/dev/null && snap refresh || true
command -v flatpak &>/dev/null && flatpak update -y || true

echo -e "${YELLOW}[3/5] Kernel yeniləməsi yoxlanır...${NC}"
if [ -f /var/run/reboot-required ]; then
  echo "🔄 Yenidən başlatma tələb olunur."
  if [ "$MODE" = "server" ]; then
    echo "💡 Server yenidən başladılır..."
    reboot
  else
    echo "ℹ️ Desktop sistemdə əl ilə reboot edin."
  fi
fi

