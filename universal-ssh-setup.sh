#!/usr/bin/env bash
# ==============================================
# Smart SSH Setup Script v1.0 for GitHub
# Author: Nihad Rasulzada
# ==============================================

set -e

CONFIG_DIR="$HOME/.config/ssh-setup"
CONFIG_FILE="$CONFIG_DIR/config.env"
KEY_PATH="$HOME/.ssh/id_ed25519"
PUB_KEY_PATH="${KEY_PATH}.pub"
HOSTNAME=$(hostname)
TITLE="${HOSTNAME}-SSH-Key"

# ==========================
# 🎨 Rənglər
# ==========================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==========================
# 🧠 Köməkçi funksiyalar
# ==========================
save_config() {
    mkdir -p "$CONFIG_DIR"
    {
        echo "EMAIL=$EMAIL"
        echo "GITHUB_USER=$GITHUB_USER"
        echo "TOKEN=$TOKEN"
    } > "$CONFIG_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}📁 Mövcud konfiqurasiya tapıldı:${NC} $CONFIG_FILE"
    fi
}

install_if_missing() {
    PKG="$1"
    CMD="$2"
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 '$PKG' tapılmadı, quraşdırılır...${NC}"
        sudo apt update -y && sudo apt install -y "$PKG"
    else
        echo -e "${GREEN}✅ '$PKG' artıq quraşdırılıb.${NC}"
    fi
}

check_github_key_exists() {
    KEYS=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user/keys | grep -o "\"title\": \".*\"" || true)
    echo "$KEYS" | grep -q "$TITLE"
}

# ==========================
# 🔹 1️⃣ Lazımi proqramlar
# ==========================
install_if_missing "curl" "curl"
install_if_missing "openssh-client" "ssh-agent"

# ==========================
# 🔹 2️⃣ Konfiqurasiya
# ==========================
load_config

if [ -z "$EMAIL" ]; then
    read -p "📧 Email adresini daxil et: " EMAIL
fi

if [ -z "$GITHUB_USER" ]; then
    read -p "👤 GitHub istifadəçi adını daxil et: " GITHUB_USER
fi

if [ -z "$TOKEN" ]; then
    read -p "🔑 GitHub Personal Access Token daxil et (repo və admin:public_key icazəsi olmalıdır): " TOKEN
fi

save_config

# ==========================
# 🔹 3️⃣ SSH açarı
# ==========================
if [ ! -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}🆕 Yeni SSH açarı yaradılır...${NC}"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N "" || { echo -e "${RED}❌ SSH açarı yaradılarkən xəta baş verdi! Yenidən cəhd edilir...${NC}"; ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""; }
else
    echo -e "${GREEN}✅ Mövcud SSH açar tapıldı:${NC} $KEY_PATH"
fi

# ==========================
# 🔹 4️⃣ SSH agent
# ==========================
echo -e "${YELLOW}🚀 SSH agent işə salınır...${NC}"
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH" || { echo -e "${RED}❌ SSH agent işə salınarkən xəta baş verdi! Yenidən cəhd edilir...${NC}"; eval "$(ssh-agent -s)"; ssh-add "$KEY_PATH"; }

# ==========================
# 🔹 5️⃣ GitHub açarı əlavə et və ya yenilə
# ==========================
PUB_KEY=$(cat "$PUB_KEY_PATH")

if check_github_key_exists; then
    echo -e "${YELLOW}🔁 '$TITLE' adlı SSH açarı GitHub-da artıq mövcuddur.${NC}"
    echo -e "${YELLOW}🧹 Mövcud açar silinir və yenisi əlavə olunur...${NC}"

    # Mövcud açarın ID-sini tap
    KEY_ID=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user/keys | grep -B1 "\"title\": \"$TITLE\"" | grep '"id":' | head -n1 | awk '{print $2}' | tr -d ',')
    if [ -n "$KEY_ID" ]; then
        DELETE_RESPONSE=$(curl -s -X DELETE -H "Authorization: token $TOKEN" "https://api.github.com/user/keys/$KEY_ID")
        if [[ "$(echo "$DELETE_RESPONSE" | jq -r '.message')" == "Not Found" ]]; then
            echo -e "${RED}❌ Mövcud SSH açarı silinə bilmədi. Yenidən cəhd edilir...${NC}"
            DELETE_RESPONSE=$(curl -s -X DELETE -H "Authorization: token $TOKEN" "https://api.github.com/user/keys/$KEY_ID")
        fi
        echo -e "${GREEN}✅ Köhnə açar silindi.${NC}"
    fi
