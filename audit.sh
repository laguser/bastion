#!/usr/bin/env bash
# ==============================================================================
#            BASTION AUDIT & MALWARE/BACKDOOR SCANNER (STANDALONE / INTEGRATED)
# ==============================================================================
set -euo pipefail

C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'
NC='\033[0m'

TOTAL_WARNINGS=0

warn() {
    echo -e "${C_RED}[CRITICAL/BACKDOOR ALERT]${NC} $1"
    ((TOTAL_WARNINGS++)) || true
}

notice() {
    echo -e "${C_YELLOW}[WARNING]${NC} $1"
    ((TOTAL_WARNINGS++)) || true
}

ok() {
    echo -e "${C_GREEN}[PASS]${NC} $1"
}

info() {
    echo -e "${C_CYAN}[INFO]${NC} $1"
}

run_audit() {
    echo -e "\n${C_BOLD}${C_BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${C_BOLD}${C_BLUE}       BASTION DEEP SECURITY AUDIT & BACKDOOR SCANNER            ${NC}"
    echo -e "${C_BOLD}${C_BLUE}════════════════════════════════════════════════════════════════${NC}\n"

    # 1. LD_PRELOAD & Library Hijacking Check
    info "1. Checking dynamic loader persistence (LD_PRELOAD)..."
    if [ -f /etc/ld.so.preload ]; then
        if [ -s /etc/ld.so.preload ]; then
            warn "/etc/ld.so.preload is NOT empty! Potential userland rootkit active:"
            cat /etc/ld.so.preload
        else
            ok "/etc/ld.so.preload exists but is empty."
        fi
    else
        ok "/etc/ld.so.preload does not exist (standard)."
    fi

    # 2. Account Security & UID 0 Verification
    info "2. Checking accounts with UID 0 (root privileges)..."
    local uid_zero_users
    uid_zero_users=$(awk -F: '($3 == "0") {print $1}' /etc/passwd 2>/dev/null || true)
    if [ "$uid_zero_users" != "root" ]; then
        warn "Found non-standard UID 0 accounts: ${uid_zero_users}"
    else
        ok "Only 'root' has UID 0."
    fi

    # Empty passwords check in /etc/shadow
    if [ -r /etc/shadow ]; then
        local empty_pw
        empty_pw=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null || true)
        if [ -n "$empty_pw" ]; then
            warn "Accounts with completely BLANK password hashes (instant login without password!): $empty_pw"
        else
            ok "No accounts with blank passwords found in /etc/shadow."
        fi
    fi

    # 3. SSH Backdoor & Configuration Inspection
    info "3. Inspecting SSH authorized keys & configuration integrity..."
    if [ -f /etc/ssh/sshd_config ]; then
        # Check AuthorizedKeysCommand
        if grep -Eq '^[[:space:]]*AuthorizedKeysCommand[[:space:]]+[^n]' /etc/ssh/sshd_config 2>/dev/null; then
            warn "AuthorizedKeysCommand is configured in sshd_config! External key fetching backdoor possible."
        fi
        # Check AuthorizedKeysCommandRunAs
        if grep -Eq '^[[:space:]]*PermitEmptyPasswords[[:space:]]+yes' /etc/ssh/sshd_config 2>/dev/null; then
            warn "sshd_config allows empty passwords (PermitEmptyPasswords yes)!"
        fi
    fi

    # Scan /root/.ssh/authorized_keys for suspicious command= / from= restrictions or excessive keys
    if [ -f /root/.ssh/authorized_keys ]; then
        if grep -Eq 'command=|no-port-forwarding|permitopen' /root/.ssh/authorized_keys 2>/dev/null; then
            notice "Restricted directives or wrapper commands found in /root/.ssh/authorized_keys."
        fi
        local key_count
        key_count=$(grep -cE '^(ssh-|ecdsa-|sk-)' /root/.ssh/authorized_keys 2>/dev/null || true)
        info "Found ${key_count:-0} authorized SSH key(s) for root."
    fi

    # 4. Persistence mechanisms: Cron & Timers
    info "4. Scanning Cron, Anacron, and scheduled jobs..."
    local cron_paths=("/etc/crontab" "/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.monthly" "/etc/cron.weekly" "/var/spool/cron/crontabs")
    local suspicious_cron=0
    for cp in "${cron_paths[@]}"; do
        if [ -d "$cp" ]; then
            for f in "$cp"/*; do
                [ -f "$f" ] || continue
                if grep -qiE '(curl|wget|bash -i|/dev/tcp|nc -e|ncat|socat|python -c|perl -e|mkfifo)' "$f" 2>/dev/null; then
                    warn "Suspicious reverse shell / downloader command found in cron file $f:"
                    grep -iE '(curl|wget|bash -i|/dev/tcp|nc -e|ncat|socat|python -c|perl -e|mkfifo)' "$f" | head -n 3
                    suspicious_cron=1
                fi
            done
        elif [ -f "$cp" ]; then
            if grep -qiE '(curl|wget|bash -i|/dev/tcp|nc -e|ncat|socat|python -c|perl -e|mkfifo)' "$cp" 2>/dev/null; then
                warn "Suspicious reverse shell / downloader command found in $cp:"
                grep -iE '(curl|wget|bash -i|/dev/tcp|nc -e|ncat|socat|python -c|perl -e|mkfifo)' "$cp" | head -n 3
                suspicious_cron=1
            fi
        fi
    done
    [ "$suspicious_cron" -eq 0 ] && ok "Cron files do not contain obvious reverse-shell / payload download commands."

    # 5. SUID / SGID Binaries & Suspicious Capabilities
    info "5. Auditing unusual SUID binaries in standard directories..."
    local dangerous_suid=("nmap" "vim" "vi" "nano" "find" "bash" "sh" "python" "python3" "perl" "ruby" "awk" "less" "more" "cp" "mv")
    local found_bad_suid=0
    for bin in "${dangerous_suid[@]}"; do
        local p
        p=$(which "$bin" 2>/dev/null || true)
        if [ -n "$p" ] && [ -u "$p" ]; then
            warn "Dangerous SUID bit set on utility: $p (allows effortless root privilege escalation!)"
            found_bad_suid=1
        fi
    done
    [ "$found_bad_suid" -eq 0 ] && ok "No GTFOBins standard dangerous SUID binaries detected."

    # 6. Hidden files in /tmp and /dev/shm
    info "6. Checking for suspicious hidden executables in /tmp and /dev/shm..."
    local hidden_execs
    hidden_execs=$(find /tmp /dev/shm -maxdepth 3 -type f -perm /111 2>/dev/null || true)
    if [ -n "$hidden_execs" ]; then
        notice "Executable files located in temporary storage:\n$hidden_execs"
    else
        ok "/tmp and /dev/shm contain no executable binaries."
    fi

    # 7. Kernel module loading restrictions
    info "7. Checking kernel rootkit surface (module loading)..."
    local mod_disabled
    mod_disabled=$(sysctl -n kernel.modules_disabled 2>/dev/null || echo "0")
    if [ "$mod_disabled" = "1" ]; then
        ok "Kernel module loading is locked (kernel.modules_disabled = 1)."
    else
        info "Kernel module loading is enabled (default for standard Linux servers)."
    fi

    echo -e "\n${C_BOLD}Audit completed with ${TOTAL_WARNINGS} alert(s) / warning(s).${NC}\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_audit
fi
