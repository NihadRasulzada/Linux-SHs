#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
LOGFILE="/var/log/system-updater.log"

# Root yoxlaması
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Zəhmət olmasa skripti sudo ilə işə salın.${NC}"
  exit 1
fi

exec > >(tee -a "$LOGFILE") 2>&1

echo -e "${GREEN}--- $(hostname) sistem yenilənməsi başlayır ---${NC}"
date
echo

echo -e "${GREEN}[1/6] APT yenilənməsi...${NC}"
apt update && apt full-upgrade -y

echo -e "${GREEN}[2/6] Snap paketləri yenilənir...${NC}"
snap refresh || echo "Snap tapılmadı və ya quraşdırılmayıb."

echo -e "${GREEN}[3/6] Flatpak paketləri yenilənir...${NC}"
if command -v flatpak &>/dev/null; then
  flatpak update -y
  flatpak uninstall --unused -y
else
  echo "Flatpak quraşdırılmayıb."
fi

echo -e "${GREEN}[4/6] Lazımsız paketlər silinir...${NC}"
apt autoremove -y
apt autoclean -y
apt clean

echo -e "${GREEN}[5/6] Sistem log faylları təmizlənir...${NC}"
journalctl --vacuum-time=7d

echo -e "${GREEN}[6/6] Cache faylları təmizlənir...${NC}"
rm -rf ~/.cache/thumbnails/* || true

echo -e "\n${GREEN}✅ Sistem uğurla yeniləndi və təmizləndi!${NC}"
echo "Log: $LOGFILE"

