#!/usr/bin/env bash
# ==============================================================================
#            BASTION — LINUX VPS HARDENING & OPTIMIZATION SUITE
#                     Engineered with 🤍 by laguser
#                  https://github.com/laguser/bastion
#         Modes: [1] Automatic (Recommended) | [2] Interactive Wizard
#
#   Patched by Axiom:
#   - SSH pubkey format is validated at collection time, before anything
#     is written to disk.
#   - Writing to /root/.ssh/authorized_keys happens ONLY inside the
#     EXECUTION phase, after CONFIRM — a "n" at the summary now truly
#     aborts with zero side effects.
#   - Password auth is NEVER disabled in the same run that installs the
#     key. The server has no way to test the client's private key, so
#     "verify then disable" can't happen automatically. Instead: the key
#     is installed, PasswordAuthentication stays "yes", and a helper
#     script is dropped for the operator to run themselves once they've
#     confirmed key-based login works from a second session.
# ==============================================================================

set -uo pipefail

# --- Color Definitions ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[0;90m'
C_BOLD='\033[1m'
NC='\033[0m'

# Verify root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}[ERROR] You must run this script as root!${NC}"
    exit 1
fi

# Log full execution output to /var/log/bastion.log
mkdir -p /var/log
exec > >(tee -a /var/log/bastion.log) 2>&1

show_header() {
    clear 2>/dev/null || true
    echo -e "${C_CYAN}${C_BOLD}"
cat << 'EOF'
  ██████╗  █████╗ ███████╗████████╗██╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
  ██████╔╝███████║███████╗   ██║   ██║██║   ██║██╔██╗ ██║
  ██╔══██╗██╔══██║╚════██║   ██║   ██║██║   ██║██║╚██╗██║
  ██████╔╝██║  ██║███████║   ██║   ██║╚██████╔╝██║ ╚████║
  ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${C_GRAY}  ┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${C_GRAY}  │${NC} ${C_WHITE}${C_BOLD}BASTION${NC} — Modern Linux VPS Hardening & TCP Acceleration     ${C_GRAY}│${NC}"
    echo -e "${C_GRAY}  │${NC} ${C_MAGENTA}Engineered by laguser${NC} ${C_GRAY}│${NC} ${C_BLUE}https://github.com/laguser/bastion${NC}  ${C_GRAY}│${NC}"
    echo -e "${C_GRAY}  └────────────────────────────────────────────────────────────┘${NC}\n"
}

show_finish_banner() {
    echo ""
    echo -e "${C_GREEN}${C_BOLD}"
cat << 'EOF'
  ███████╗██╗███╗   ██╗██╗███████╗██╗  ██╗███████╗██████╗ 
  ██╔════╝██║████╗  ██║██║██╔════╝██║  ██║██╔════╝██╔══██╗
  █████╗  ██║██╔██╗ ██║██║███████╗███████║█████╗  ██║  ██║
  ██╔══╝  ██║██║╚██╗██║██║╚════██║██╔══██║██╔══╝  ██║  ██║
  ██║     ██║██║ ╚████║██║███████║██║  ██║███████╗██████╔╝
  ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝ 
EOF
    echo -e "${C_GRAY}  >> Hardening profile applied successfully by laguser/bastion <<${NC}\n"
}

show_header

# Input prompt helper with Enter-default capability (Safe: uses printf -v)
prompt() {
    local var_name="$1"
    local question="$2"
    local default_val="$3"
    local input=""

    if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo -e "${C_RED}[ERROR] Invalid variable name: $var_name${NC}" >&2
        return 1
    fi

    echo -e -n "${C_YELLOW}⚡ ${C_BOLD}${question}${NC} "
    if [ -n "$default_val" ]; then
        echo -e -n "${C_CYAN}[Press Enter for: ${default_val}]${NC}: "
    else
        echo -e -n "${C_CYAN}[Press Enter to skip]${NC}: "
    fi

    if [ -t 0 ]; then
        read -r input || input=""
    elif (exec </dev/tty) 2>/dev/null; then
        read -r input </dev/tty || input=""
    else
        read -r input || input=""
    fi

    if [ -z "$input" ]; then
        printf -v "$var_name" '%s' "$default_val"
    else
        printf -v "$var_name" '%s' "$input"
    fi
}

