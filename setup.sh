#!/usr/bin/env bash
# ==============================================================================
#            SERVER SHIELD — LINUX VPS HARDENING & OPTIMIZATION
#         Modes: [1] Automatic | [2] Manual Wizard | [3] AI (Gemini Flash)
# ==============================================================================

set -uo pipefail

# --- Color Definitions ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
cat << 'EOF'
  ██████╗  █████╗ ███████╗████████╗██╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
  ██████╔╝███████║███████╗   ██║   ██║██║   ██║██╔██╗ ██║
  ██╔══██╗██╔══██║╚════██║   ██║   ██║██║   ██║██║╚██╗██║
  ██████╔╝██║  ██║███████║   ██║   ██║╚██████╔╝██║ ╚████║
  ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${C_MAGENTA}   >> Bastion — Linux VPS Hardening & Optimization Suite <<${NC}"
    echo -e "${C_BLUE}   >> Root Password Mode | Multi-Engine Setup <<${NC}\n"
}

show_finish_banner() {
    clear
    echo -e "${C_GREEN}${C_BOLD}"
cat << 'EOF'
   ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗██╗
  ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝██║
  ██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗  ██║
  ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝  ╚═╝
  ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████╗██╗
   ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝
EOF
    echo -e "${NC}"
}

show_header

# Verify root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}[ERROR] You must run this script as root!${NC}"
    exit 1
fi

# Input prompt helper with Enter-default capability
prompt() {
    local var_name="$1"
    local question="$2"
    local default_val="$3"
    local input

    echo -e -n "${C_YELLOW}⚡ ${C_BOLD}${question}${NC} "
    if [ -n "$default_val" ]; then
        echo -e -n "${C_CYAN}[Press Enter for: ${default_val}]${NC}: "
    else
        echo -e -n "${C_CYAN}[Press Enter to skip]${NC}: "
    fi

    read -r input </dev/tty
    if [ -z "$input" ]; then
        eval "$var_name=\"$default_val\""
    else
        eval "$var_name=\"$input\""
    fi
}

prompt_secret() {
    local var_name="$1"
    local question="$2"
    local input

    echo -e -n "${C_YELLOW}⚡ ${C_BOLD}${question}${NC}: "
    read -s -r input </dev/tty
    echo ""
    eval "$var_name=\"$input\""
}

# ==============================================================================
# MODE SELECTION
# ==============================================================================
echo -e "${C_BOLD}Select Configuration Mode:${NC}"
echo -e "  ${C_CYAN}[1] Automatic${NC}   — Instant deployment with battle-tested security defaults"
echo -e "  ${C_CYAN}[2] Manual${NC}      — Step-by-step interactive questionnaire (with defaults on Enter)"
echo -e "  ${C_CYAN}[3] AI-Powered${NC}  — Powered by Google Gemini Flash (analyzes hardware & workload)"
echo ""

prompt SETUP_MODE "Choose mode (1, 2, or 3)" "1"

# Default Variables
SSH_PORT="22"
SSH_TIMEOUT="300"
OPEN_WEB="y"
EXTRA_PORT=""
F2B_MAXRETRY="3"
F2B_BANTIME="7200"
F2B_FINDTIME="600"
SWAP_SIZE_GB="2"
SWAPPINESS="10"
HARDEN_DEV_SHM="y"
ENABLE_BBR="y"
HARDEN_SYSCTL="y"
ENABLE_AUTO_UPDATES="y"

# ==============================================================================
# MODE LOGIC
# ==============================================================================

if [ "$SETUP_MODE" = "2" ] || [ "$SETUP_MODE" = "manual" ]; then
    # ---------------- MANUAL MODE ----------------
    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 1. SSH CONFIGURATION ]${NC}"
    prompt SSH_PORT "SSH Port (Changing from 22 reduces automated scanning noise)" "22"
    prompt SSH_TIMEOUT "Disconnect idle sessions after how many seconds?" "300"

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 2. FIREWALL (UFW) & PORTS ]${NC}"
    prompt OPEN_WEB "Allow incoming HTTP (80) & HTTPS (443) web ports? (y/n)" "y"
    prompt EXTRA_PORT "Open any additional custom port? (e.g. 3000 or Enter to skip)" ""

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 3. FAIL2BAN BRUTE-FORCE SHIELD ]${NC}"
    prompt F2B_MAXRETRY "Maximum failed password attempts before ban" "3"
    prompt F2B_BANTIME "Ban duration in seconds (7200 = 2 hours, 86400 = 24 hours)" "7200"
    prompt F2B_FINDTIME "Window time in seconds to track failed attempts" "600"

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 4. MEMORY & STORAGE TUNING ]${NC}"
    prompt SWAP_SIZE_GB "Swap file size in Gigabytes (0 to skip)" "2"
    prompt SWAPPINESS "Kernel Swappiness ratio 0-100 (10 = preserve RAM first)" "10"
    prompt HARDEN_DEV_SHM "Mount /dev/shm with 'noexec' to block script exploits? (y/n)" "y"

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 5. KERNEL HARDENING & OPTIMIZATION ]${NC}"
    prompt ENABLE_BBR "Enable Google BBR Congestion Control (Faster network)? (y/n)" "y"
    prompt HARDEN_SYSCTL "Apply kernel security shield (SYN-Flood cookies, anti-spoof)? (y/n)" "y"
    prompt ENABLE_AUTO_UPDATES "Enable automatic background security updates? (y/n)" "y"

