#!/bin/bash
set -euo pipefail
MODE=${1:-server}
YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}[1/3] Sistem cache təmizlənir...${NC}"
rm -rf ~/.cache/thumbnails/* ~/.cache/*trash* /tmp/* 2>/dev/null || true

echo -e "${YELLOW}[2/3] Log faylları təmizlənir...${NC}"
journalctl --vacuum-time=7d
rm -rf /var/log/*.gz /var/log/*.[0-9] 2>/dev/null || true

echo -e "${YELLOW}[3/3] Docker və Snap cache...${NC}"
command -v docker &>/dev/null && docker system prune -af --volumes || true
rm -rf /var/lib/snapd/cache/* 2>/dev/null || true
