#!/usr/bin/env bash
# =========================================================================
# system-info.sh - Collecte d'informations système pour debug WordOps
# =========================================================================
# Purpose: Capture l'état complet du système avant/après installation
# Usage: system-info.sh [output-file]
# =========================================================================

set -euo pipefail

OUTPUT_FILE="${1:-/logs/system-info.log}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_section() {
    echo ""
    echo "========================================================================="
    echo "  $1"
    echo "========================================================================="
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Fonction pour exécuter une commande et capturer la sortie
run_cmd() {
    local description="$1"
    local command="$2"
    
    echo "# $description"
    echo "# Command: $command"
    echo "---"
    eval "$command" 2>&1 || echo "Command failed with exit code: $?"
    echo ""
}

# Début de la collecte
{
    log_section "INFORMATIONS SYSTÈME - $TIMESTAMP"
    
    log_section "1. DISTRIBUTION ET KERNEL"
    run_cmd "OS Release" "cat /etc/os-release"
    run_cmd "LSB Release" "lsb_release -a"
    run_cmd "Kernel Version" "uname -a"
    run_cmd "Kernel Release" "uname -r"
    run_cmd "Architecture" "uname -m"
    run_cmd "Hostname" "hostname -f"
    
    log_section "2. RESSOURCES SYSTÈME"
    run_cmd "Memory Info" "free -h"
    run_cmd "Disk Space" "df -h"
    run_cmd "CPU Info" "lscpu"
    run_cmd "Uptime" "uptime"
    
    log_section "3. RÉSEAU"
    run_cmd "IP Addresses" "ip addr show"
    run_cmd "Routing Table" "ip route"
    run_cmd "DNS Configuration" "cat /etc/resolv.conf"
    run_cmd "DNS Test (google.com)" "nslookup google.com || dig google.com || true"
    run_cmd "Connectivity Test (google.com)" "ping -c 3 google.com || true"
    run_cmd "HTTPS Connectivity Test" "curl -sI https://google.com || true"
    
    log_section "4. APT CONFIGURATION"
    run_cmd "APT Sources List" "cat /etc/apt/sources.list"
    run_cmd "APT Sources List.d" "ls -la /etc/apt/sources.list.d/ && cat /etc/apt/sources.list.d/* 2>/dev/null || true"
    run_cmd "APT Preferences" "cat /etc/apt/preferences.d/* 2>/dev/null || true"
    run_cmd "APT Configuration" "apt-config dump"
    
    log_section "5. CLÉ GPG ET KEYRINGS"
    run_cmd "APT Keys (deprecated)" "apt-key list 2>/dev/null || true"
    run_cmd "Keyrings Directory" "ls -la /etc/apt/keyrings/ /usr/share/keyrings/ 2>/dev/null || true"
    run_cmd "Trusted GPG Keys" "ls -la /etc/apt/trusted.gpg.d/ 2>/dev/null || true"
    
    log_section "6. PACKAGES INSTALLÉS"
    run_cmd "All Installed Packages" "dpkg -l"
    run_cmd "Python Packages" "dpkg -l | grep python"
    run_cmd "Nginx Packages" "dpkg -l | grep nginx || echo 'No nginx packages'"
    run_cmd "PHP Packages" "dpkg -l | grep php || echo 'No PHP packages'"
    run_cmd "MariaDB/MySQL Packages" "dpkg -l | grep -E 'mariadb|mysql' || echo 'No database packages'"
    run_cmd "Git Packages" "dpkg -l | grep git || echo 'No git packages'"
    
    log_section "7. APT CACHE POLICY"
    run_cmd "APT Update Status" "apt-get update -qq 2>&1 | head -50"
    run_cmd "APT Cache Stats" "apt-cache stats"
    run_cmd "Python3 Policy" "apt-cache policy python3"
    run_cmd "Python3-pip Policy" "apt-cache policy python3-pip"
    run_cmd "Curl Policy" "apt-cache policy curl"
    
    log_section "8. SERVICES SYSTEMD"
    run_cmd "Systemd Status" "systemctl status 2>/dev/null || echo 'Systemd not available'"
    run_cmd "Failed Services" "systemctl --failed 2>/dev/null || true"
    run_cmd "Running Services" "systemctl list-units --type=service --state=running 2>/dev/null || true"
    
    log_section "9. WORDOPS SPÉCIFIQUE"
    run_cmd "WordOps Binary" "which wo || echo 'WordOps not installed'"
    run_cmd "WordOps Version" "wo --version 2>/dev/null || echo 'WordOps not installed'"
    run_cmd "WordOps Config" "cat /etc/wo/wo.conf 2>/dev/null || echo 'WordOps config not found'"
    run_cmd "WordOps Logs Directory" "ls -la /var/log/wo/ 2>/dev/null || echo 'WordOps logs directory not found'"
    run_cmd "WordOps Installation Log" "cat /var/log/wo/install.log 2>/dev/null || echo 'No installation log'"
    
    log_section "10. VARIABLES D'ENVIRONNEMENT"
    run_cmd "All Environment Variables" "env | sort"
    run_cmd "PATH" "echo \$PATH"
    run_cmd "DEBIAN_FRONTEND" "echo \$DEBIAN_FRONTEND"
    run_cmd "LANG and LOCALE" "locale"
    
    log_section "11. REPOSITORIES TESTING"
    run_cmd "Test Sury PHP Repo" "curl -sI https://packages.sury.org/php/ || true"
    run_cmd "Test MariaDB Repo" "curl -sI https://mariadb.org/mariadb_release_signing_key.pgp || true"
    run_cmd "Test Redis Repo" "curl -sI https://packages.redis.io/gpg || true"
    run_cmd "Test WordOps Repo (OpenSUSE)" "curl -sI https://download.opensuse.org/repositories/home:/virtubox:/WordOps/ || true"
    
    log_section "12. PROCESSUS EN COURS"
    run_cmd "Top Processes" "ps aux --sort=-%mem | head -20"
    
    log_section "13. LOGS SYSTÈME RÉCENTS"
    run_cmd "Dmesg (last 50 lines)" "dmesg | tail -50 2>/dev/null || true"
    run_cmd "Syslog (last 50 lines)" "tail -50 /var/log/syslog 2>/dev/null || tail -50 /var/log/messages 2>/dev/null || echo 'No system log found'"
    
    log_section "COLLECTE TERMINÉE - $TIMESTAMP"
    
} | tee "$OUTPUT_FILE"

log_success "System information saved to: $OUTPUT_FILE"
exit 0
