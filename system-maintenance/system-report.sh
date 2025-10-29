#!/bin/bash
set -euo pipefail
YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}📊 Sistem Məlumatı${NC}"
echo "Host: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
echo "RAM istifadəsi: $(free -h | awk '/Mem/{print $3 "/" $2}')"
echo "Disk istifadəsi: $(df -h / | awk 'NR==2 {print $5}')"
echo "IP-lər:"
ip -4 addr show | grep "inet " | awk '{print " - " $2}'
echo
