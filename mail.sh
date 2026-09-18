#!/usr/bin/env bash
# ==============================================================================
#            BASTION TEMP-MAIL — PRIVATE INBUCKET SETUP SCRIPT
# ==============================================================================

set -uo pipefail

C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${C_CYAN}${C_BOLD}"
cat << 'EOF'
  ███╗   ███╗ █████╗ ██╗██╗     
  ████╗ ████║██╔══██╗██║██║     
  ██╔████╔██║███████║██║██║     
  ██║╚██╔╝██║██╔══██║██║██║     
  ██║ ╚═╝ ██║██║  ██║██║███████╗
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝
EOF
echo -e "${C_GREEN}   >> Private Temp-Mail Deployer (Anti-Spam & Domain-Locked) <<${NC}\n"

# Verify root
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}[!] Please run as root!${NC}"
    exit 1
fi

DOMAIN="nnmail.mooo.com"
echo -e -n "${C_YELLOW}⚡ Enter your mail domain ${C_CYAN}[Press Enter for: ${DOMAIN}]${NC}: "
read -r input </dev/tty
if [ -n "$input" ]; then
    DOMAIN="$input"
fi

WEB_PORT="9000"
echo -e -n "${C_YELLOW}⚡ Web UI Port ${C_CYAN}[Press Enter for: ${WEB_PORT}]${NC}: "
read -r input_port </dev/tty
if [ -n "$input_port" ]; then
    WEB_PORT="$input_port"
fi

echo ""
echo -e "${C_CYAN}>>> [1/4] Stopping old containers & freeing port 25...${NC}"
docker stop inbucket 2>/dev/null || true
docker rm inbucket 2>/dev/null || true

# Free port 25 from any host mail services (postfix/exim)
systemctl stop postfix exim4 sendmail 2>/dev/null || true
systemctl disable postfix exim4 sendmail 2>/dev/null || true
fuser -k 25/tcp 2>/dev/null || true

echo -e "${C_CYAN}>>> [2/4] Ensuring Docker is installed and running...${NC}"
if ! command -v docker &>/dev/null; then
    echo -e "${C_YELLOW}  -> Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker --now
fi

echo -e "${C_CYAN}>>> [3/4] Launching clean Inbucket locked to ${DOMAIN}...${NC}"
docker run -d \
  --name inbucket \
  --restart always \
  -p 25:2500 \
  -p "${WEB_PORT}:9000" \
  -e INBUCKET_SMTP_DOMAINS="${DOMAIN}" \
  -e INBUCKET_STORAGE_RETENTIONPERIOD="48h" \
  -e INBUCKET_STORAGE_MAILBOXCOUNT=1000 \
  inbucket/inbucket:latest

echo -e "${C_CYAN}>>> [4/4] Updating firewall (UFW)...${NC}"
if command -v ufw &>/dev/null; then
    ufw allow 25/tcp comment "Inbucket SMTP" >/dev/null 2>&1 || true
    ufw allow "${WEB_PORT}/tcp" comment "Inbucket Web" >/dev/null 2>&1 || true
    ufw reload >/dev/null 2>&1 || true
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "103.102.229.97")

echo ""
echo -e "${C_GREEN}${C_BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${C_GREEN}${C_BOLD}║           PRIVATE TEMP-MAIL DEPLOYED SUCCESSFULLY!               ║${NC}"
echo -e "${C_GREEN}${C_BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  🌐 Web Interface:     ${C_CYAN}http://${DOMAIN}:${WEB_PORT}${NC}"
echo -e "  🔗 Direct IP Link:     ${C_CYAN}http://${SERVER_IP}:${WEB_PORT}${NC}"
echo -e "  🛡️ Allowed Domain:     ${C_GREEN}@${DOMAIN}${NC} (all spam to IP is blocked!)"
echo -e "  ⏱️ Mail Retention:     ${C_YELLOW}48 hours (auto-purge)${NC}"
echo ""
echo -e "${C_YELLOW}${C_BOLD}Как использовать для регистрации:${NC}"
echo -e "  1. Вводите на сайтах любой адрес: ${C_GREEN}mycode@${DOMAIN}${NC}"
echo -e "  2. Откройте в браузере: ${C_CYAN}http://${DOMAIN}:${WEB_PORT}${NC}"
echo -e "  3. Вбейте в поиск: ${C_GREEN}mycode${NC} — письмо будет там мгновенно!"
echo ""