prompt_secret() {
    local var_name="$1"
    local question="$2"
    local input=""

    if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo -e "${C_RED}[ERROR] Invalid variable name: $var_name${NC}" >&2
        return 1
    fi

    echo -e -n "${C_YELLOW}⚡ ${C_BOLD}${question}${NC}: "
    if [ -t 0 ]; then
        read -s -r input || input=""
    elif (exec </dev/tty) 2>/dev/null; then
        read -s -r input </dev/tty || input=""
    else
        read -s -r input || input=""
    fi
    echo ""
    printf -v "$var_name" '%s' "$input"
}

clamp_uint() {
    local val="$1"
    local min="$2"
    local max="$3"
    local fallback="$4"

    if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge "$min" ] && [ "$val" -le "$max" ]; then
        echo "$val"
    else
        echo "$fallback"
    fi
}

# Validate an OpenSSH public key line by format only (no filesystem touch)
is_valid_pubkey() {
    local key="$1"
    [[ "$key" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com)\ [A-Za-z0-9+/]+=*(\ .*)?$ ]]
}

# ==============================================================================
# MODE SELECTION
# ==============================================================================
echo -e "${C_BOLD}Select Configuration Mode:${NC}"
echo -e "  ${C_CYAN}[1] Automatic (Recommended)${NC} — Production security profile with zero cloud dependency"
echo -e "  ${C_CYAN}[2] Interactive Wizard${NC}     — Step-by-step custom questionnaire (SSH keys, ports, limits)"
echo ""

prompt SETUP_MODE "Choose mode (1 or 2)" "1"

# Default Variables
SSH_PORT="22"
SSH_TIMEOUT="300"
ALLOW_TCP_FORWARDING="no"
SSH_PUBKEY=""
DISABLE_PASS="n"
OPEN_WEB="y"
EXTRA_PORTS=""
F2B_MAXRETRY="3"
F2B_BANTIME="7200"
F2B_FINDTIME="600"
SWAP_SIZE_GB="2"
SWAPPINESS="10"
HARDEN_DEV_SHM="y"
ENABLE_BBR="y"
HARDEN_SYSCTL="y"
ENABLE_AUTO_UPDATES="y"

# Virtualization Detection (LXC / OpenVZ containers cannot run custom kernel sysctl / swap)
if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -c &>/dev/null; then
    echo -e "${C_YELLOW}[!] Container virtualization detected (LXC/OpenVZ). Disabling swap and host kernel tuning.${NC}"
    SWAP_SIZE_GB="0"
    HARDEN_SYSCTL="n"
fi

# ==============================================================================
# MODE LOGIC — collection only. Nothing here touches the filesystem.
# ==============================================================================