elif [ "$SETUP_MODE" = "3" ] || [ "$SETUP_MODE" = "ai" ]; then
    # ---------------- AI-POWERED MODE (GEMINI FLASH) ----------------
    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ AI OPTIMIZATION (GOOGLE GEMINI FLASH) ]${NC}"
    prompt_secret GEMINI_KEY "Enter your Google AI Studio Gemini API Key"
    
    if [ -z "$GEMINI_KEY" ]; then
        echo -e "${C_RED}[!] API key cannot be empty. Falling back to Automatic mode.${NC}"
    else
        prompt WORKLOAD_DESC "What is the primary workload of this server? (e.g., Docker, Web, VPN, Game, General)" "Web Server & General Docker"
        echo -e "${C_BLUE}>>> Gathering server hardware and environment telemetry...${NC}"
        
        TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
        CPU_CORES=$(nproc)
        CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
        DISK_AVAIL_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
        OS_DESC=$(grep -E '^(PRETTY_NAME)=' /etc/os-release | cut -d= -f2 | tr -d '"')

        echo -e "    OS:       ${C_CYAN}${OS_DESC}${NC}"
        echo -e "    CPU:      ${C_CYAN}${CPU_CORES} Cores (${CPU_MODEL})${NC}"
        echo -e "    RAM:      ${C_CYAN}${TOTAL_RAM_MB} MB${NC}"
        echo -e "    Disk Free:${C_CYAN}${DISK_AVAIL_GB} GB${NC}"
        echo -e "${C_BLUE}>>> Contacting Gemini Flash model for tailored optimization...${NC}"

        PROMPT_TEXT="You are an expert Linux Systems and Security Engineer. Analyze this server hardware and workload, and provide the optimal configuration parameters in strict JSON format.
Server Telemetry:
- OS: $OS_DESC
- CPU Cores: $CPU_CORES ($CPU_MODEL)
- Total RAM: $TOTAL_RAM_MB MB
- Disk Free: $DISK_AVAIL_GB GB
- Workload: $WORKLOAD_DESC

