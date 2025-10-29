#!/bin/bash
set -euo pipefail
YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${YELLOW}[1/3] SSH təhlükəsizliyi yoxlanır...${NC}"
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
  echo -e "${RED}⚠️ Root SSH girişi aktivdir.${NC}"
else
  echo -e "${GREEN}✅ Root SSH girişi bağlıdır.${NC}"
fi

echo -e "${YELLOW}[2/3] Firewall vəziyyəti...${NC}"
ufw status || echo "⚠️ UFW aktiv deyil."

echo -e "${YELLOW}[3/3] Fail2ban yoxlanır...${NC}"
systemctl is-active --quiet fail2ban && echo "✅ Fail2ban aktivdir." || echo "⚠️ Fail2ban aktiv deyil."