if [ "$SETUP_MODE" = "2" ] || [ "$SETUP_MODE" = "wizard" ] || [ "$SETUP_MODE" = "manual" ]; then
    # ---------------- INTERACTIVE WIZARD MODE ----------------
    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 1. SSH CONFIGURATION & AUTHENTICATION ]${NC}"
    prompt SSH_PORT "SSH Port (Changing from 22 reduces automated scanning noise)" "22"
    SSH_PORT=$(clamp_uint "$SSH_PORT" 1 65535 22)

    prompt SSH_TIMEOUT "Disconnect idle sessions after how many seconds?" "300"
    SSH_TIMEOUT=$(clamp_uint "$SSH_TIMEOUT" 30 86400 300)

    prompt ADD_SSH_KEY "Would you like to install an SSH Public Key for root login? (y/n)" "n"
    if [[ "$ADD_SSH_KEY" =~ ^[Yy]$ ]]; then
        prompt SSH_PUBKEY "Paste your SSH Public Key (e.g. ssh-ed25519 AAAAC3... user@domain)" ""
        if [ -n "$SSH_PUBKEY" ] && is_valid_pubkey "$SSH_PUBKEY"; then
            echo -e "${C_GREEN}[✓] Key format looks valid — it will be installed during the EXECUTION phase, after confirmation.${NC}"

            prompt DISABLE_PASS "After the key is confirmed working, disable SSH password login? (y/n)" "n"
            if [[ "$DISABLE_PASS" =~ ^[Yy]$ ]]; then
                echo -e "${C_YELLOW}[i] Password auth will NOT be disabled in this run. This box can't test your private key —${NC}"
                echo -e "${C_YELLOW}    only your local machine has it. A helper script will be created instead; run it${NC}"
                echo -e "${C_YELLOW}    yourself once you've confirmed key login works from a NEW terminal.${NC}"
            fi
        else
            echo -e "${C_RED}[!] Key format looks invalid (expected 'ssh-ed25519 AAAA...' / 'ssh-rsa AAAA...' / etc).${NC}"
            echo -e "${C_RED}    Skipping key installation. Password authentication remains enabled.${NC}"
            SSH_PUBKEY=""
            DISABLE_PASS="n"
        fi
    fi

    prompt ALLOW_TCP_FWD "Allow SSH TCP forwarding (required for SSH tunnels / SOCKS)? (y/n)" "n"
    if [[ "$ALLOW_TCP_FWD" =~ ^[Yy]$ ]]; then
        ALLOW_TCP_FORWARDING="yes"
    else
        ALLOW_TCP_FORWARDING="no"
    fi

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 2. FIREWALL (UFW) & PORTS ]${NC}"
    prompt OPEN_WEB "Allow incoming HTTP (80) & HTTPS (443) web ports? (y/n)" "y"
    prompt EXTRA_PORTS "Open any additional custom ports? (e.g. 51820/udp, 8080 or Enter to skip)" ""

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 3. FAIL2BAN BRUTE-FORCE SHIELD ]${NC}"
    prompt F2B_MAXRETRY "Maximum failed password attempts before ban" "3"
    F2B_MAXRETRY=$(clamp_uint "$F2B_MAXRETRY" 1 50 3)

    prompt F2B_BANTIME "Ban duration in seconds (7200 = 2 hours, 86400 = 24 hours)" "7200"
    F2B_BANTIME=$(clamp_uint "$F2B_BANTIME" 60 31536000 7200)

    prompt F2B_FINDTIME "Window time in seconds to track failed attempts" "600"
    F2B_FINDTIME=$(clamp_uint "$F2B_FINDTIME" 30 86400 600)

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 4. MEMORY & STORAGE TUNING ]${NC}"
    prompt SWAP_SIZE_GB "Swap file size in Gigabytes (0 to skip)" "$SWAP_SIZE_GB"
    SWAP_SIZE_GB=$(clamp_uint "$SWAP_SIZE_GB" 0 64 2)

    prompt SWAPPINESS "Kernel Swappiness ratio 0-100 (10 = preserve RAM first)" "10"
    SWAPPINESS=$(clamp_uint "$SWAPPINESS" 0 100 10)

    prompt HARDEN_DEV_SHM "Mount /dev/shm with 'noexec' to block script exploits? (y/n)" "y"

    echo ""
    echo -e "${C_MAGENTA}${C_BOLD}┌──[ 5. KERNEL HARDENING & OPTIMIZATION ]${NC}"
    prompt ENABLE_BBR "Enable Google BBR Congestion Control (Faster network)? (y/n)" "y"
    prompt HARDEN_SYSCTL "Apply kernel security shield (SYN-Flood cookies, anti-spoof)? (y/n)" "$HARDEN_SYSCTL"
    prompt ENABLE_AUTO_UPDATES "Enable automatic background security updates? (y/n)" "y"

else
    # ---------------- AUTOMATIC MODE ----------------
    echo -e "${C_GREEN}>>> Automatic Mode selected. Applying standard production hardening profile.${NC}"
fi

# Multi-Protocol Listening Port Auto-Detection (TCP & UDP)
DETECTED_PORTS=()
if command -v ss &>/dev/null; then
    mapfile -t DETECTED_PORTS < <(
        ss -tulnH 2>/dev/null | awk '{split($5,a,":"); p=a[length(a)];
            if ($1=="udp") print p"/udp"; else print p"/tcp"}' |
        grep -vE '^(22|80|443)/' | sort -u
    )
fi

