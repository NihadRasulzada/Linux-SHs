#!/bin/bash
set -euo pipefail
YELLOW='\033[1;33m'; NC='\033[0m'
BACKUP_DIR="/backup/$(date +%F_%H-%M)"

echo -e "${YELLOW}[1/2] Backup yaradılır...${NC}"
mkdir -p "$BACKUP_DIR"
rsync -a --delete /etc "$BACKUP_DIR/etc"
rsync -a /home "$BACKUP_DIR/home"
rsync -a /var/www "$BACKUP_DIR/www" 2>/dev/null || true

echo -e "${YELLOW}[2/2] Backup tamamlandı: $BACKUP_DIR${NC}"