Respond ONLY with valid JSON having these exact keys:
{
  \"ssh_port\": 22,
  \"swap_size_gb\": 2,
  \"swappiness\": 10,
  \"open_web\": true,
  \"enable_bbr\": true,
  \"f2b_maxretry\": 3,
  \"f2b_bantime\": 7200,
  \"ai_reasoning\": \"brief 2-sentence summary of recommendations\"
}"

        AI_RAW_RESP=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}" \
            -H "Content-Type: application/json" \
            -d "{
                \"contents\": [{\"parts\": [{\"text\": $(echo -n "$PROMPT_TEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}]}],
                \"generationConfig\": {\"response_mime_type\": \"application/json\"}
            }")

        AI_PARSED=$(python3 -c "
import sys, json
try:
    data = json.loads('''$AI_RAW_RESP''')
    text = data['candidates'][0]['content']['parts'][0]['text']
    conf = json.loads(text)
    print(f\"{conf.get('ssh_port', 22)}|{conf.get('swap_size_gb', 2)}|{conf.get('swappiness', 10)}|{conf.get('open_web', True)}|{conf.get('enable_bbr', True)}|{conf.get('f2b_maxretry', 3)}|{conf.get('f2b_bantime', 7200)}|{conf.get('ai_reasoning', 'Optimized for current hardware')}\")
except Exception as e:
    sys.exit(1)
" 2>/dev/null || true)

        if [ -n "$AI_PARSED" ]; then
            IFS='|' read -r AI_SSH AI_SWAP AI_SWAPPINESS AI_WEB AI_BBR AI_RETRY AI_BAN AI_REASON <<< "$AI_PARSED"
            SSH_PORT="$AI_SSH"
            SWAP_SIZE_GB="$AI_SWAP"
            SWAPPINESS="$AI_SWAPPINESS"
            [ "$AI_WEB" = "True" ] && OPEN_WEB="y" || OPEN_WEB="n"
            [ "$AI_BBR" = "True" ] && ENABLE_BBR="y" || ENABLE_BBR="n"
            F2B_MAXRETRY="$AI_RETRY"
            F2B_BANTIME="$AI_BAN"
            
            echo -e "${C_GREEN}[✓] Gemini Flash Analysis Successful!${NC}"
            echo -e "${C_CYAN}AI Reasoning: ${NC}${AI_REASON}\n"
        else
            echo -e "${C_YELLOW}[!] Could not parse Gemini response (Invalid API Key or Rate Limit). Using optimal defaults.${NC}"
        fi
    fi
else
    echo -e "${C_GREEN}>>> Automatic Mode selected. Applying default hardening profile.${NC}"
fi

# ==============================================================================
# CONFIGURATION SUMMARY BOX
# ==============================================================================
echo -e "${C_CYAN}${C_BOLD}┌────────────────── CONFIGURATION SUMMARY ──────────────────┐${NC}"
printf "│ %-30s : %-25s │\n" "Account" "root (Password Auth)"
printf "│ %-30s : %-25s │\n" "SSH Port" "$SSH_PORT"
printf "│ %-30s : %-25s │\n" "Idle Session Timeout" "${SSH_TIMEOUT}s"
printf "│ %-30s : %-25s │\n" "Web Ports (80/443)" "$OPEN_WEB"
printf "│ %-30s : %-25s │\n" "Extra Port" "$([ -n "$EXTRA_PORT" ] && echo "$EXTRA_PORT" || echo "None")"
printf "│ %-30s : %-25s │\n" "Fail2Ban Policy" "$F2B_MAXRETRY tries / ${F2B_BANTIME}s ban"
printf "│ %-30s : %-25s │\n" "Swap Allocation" "${SWAP_SIZE_GB} GB (Swappiness: $SWAPPINESS)"
printf "│ %-30s : %-25s │\n" "Secure /dev/shm" "$HARDEN_DEV_SHM"
printf "│ %-30s : %-25s │\n" "Google TCP BBR" "$ENABLE_BBR"
printf "│ %-30s : %-25s │\n" "Kernel SYN-Flood Shield" "$HARDEN_SYSCTL"
printf "│ %-30s : %-25s │\n" "Auto Security Updates" "$ENABLE_AUTO_UPDATES"
echo -e "${C_CYAN}${C_BOLD}└───────────────────────────────────────────────────────────┘${NC}"

prompt CONFIRM "Apply configuration now? (y/n)" "y"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${C_RED}[!] Installation aborted by user.${NC}"
    exit 0
fi

# ==============================================================================
# EXECUTION
# ==============================================================================

echo ""
echo -e "${C_BLUE}>>> [1/8] Updating package lists and upgrading software...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo -e "${C_BLUE}>>> [2/8] Installing core security utilities (UFW, Fail2Ban, Chrony)...${NC}"
apt install -y ufw fail2ban curl wget htop iotop net-tools unattended-upgrades chrony
systemctl enable chrony --now >/dev/null 2>&1

echo -e "${C_BLUE}>>> [3/8] Configuring Virtual Memory & Swap...${NC}"
if [ "$SWAP_SIZE_GB" -gt 0 ]; then
    CURRENT_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
    if [ "$CURRENT_SWAP" -gt 0 ]; then
        echo -e "${C_YELLOW}  -> Swap already present (${CURRENT_SWAP}MB). Skipping.${NC}"
    else
        echo -e "${C_GREEN}  -> Allocating ${SWAP_SIZE_GB}GB swap file...${NC}"
        fallocate -l "${SWAP_SIZE_GB}G" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_SIZE_GB * 1024))
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
    fi
fi

echo -e "${C_BLUE}>>> [4/8] Applying Kernel Hardening & TCP Acceleration (sysctl)...${NC}"
cat << EOF > /etc/sysctl.d/99-server-hardening.conf
# ==============================================================================
# Google BBR TCP Congestion Control
# ==============================================================================
$([[ "$ENABLE_BBR" =~ ^[Yy]$ ]] && echo "net.core.default_qdisc = fq" || true)
$([[ "$ENABLE_BBR" =~ ^[Yy]$ ]] && echo "net.ipv4.tcp_congestion_control = bbr" || true)

# ==============================================================================
# SYN-Flood & Denial of Service Protection
# ==============================================================================
$([[ "$HARDEN_SYSCTL" =~ ^[Yy]$ ]] && cat << 'SYS_BLOCK'
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
SYS_BLOCK
)

# ==============================================================================
# High Bandwidth Buffer & Connection Queue Tuning
# ==============================================================================
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# ==============================================================================
# Memory Management
# ==============================================================================
vm.swappiness = $SWAPPINESS
vm.vfs_cache_pressure = 50
EOF

sysctl --system >/dev/null 2>&1
echo -e "${C_GREEN}  -> Sysctl configuration reloaded.${NC}"