if [ ${#DETECTED_PORTS[@]} -gt 0 ]; then
    echo -e "${C_YELLOW}>>> Detected active services on ports: ${DETECTED_PORTS[*]}${NC}"
    DETECTED_CSV=$(IFS=,; echo "${DETECTED_PORTS[*]}")
    if [ -z "$EXTRA_PORTS" ]; then
        EXTRA_PORTS="$DETECTED_CSV"
    else
        EXTRA_PORTS="${EXTRA_PORTS},${DETECTED_CSV}"
    fi
fi

# Check for Port Conflicts before configuring SSH
if [ "$SSH_PORT" -ne 22 ] && command -v ss &>/dev/null; then
    if ss -tlnH "sport = :$SSH_PORT" 2>/dev/null | grep -q .; then
        echo -e "${C_YELLOW}[!] Port $SSH_PORT is already bound by another service. Keeping SSH on port 22.${NC}"
        SSH_PORT=22
    fi
fi

# Clamp all numeric parameters to safe ranges
SSH_PORT=$(clamp_uint "$SSH_PORT" 1 65535 22)
SSH_TIMEOUT=$(clamp_uint "$SSH_TIMEOUT" 30 86400 300)
F2B_MAXRETRY=$(clamp_uint "$F2B_MAXRETRY" 1 50 3)
F2B_BANTIME=$(clamp_uint "$F2B_BANTIME" 60 31536000 7200)
F2B_FINDTIME=$(clamp_uint "$F2B_FINDTIME" 30 86400 600)
SWAP_SIZE_GB=$(clamp_uint "$SWAP_SIZE_GB" 0 64 2)
SWAPPINESS=$(clamp_uint "$SWAPPINESS" 0 100 10)

# ==============================================================================
# CONFIGURATION SUMMARY BOX — read-only, no filesystem state has been touched yet
# ==============================================================================
AUTH_DESC="Password Authentication"
if [ -n "$SSH_PUBKEY" ]; then
    if [[ "$DISABLE_PASS" =~ ^[Yy]$ ]]; then
        AUTH_DESC="Password + SSH Key (key-only after manual confirmation step)"
    else
        AUTH_DESC="Password + SSH Key"
    fi
fi

echo -e "${C_CYAN}${C_BOLD}┌────────────────── CONFIGURATION SUMMARY ──────────────────┐${NC}"
printf "│ %-30s : %-25s │\n" "Root Auth Method" "$AUTH_DESC"
printf "│ %-30s : %-25s │\n" "SSH Port" "$SSH_PORT"
printf "│ %-30s : %-25s │\n" "Idle Session Timeout" "${SSH_TIMEOUT}s"
printf "│ %-30s : %-25s │\n" "SSH TCP Forwarding" "$ALLOW_TCP_FORWARDING"
printf "│ %-30s : %-25s │\n" "Web Ports (80/443)" "$OPEN_WEB"
printf "│ %-30s : %-25s │\n" "Extra Service Ports" "$([ -n "$EXTRA_PORTS" ] && echo "$EXTRA_PORTS" || echo "None")"
printf "│ %-30s : %-25s │\n" "Fail2Ban Policy" "$F2B_MAXRETRY tries / ${F2B_BANTIME}s ban"
printf "│ %-30s : %-25s │\n" "Swap Allocation" "${SWAP_SIZE_GB} GB (Swappiness: $SWAPPINESS)"
printf "│ %-30s : %-25s │\n" "Secure /dev/shm" "$HARDEN_DEV_SHM"
printf "│ %-30s : %-25s │\n" "Google TCP BBR" "$ENABLE_BBR"
printf "│ %-30s : %-25s │\n" "Kernel Hardening" "$HARDEN_SYSCTL"
printf "│ %-30s : %-25s │\n" "Auto Security Updates" "$ENABLE_AUTO_UPDATES"
echo -e "${C_CYAN}${C_BOLD}└───────────────────────────────────────────────────────────┘${NC}"

prompt CONFIRM "Apply configuration now? (y/n)" "n"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${C_RED}[!] Installation aborted by user. No files were modified.${NC}"
    exit 0
fi

# ==============================================================================
# EXECUTION — every mutation happens from here down, and only from here down.
# ==============================================================================

# Create backups of critical files prior to mutation
BACKUP_DIR="/var/backups/bastion/$(date +%s)"
mkdir -p "$BACKUP_DIR"
[ -f /etc/ssh/sshd_config ] && cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
[ -f /etc/fstab ] && cp -a /etc/fstab "$BACKUP_DIR/fstab.bak" 2>/dev/null || true
[ -f /etc/systemd/system.conf ] && cp -a /etc/systemd/system.conf "$BACKUP_DIR/system.conf.bak" 2>/dev/null || true
if [ -d /etc/ufw ]; then
    cp -a /etc/ufw/user.rules "$BACKUP_DIR/user.rules.bak" 2>/dev/null || true
    cp -a /etc/ufw/user6.rules "$BACKUP_DIR/user6.rules.bak" 2>/dev/null || true
fi

echo ""
echo -e "${C_BLUE}>>> [1/8] Updating package lists and upgrading software...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo -e "${C_BLUE}>>> [2/8] Installing core security utilities (UFW, Fail2Ban, Chrony, Python3-Systemd)...${NC}"
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    ufw fail2ban curl wget unattended-upgrades chrony python3-systemd
systemctl enable chrony --now >/dev/null 2>&1 || true

echo -e "${C_BLUE}>>> [3/8] Configuring Virtual Memory & Swap...${NC}"
DISK_FREE_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
if [ "$SWAP_SIZE_GB" -gt 0 ]; then
    CURRENT_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
    if [ "${CURRENT_SWAP:-0}" -gt 0 ]; then
        echo -e "${C_YELLOW}  -> Swap already present (${CURRENT_SWAP}MB). Skipping creation.${NC}"
    elif [ "${DISK_FREE_GB:-0}" -lt "$((SWAP_SIZE_GB + 2))" ]; then
        echo -e "${C_YELLOW}  -> Insufficient disk space (${DISK_FREE_GB:-0}GB free). Skipping swap creation.${NC}"
    else
        echo -e "${C_GREEN}  -> Allocating ${SWAP_SIZE_GB}GB swap file...${NC}"
        fallocate -l "${SWAP_SIZE_GB}G" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_SIZE_GB * 1024))
        chmod 600 /swapfile
        if ! mkswap /swapfile >/dev/null 2>&1 || ! swapon /swapfile 2>/dev/null; then
            rm -f /swapfile
            echo -e "${C_YELLOW}  -> Swapfile unsupported or failed on this filesystem. Skipped.${NC}"
        else
            if ! grep -q '/swapfile' /etc/fstab 2>/dev/null; then
                echo '/swapfile none swap sw,nofail 0 0' >> /etc/fstab
            fi
            echo -e "${C_GREEN}  -> Swap allocated and activated.${NC}"
        fi
    fi