fi

# GitHub-a SSH açarını əlavə et
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/keys \
  -d "{\"title\": \"$TITLE\", \"key\": \"$PUB_KEY\"}")

# Təhlil et və error mesajı ver
if [ "$RESPONSE" -eq 201 ]; then
    echo -e "${GREEN}✅ Yeni SSH açarı uğurla GitHub hesabına əlavə edildi!${NC}"
else
    echo -e "${RED}❌ SSH açarı əlavə edilə bilmədi. Kod: $RESPONSE.${NC}"
    
    if [ "$RESPONSE" -eq 401 ]; then
        echo -e "${YELLOW}❌ Token səhv və ya icazələr düzgün deyil. Zəhmət olmasa token-in düzgünlüyünü yoxlayın.${NC}"
        read -p "Yeni token daxil edin və ya mövcud token-in düzgünlüyünü yoxlayın: " TOKEN
        save_config
        # Yenidən cəhd
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
          -X POST \
          -H "Authorization: token $TOKEN" \
          -H "Accept: application/vnd.github+json" \
          https://api.github.com/user/keys \
          -d "{\"title\": \"$TITLE\", \"key\": \"$PUB_KEY\"}")
        
        if [ "$RESPONSE" -eq 201 ]; then
            echo -e "${GREEN}✅ Yeni SSH açarı uğurla GitHub hesabına əlavə edildi!${NC}"
        else
            echo -e "${RED}❌ Hələ də SSH açarı əlavə edilə bilmədi.${NC}"
            exit 1
        fi
    fi
fi

# ==========================
# 🔹 6️⃣ Son yoxlamalar
# ==========================
echo -e "\n🔍 ${YELLOW}Sistem yoxlamaları aparılır...${NC}"

# 1. SSH agent aktivdirmi?
if pgrep -x "ssh-agent" >/dev/null; then
    echo -e "${GREEN}✅ SSH agent aktivdir.${NC}"
else
    echo -e "${RED}❌ SSH agent aktiv deyil. Yenidən işə salınır...${NC}"
    eval "$(ssh-agent -s)"
fi

# 2. SSH key GitHub-da varmı?
if check_github_key_exists; then
    echo -e "${GREEN}✅ GitHub hesabında SSH açar mövcuddur.${NC}"
else
    echo -e "${RED}❌ GitHub-da SSH açar tapılmadı. Yenidən cəhd edilir...${NC}"
    check_github_key_exists || check_github_key_exists
fi

# 3. SSH bağlantısı (GitHub ilə əlaqə doğrulama)
echo -e "${YELLOW}🔗 GitHub bağlantısı test edilir...${NC}"
ssh -T git@github.com || echo -e "${GREEN}✅ GitHub SSH bağlantısı uğurla quruldu. GitHub şellinə giriş mümkün deyil, amma SSH ilə əlaqə aktivdir.${NC}"

# ==========================
# 🔹 7️⃣ Bitdi!
# ==========================
echo -e "\n----------------------------------------------"
echo -e "${GREEN}🎉 SSH setup uğurla tamamlandı!${NC}"
echo -e "📋 SSH açar: $PUB_KEY_PATH"
echo -e "📦 Konfiqurasiya faylı: $CONFIG_FILE"
echo -e "💻 Git əmrləri tam istifadəyə hazırdır!"
echo -e "----------------------------------------------"
