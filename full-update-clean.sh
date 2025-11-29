#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
LOGFILE="/var/log/system-updater.log"

# Ensure log file exists
touch "$LOGFILE"

# Root yoxlaması
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Zəhmət olmasa skripti sudo ilə işə salın.${NC}"
  exit 1
fi

exec > >(tee -a "$LOGFILE") 2>&1

echo -e "${GREEN}--- $(hostname) sistem yenilənməsi başlayır ---${NC}"
date
echo

# [1/6] APT yenilənməsi
echo -e "${GREEN}[1/6] APT yenilənməsi...${NC}"
if ! apt update &>/dev/null; then
  echo -e "${RED}APT yenilənməsi uğursuz oldu.${NC}"
  exit 1
fi

if ! apt full-upgrade -y &>/dev/null; then
  echo -e "${RED}APT yeniləmə tamamlanmadı.${NC}"
  exit 1
fi

echo -e "${GREEN}[2/6] Snap paketləri yenilənir...${NC}"
if command -v snap &>/dev/null; then
  snap refresh || echo "Snap tapılmadı və ya quraşdırılmayıb."
else
  echo "Snap quraşdırılmayıb."
fi

echo -e "${GREEN}[3/6] Flatpak paketləri yenilənir...${NC}"
if command -v flatpak &>/dev/null; then
  flatpak update -y
  flatpak uninstall --unused -y
else
  echo "Flatpak quraşdırılmayıb."
fi

echo -e "${GREEN}[4/6] Lazımsız paketlər silinir...${NC}"
if ! apt autoremove -y; then
  echo -e "${RED}Lazımsız paketlərin silinməsi uğursuz oldu.${NC}"
  exit 1
fi
apt autoclean -y
apt clean

echo -e "${GREEN}[5/6] Sistem log faylları təmizlənir...${NC}"
if ! journalctl --vacuum-time=7d; then
  echo -e "${RED}Sistem loglarının təmizlənməsi uğursuz oldu.${NC}"
  exit 1
fi

echo -e "${GREEN}[6/6] Cache faylları təmizlənir...${NC}"
rm -rf ~/.cache/thumbnails/* || true

echo -e "\n${GREEN}✅ Sistem uğurla yeniləndi və təmizləndi!${NC}"
echo "Log: $LOGFILE"
exit 0