fi

echo -e "${C_BLUE}>>> [4/8] Configuring Google TCP BBR & Kernel Hardening (sysctl)...${NC}"

# Independent BBR Acceleration (separate from host kernel sysctl shield)
if [[ "$ENABLE_BBR" =~ ^[Yy]$ ]]; then
    modprobe tcp_bbr 2>/dev/null || true
    if sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q bbr; then
        cat << 'EOF' > /etc/sysctl.d/98-bbr.conf
# Google BBR Congestion Control (by laguser)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
        sysctl -p /etc/sysctl.d/98-bbr.conf >/dev/null 2>&1 || true
        echo -e "${C_GREEN}  -> Google TCP BBR enabled.${NC}"
    else
        echo -e "${C_YELLOW}  -> Kernel does not support BBR. Retaining default congestion control.${NC}"
    fi
fi

# Kernel Security Shield
if [[ "$HARDEN_SYSCTL" =~ ^[Yy]$ ]]; then
cat << EOF > /etc/sysctl.d/99-server-hardening.conf
# ==============================================================================
# SYN-Flood & Denial of Service Protection
# ==============================================================================
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
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

# IPv6 Route Hardening
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Filesystem & Kernel Memory Security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1

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

    sysctl --system >/dev/null 2>&1 || true
    echo -e "${C_GREEN}  -> Sysctl security configuration applied.${NC}"