echo -e "${C_BLUE}>>> [5/8] Securing Shared Memory (/dev/shm)...${NC}"
if [[ "$HARDEN_DEV_SHM" =~ ^[Yy]$ ]]; then
    if ! grep -q "/dev/shm" /etc/fstab; then
        echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
        mount -o remount /dev/shm >/dev/null 2>&1 || true
    fi
    echo -e "${C_GREEN}  -> /dev/shm protected with noexec,nosuid,nodev.${NC}"
fi

echo -e "${C_BLUE}>>> [6/8] Increasing File Descriptor Limits...${NC}"
cat << 'EOF' > /etc/security/limits.d/99-nofile.conf
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
grep -q "DefaultLimitNOFILE=65535" /etc/systemd/system.conf || echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf

echo -e "${C_BLUE}>>> [7/8] Hardening OpenSSH & Configuring Fail2Ban...${NC}"
mkdir -p /etc/ssh/sshd_config.d/
SSH_HARDEN_CONF="/etc/ssh/sshd_config.d/99-hardened.conf"

cat << EOF > "$SSH_HARDEN_CONF"
Port $SSH_PORT
PermitRootLogin yes
PasswordAuthentication yes
LoginGraceTime 30
MaxAuthTries 3
PermitEmptyPasswords no
X11Forwarding no
ClientAliveInterval $SSH_TIMEOUT
ClientAliveCountMax 2
EOF

if sshd -t; then
    systemctl restart sshd || systemctl restart ssh
    echo -e "${C_GREEN}  -> SSH active on port $SSH_PORT (root password enabled).${NC}"
else
    echo -e "${C_RED}  -> SSH config error. Reverting.${NC}"
    rm -f "$SSH_HARDEN_CONF"
fi

cat << EOF > /etc/fail2ban/jail.d/custom-ssh.local
[DEFAULT]
bantime = $F2B_BANTIME
findtime = $F2B_FINDTIME
maxretry = $F2B_MAXRETRY

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = $F2B_MAXRETRY
EOF

systemctl restart fail2ban
systemctl enable fail2ban >/dev/null 2>&1
echo -e "${C_GREEN}  -> Fail2Ban active (${F2B_MAXRETRY} tries = ${F2B_BANTIME}s ban).${NC}"

echo -e "${C_BLUE}>>> [8/8] Configuring UFW Firewall & Automatic Updates...${NC}"
ufw --force reset >/dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT/tcp" comment "SSH Port"

if [[ "$OPEN_WEB" =~ ^[Yy]$ ]]; then
    ufw allow 80/tcp comment "HTTP"
    ufw allow 443/tcp comment "HTTPS"
fi

if [ -n "$EXTRA_PORT" ]; then
    ufw allow "$EXTRA_PORT" comment "Custom Port"
fi

ufw --force enable >/dev/null 2>&1
echo -e "${C_GREEN}  -> UFW firewall enabled.${NC}"

if [[ "$ENABLE_AUTO_UPDATES" =~ ^[Yy]$ ]]; then
    echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    echo -e "${C_GREEN}  -> Background security updates active.${NC}"
fi

# ==============================================================================
# CHANGE ROOT PASSWORD PROMPT
# ==============================================================================
echo ""
echo -e "${C_MAGENTA}${C_BOLD}┌──[ ROOT PASSWORD UPDATE ]${NC}"
prompt CHANGE_ROOT_PASSWORD "Would you like to set a new root password now? (y/n)" "y"

if [[ "$CHANGE_ROOT_PASSWORD" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Please type your new root password below:${NC}"
    passwd root
    echo -e "${C_GREEN}Root password updated successfully.${NC}"
else
    echo -e "${C_BLUE}Skipped root password update.${NC}"
fi

# ==============================================================================
# FINISH BANNER
# ==============================================================================
show_finish_banner
echo -e "${C_CYAN}  Target User:     ${C_GREEN}root${NC}"
echo -e "  Auth Method:     ${C_GREEN}Password Authentication${NC}"
echo -e "  SSH Port:        ${C_GREEN}${SSH_PORT}${NC}"
echo -e "  TCP BBR:         ${C_GREEN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'active')${NC}"
echo -e "  Firewall:        ${C_GREEN}$(ufw status | grep Status)${NC}"
echo ""
echo -e "${C_RED}${C_BOLD}⚠️  CRITICAL: DO NOT CLOSE THIS SESSION YET!${NC}"
echo -e "Open a NEW terminal tab/window and verify login before disconnecting:"
if [ "$SSH_PORT" -eq 22 ]; then
    echo -e "   ${C_YELLOW}ssh root@$(curl -s ifconfig.me)${NC}"
else
    echo -e "   ${C_YELLOW}ssh root@$(curl -s ifconfig.me) -p ${SSH_PORT}${NC}"
fi
echo ""