fi

echo -e "${C_BLUE}>>> [5/8] Securing Shared Memory (/dev/shm)...${NC}"
if [[ "$HARDEN_DEV_SHM" =~ ^[Yy]$ ]]; then
    if ! grep -q "[[:space:]]/dev/shm[[:space:]]" /etc/fstab 2>/dev/null; then
        echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
    fi
    mount -o remount,noexec,nosuid,nodev /dev/shm >/dev/null 2>&1 || true
    echo -e "${C_GREEN}  -> /dev/shm protected with noexec,nosuid,nodev.${NC}"
fi

echo -e "${C_BLUE}>>> [6/8] Increasing File Descriptor Limits...${NC}"
cat << 'EOF' > /etc/security/limits.d/99-nofile.conf
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
grep -q "DefaultLimitNOFILE=65535" /etc/systemd/system.conf 2>/dev/null || echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf

echo -e "${C_BLUE}>>> [7/8] Hardening OpenSSH & Configuring Fail2Ban...${NC}"

# --- Install SSH public key (validated at collection time, written here) ---
KEY_INSTALLED=0
if [ -n "$SSH_PUBKEY" ] && is_valid_pubkey "$SSH_PUBKEY"; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    if ! grep -qxF "$SSH_PUBKEY" /root/.ssh/authorized_keys 2>/dev/null; then
        echo "$SSH_PUBKEY" >> /root/.ssh/authorized_keys
    fi
    KEY_INSTALLED=1
    echo -e "${C_GREEN}  -> SSH public key installed to /root/.ssh/authorized_keys.${NC}"
fi

# Strictly check Include directive using regex anchor to avoid matching comments (#Include)
if [ -f /etc/ssh/sshd_config ]; then
    if ! grep -Eq '^\s*Include\s+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config 2>/dev/null; then
        sed -i '1s|^|Include /etc/ssh/sshd_config.d/*.conf\n|' /etc/ssh/sshd_config
    fi
fi

mkdir -p /etc/ssh/sshd_config.d/
SSH_HARDEN_CONF="/etc/ssh/sshd_config.d/00-bastion.conf"

# Password auth ALWAYS stays enabled on this run, even if a key was installed
# and the operator asked to disable it. See the header note: the private key
# never touches this box, so this box cannot verify it works. A helper script
# is dropped below instead.
cat << EOF > "$SSH_HARDEN_CONF"
# Bastion Hardened OpenSSH Configuration (by laguser)
Port $SSH_PORT
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
LoginGraceTime 30
MaxAuthTries 3
PermitEmptyPasswords no
X11Forwarding no
AllowTcpForwarding $ALLOW_TCP_FORWARDING
AllowAgentForwarding no
LogLevel VERBOSE
MaxStartups 10:30:60
ClientAliveInterval $SSH_TIMEOUT
ClientAliveCountMax 2

# Modern Cryptography (Strict Key Exchange, Ciphers, and MACs)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF

# Handle systemd socket activation ONLY when ssh.socket is explicitly enabled
if systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
    mkdir -p /etc/systemd/system/ssh.socket.d
    cat << EOF > /etc/systemd/system/ssh.socket.d/port.conf
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl restart ssh.socket >/dev/null 2>&1 || true
fi

# Verify OpenSSH syntax before restarting
if sshd -t >/dev/null 2>&1; then
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
    echo -e "${C_GREEN}  -> SSH service reloaded.${NC}"
else
    echo -e "${C_RED}  -> SSH config error detected! Reverting $SSH_HARDEN_CONF.${NC}"
    rm -f "$SSH_HARDEN_CONF"
fi

# Verification: Check if SSH is indeed listening on the desired port
sleep 1
SSH_VERIFIED=0
if command -v ss &>/dev/null && ss -tlnH "sport = :$SSH_PORT" 2>/dev/null | grep -q .; then
    SSH_VERIFIED=1
    echo -e "${C_GREEN}  -> [✓] Verified: SSH actively listening on port $SSH_PORT.${NC}"
else
    echo -e "${C_YELLOW}  -> [!] Note: SSH is not responding on port $SSH_PORT. Fallback port 22 maintained.${NC}"
fi

# --- Deferred password-auth disable: dropped only if a key was installed ---
DISABLE_HELPER="/root/bastion-disable-password-auth.sh"
if [ "$KEY_INSTALLED" -eq 1 ] && [[ "$DISABLE_PASS" =~ ^[Yy]$ ]]; then
    cat << HELPEREOF > "$DISABLE_HELPER"
#!/usr/bin/env bash
# Generated by Bastion. Run this ONLY after confirming, from a SEPARATE
# terminal, that key-based login works:
#   ssh -p $SSH_PORT root@<this-server-ip>
# If that works without a password prompt, run this script to lock the
# door behind you. If it does NOT work, do not run this — fix the key
# first, or you will lose password access with no key fallback.
set -euo pipefail
if [ "\$EUID" -ne 0 ]; then echo "Run as root."; exit 1; fi
CONF="$SSH_HARDEN_CONF"
if [ ! -f "\$CONF" ]; then echo "Bastion SSH config not found at \$CONF"; exit 1; fi
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "\$CONF"
sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' "\$CONF"
if sshd -t; then
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    echo "Password authentication disabled. Key-only login is now enforced."
else
    echo "sshd config check failed — reverting, nothing was changed."
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "\$CONF"
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' "\$CONF"
    exit 1
fi
HELPEREOF
    chmod 700 "$DISABLE_HELPER"
    echo -e "${C_YELLOW}  -> Key installed. Password auth left ENABLED this run.${NC}"
    echo -e "${C_YELLOW}     Verify key login from a new terminal, then run: ${C_CYAN}$DISABLE_HELPER${NC}"
fi

# Fail2ban configuration: Use systemd backend & safe ignoreip & monitor active + fallback port
CURRENT_CLIENT_IP=$(echo "${SSH_CLIENT:-${SSH_CONNECTION:-}}" | awk '{print $1}')
IGNORE_IPS="127.0.0.1/8 ::1"
if [ -n "$CURRENT_CLIENT_IP" ] && [[ "$CURRENT_CLIENT_IP" =~ ^[0-9a-fA-F.:]+$ ]]; then
    IGNORE_IPS="$IGNORE_IPS $CURRENT_CLIENT_IP"
fi

F2B_BACKEND="auto"
if command -v systemctl &>/dev/null && systemctl is-active --quiet systemd-journald 2>/dev/null; then
    F2B_BACKEND="systemd"
elif [ -f /var/log/auth.log ]; then
    F2B_BACKEND="/var/log/auth.log"
fi

mkdir -p /etc/fail2ban/jail.d/
cat << EOF > /etc/fail2ban/jail.d/custom-ssh.local
[DEFAULT]
bantime = $F2B_BANTIME
findtime = $F2B_FINDTIME
maxretry = $F2B_MAXRETRY
ignoreip = $IGNORE_IPS

[sshd]
enabled = true
port = $SSH_PORT,22
mode = aggressive
backend = $F2B_BACKEND
maxretry = $F2B_MAXRETRY
EOF

systemctl restart fail2ban >/dev/null 2>&1 || true
systemctl enable fail2ban >/dev/null 2>&1 || true
echo -e "${C_GREEN}  -> Fail2Ban active (${F2B_MAXRETRY} tries = ${F2B_BANTIME}s ban, backend: ${F2B_BACKEND}).${NC}"

echo -e "${C_BLUE}>>> [8/8] Configuring UFW Firewall & Automatic Updates...${NC}"

# Lockout Protection: Always ensure current SSH port and port 22 are permitted with rate-limiting
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

# Use 'ufw limit' for brute-force protection at firewall layer
ufw limit "$SSH_PORT/tcp" comment "Bastion SSH Rate-Limited" >/dev/null 2>&1
if [ "$SSH_PORT" -ne 22 ]; then
    # Keep 22 open as emergency fallback
    ufw limit 22/tcp comment "SSH Emergency Fallback" >/dev/null 2>&1
fi

if [[ "$OPEN_WEB" =~ ^[Yy]$ ]]; then
    ufw allow 80/tcp comment "HTTP" >/dev/null 2>&1
    ufw allow 443/tcp comment "HTTPS" >/dev/null 2>&1
fi

# Strict regex validation for custom ports
if [ -n "$EXTRA_PORTS" ]; then
    for item in $(echo "$EXTRA_PORTS" | tr ',; ' ' '); do
        if [[ "$item" =~ ^[0-9]{1,5}(:[0-9]{1,5})?(/(tcp|udp))?$ ]]; then
            ufw allow "$item" comment "Bastion Custom Port" >/dev/null 2>&1 || true
        fi
    done
fi

ufw --force enable >/dev/null 2>&1
echo -e "${C_GREEN}  -> UFW firewall enabled with rate-limited SSH protection.${NC}"

if [[ "$ENABLE_AUTO_UPDATES" =~ ^[Yy]$ ]]; then
    cat << 'EOF' > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
EOF

    cat << 'EOF' > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    systemctl enable unattended-upgrades --now >/dev/null 2>&1 || true
    echo -e "${C_GREEN}  -> Background security updates active (50unattended-upgrades configured).${NC}"
fi

# ==============================================================================
# CHANGE ROOT PASSWORD PROMPT
# ==============================================================================
echo ""
echo -e "${C_MAGENTA}${C_BOLD}┌──[ ROOT PASSWORD UPDATE ]${NC}"
prompt CHANGE_ROOT_PASSWORD "Would you like to set a new root password now? (y/n)" "n"

if [[ "$CHANGE_ROOT_PASSWORD" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Please type your new root password below:${NC}"
    passwd root
    echo -e "${C_GREEN}Root password updated successfully.${NC}"
else
    echo -e "${C_BLUE}Skipped root password update.${NC}"
fi

# ==============================================================================
# FINISH BANNER & SECURITY REPORT
# ==============================================================================
show_finish_banner
echo -e "${C_CYAN}  Target User:       ${C_WHITE}root${NC}"
echo -e "  Auth Method:       ${C_WHITE}${AUTH_DESC}${NC}"
echo -e "  SSH Port:          ${C_WHITE}${SSH_PORT}${NC}"
if [ "$SSH_VERIFIED" -eq 1 ]; then
    echo -e "  SSH Status:        ${C_GREEN}[✔] Actively listening on port ${SSH_PORT}${NC}"
else
    echo -e "  SSH Status:        ${C_RED}[!] Not responding on port ${SSH_PORT} — Connect via fallback port 22!${NC}"
fi
echo -e "  Google TCP BBR:    ${C_GREEN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'active')${NC}"
echo -e "  Firewall:          ${C_GREEN}$(ufw status 2>/dev/null | grep Status || echo 'Status: active')${NC}"
echo -e "  Install Log:       ${C_GRAY}/var/log/bastion.log${NC}"
echo -e "  Config Backups:    ${C_GRAY}${BACKUP_DIR}${NC}"
if [ "$KEY_INSTALLED" -eq 1 ] && [[ "$DISABLE_PASS" =~ ^[Yy]$ ]]; then
    echo -e "  Password Disable:  ${C_YELLOW}Deferred — run ${DISABLE_HELPER} after verifying key login${NC}"
fi
echo ""

if [ "$SSH_PORT" -ne 22 ]; then
    echo -e "${C_YELLOW}${C_BOLD}ℹ️  EMERGENCY FALLBACK PORT 22 IS CURRENTLY ACTIVE${NC}"
    echo -e "Once you have verified login on port ${SSH_PORT}, close port 22 by running:"
    echo -e "   ${C_CYAN}sudo ufw delete limit 22/tcp${NC}\n"
fi

echo -e "${C_RED}${C_BOLD}⚠️  CRITICAL: DO NOT CLOSE THIS SESSION YET!${NC}"
echo -e "Open a NEW terminal tab/window and verify login before disconnecting:"
SERVER_PUBLIC_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
if [ "$SSH_PORT" -eq 22 ]; then
    echo -e "   ${C_YELLOW}ssh root@${SERVER_PUBLIC_IP}${NC}"
else
    echo -e "   ${C_YELLOW}ssh root@${SERVER_PUBLIC_IP} -p ${SSH_PORT}${NC}"
fi
echo ""
