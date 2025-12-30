#!/usr/bin/env bash
# =========================================================================
# install-wordops.sh - Script d'installation WordOps avec debug complet
# =========================================================================
# Purpose: Installer WordOps avec capture complète de logs et diagnostics
# Usage: install-wordops.sh [--dry-run] [--verbose]
# =========================================================================

# Mode strict avec tracabilité complète
set -euo pipefail

# Configuration
WO_INSTALL_LOG="${WO_INSTALL_LOG:-/logs/wo-install.log}"
WO_DEBUG_LOG="/logs/wo-debug.log"
WO_APT_DEBUG_LOG="/logs/wo-apt-debug.log"
SYSTEM_INFO_LOG="/logs/system-info-pre-install.log"
SYSTEM_INFO_POST_LOG="/logs/system-info-post-install.log"
DRY_RUN=0
VERBOSE=0

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --verbose|-v)
            VERBOSE=1
            set -x  # Active le mode debug bash
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--verbose]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Collecte les infos système sans installer"
            echo "  --verbose    Active le mode debug bash (set -x)"
            echo "  --help       Affiche cette aide"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Fonctions de logging
log_header() {
    echo ""
    echo -e "${CYAN}=========================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}=========================================================================${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fonction pour exécuter une commande avec logging
run_logged() {
    local description="$1"
    shift
    
    log_step "$description"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY-RUN: $*"
        return 0
    fi
    
    if "$@" 2>&1 | tee -a "$WO_DEBUG_LOG"; then
        log_success "$description - Completed"
        return 0
    else
        local exit_code=$?
        log_error "$description - Failed with exit code $exit_code"
        return $exit_code
    fi
}

# Déterminer le chemin de system-info.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "/usr/local/bin/system-info.sh" ]]; then
    SYSTEM_INFO_SCRIPT="/usr/local/bin/system-info.sh"
    chmod +x "$SYSTEM_INFO_SCRIPT" 2>/dev/null || true
elif [[ -f "$SCRIPT_DIR/system-info.sh" ]]; then
    SYSTEM_INFO_SCRIPT="$SCRIPT_DIR/system-info.sh"
    chmod +x "$SYSTEM_INFO_SCRIPT" 2>/dev/null || true
else
    log_warning "system-info.sh not found, system information collection will be skipped"
    SYSTEM_INFO_SCRIPT=""
fi

# Trap pour capturer les erreurs
error_handler() {
    local line_number=$1
    log_error "Script failed at line $line_number"
    log_info "Collecting post-failure system information..."
    if [[ -n "$SYSTEM_INFO_SCRIPT" ]]; then
        "$SYSTEM_INFO_SCRIPT" "/logs/system-info-post-failure.log" 2>&1 || true
    fi
    log_error "Installation FAILED. Check logs in /logs/"
    exit 1
}

trap 'error_handler $LINENO' ERR

# =========================================================================
# DÉBUT DU SCRIPT
# =========================================================================

log_header "WORDOPS INSTALLATION DEBUG SCRIPT"

log_info "Configuration:"
log_info "  - Install Log: $WO_INSTALL_LOG"
log_info "  - Debug Log: $WO_DEBUG_LOG"
log_info "  - APT Debug Log: $WO_APT_DEBUG_LOG"
log_info "  - Dry Run: $DRY_RUN"
log_info "  - Verbose: $VERBOSE"
log_info "  - System Info Script: ${SYSTEM_INFO_SCRIPT:-none}"

# =========================================================================
# ÉTAPE 1: Collecte d'informations système AVANT installation
# =========================================================================

log_header "ÉTAPE 1: COLLECTE INFORMATIONS SYSTÈME (PRÉ-INSTALLATION)"

if [[ -n "$SYSTEM_INFO_SCRIPT" ]]; then
    run_logged "Collecting system information" \
        "$SYSTEM_INFO_SCRIPT" "$SYSTEM_INFO_LOG"
else
    log_warning "Skipping system information collection (script not found)"
fi

# =========================================================================
# ÉTAPE 2: Vérifications préalables
# =========================================================================

log_header "ÉTAPE 2: VÉRIFICATIONS PRÉALABLES"

# Vérifier qu'on est root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi
log_success "Running as root"

# Vérifier la distribution
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    log_info "Distribution: $NAME $VERSION"
    log_info "Codename: $VERSION_CODENAME"
    
    # Vérifier que c'est Ubuntu ou Debian supporté
    case "$ID" in
        ubuntu)
            case "$VERSION_CODENAME" in
                focal|jammy|noble)
                    log_success "Ubuntu $VERSION_CODENAME is supported"
                    ;;
                *)
                    log_warning "Ubuntu $VERSION_CODENAME may not be officially supported"
                    ;;
            esac
            ;;
        debian)
            case "$VERSION_CODENAME" in
                bullseye|bookworm)
                    log_success "Debian $VERSION_CODENAME is supported"
                    ;;
                *)
                    log_warning "Debian $VERSION_CODENAME may not be officially supported"
                    ;;
            esac
            ;;
        *)
            log_error "Unsupported distribution: $ID"
            exit 1
            ;;
    esac
else
    log_error "/etc/os-release not found"
    exit 1
fi

# =========================================================================
# ÉTAPE 3: Tests de connectivité réseau
# =========================================================================

log_header "ÉTAPE 3: TESTS DE CONNECTIVITÉ"

log_step "Testing DNS resolution"
if nslookup google.com >/dev/null 2>&1; then
    log_success "DNS resolution working"
else
    log_error "DNS resolution failed"
    log_info "DNS servers:"
    cat /etc/resolv.conf
fi

log_step "Testing internet connectivity"
if ping -c 3 -W 5 8.8.8.8 >/dev/null 2>&1; then
    log_success "Internet connectivity OK"
else
    log_error "Cannot reach internet (ping 8.8.8.8 failed)"
fi

log_step "Testing HTTPS connectivity"
if curl -sI https://google.com >/dev/null 2>&1; then
    log_success "HTTPS connectivity OK"
else
    log_error "HTTPS connectivity failed"
fi

# Test des dépôts critiques
log_step "Testing critical repositories"
for repo in \
    "https://packages.sury.org/php/" \
    "https://mariadb.org/mariadb_release_signing_key.pgp" \
    "https://packages.redis.io/gpg" \
    "https://download.opensuse.org/repositories/home:/virtubox:/WordOps/"; do
    
    if curl -sI -m 10 "$repo" >/dev/null 2>&1; then
        log_success "Repository accessible: $repo"
    else
        log_warning "Repository not accessible: $repo"
    fi
done

# =========================================================================
# ÉTAPE 4: Configuration APT avec debug
# =========================================================================

log_header "ÉTAPE 4: CONFIGURATION APT"

log_step "Configuring APT for debug mode"

# Créer un fichier de configuration APT pour le debug
cat > /etc/apt/apt.conf.d/99debug-wordops <<EOF
// Debug configuration for WordOps installation troubleshooting
Debug::pkgProblemResolver "true";
Debug::pkgDepCache::AutoInstall "true";
Debug::Acquire::http "true";
Debug::Acquire::https "true";
Debug::Acquire::gpgv "true";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::Retries "3";
EOF

log_success "APT debug configuration created"

log_step "Updating APT cache with debug"
if [[ $DRY_RUN -eq 0 ]]; then
    apt-get update -o Debug::Acquire::http=true 2>&1 | tee "$WO_APT_DEBUG_LOG" || {
        log_error "APT update failed"
        log_info "Checking for common issues..."
        
        # Vérifier les signatures GPG
        log_info "Checking GPG signatures..."
        apt-get update 2>&1 | grep -i "NO_PUBKEY" || true
        
        # Vérifier les dépôts inaccessibles
        log_info "Checking repository accessibility..."
        apt-get update 2>&1 | grep -i "failed" || true
    }
    log_success "APT update completed"
fi

# =========================================================================
# ÉTAPE 5: Installation des dépendances minimales
# =========================================================================

log_header "ÉTAPE 5: VÉRIFICATION DES DÉPENDANCES"

REQUIRED_PACKAGES=(
    "curl"
    "wget"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "apt-transport-https"
    "software-properties-common"
    "python3"
    "python3-pip"
    "python3-setuptools"
    "python3-dev"
    "build-essential"
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        log_success "Package installed: $pkg"
    else
        log_warning "Package missing: $pkg"
        if [[ $DRY_RUN -eq 0 ]]; then
            log_step "Installing $pkg"
            apt-get install -y "$pkg" 2>&1 | tee -a "$WO_DEBUG_LOG"
        fi
    fi
done

# =========================================================================
# ÉTAPE 6: Téléchargement et exécution du script d'installation WordOps
# =========================================================================

log_header "ÉTAPE 6: INSTALLATION WORDOPS"

if [[ $DRY_RUN -eq 1 ]]; then
    log_info "DRY-RUN mode: Skipping actual WordOps installation"
    log_info "Would download from: https://wops.cc"
else
    log_step "Downloading WordOps installer"
    
    # Télécharger le script d'installation
    if curl -sL -o /tmp/wo-install.sh https://wops.cc 2>&1 | tee -a "$WO_DEBUG_LOG"; then
        log_success "WordOps installer downloaded"
        
        log_info "Installer script preview (first 50 lines):"
        head -50 /tmp/wo-install.sh | tee -a "$WO_DEBUG_LOG"
        
        log_step "Executing WordOps installer"
        
        # Exécuter l'installation avec capture complète
        if bash /tmp/wo-install.sh --force 2>&1 | tee "$WO_INSTALL_LOG"; then
            log_success "WordOps installation completed"
        else
            local exit_code=$?
            log_error "WordOps installation failed with exit code: $exit_code"
            
            # Analyse des erreurs courantes
            log_info "Analyzing installation errors..."
            
            if grep -qi "NO_PUBKEY" "$WO_INSTALL_LOG"; then
                log_error "GPG key missing detected"
                grep -i "NO_PUBKEY" "$WO_INSTALL_LOG" | tee -a "$WO_DEBUG_LOG"
            fi
            
            if grep -qi "unmet dependencies" "$WO_INSTALL_LOG"; then
                log_error "Unmet dependencies detected"
                grep -i "unmet dependencies" "$WO_INSTALL_LOG" | tee -a "$WO_DEBUG_LOG"
            fi
            
            if grep -qi "404\|failed to fetch" "$WO_INSTALL_LOG"; then
                log_error "Repository fetch errors detected"
                grep -iE "404|failed to fetch" "$WO_INSTALL_LOG" | tee -a "$WO_DEBUG_LOG"
            fi
            
            exit $exit_code
        fi
    else
        log_error "Failed to download WordOps installer"
        exit 1
    fi
fi

# =========================================================================
# ÉTAPE 7: Vérification post-installation
# =========================================================================

log_header "ÉTAPE 7: VÉRIFICATION POST-INSTALLATION"

if [[ $DRY_RUN -eq 0 ]]; then
    if command -v wo >/dev/null 2>&1; then
        log_success "WordOps binary found"
        
        log_step "Checking WordOps version"
        wo --version 2>&1 | tee -a "$WO_DEBUG_LOG"
        
        log_step "Checking WordOps stack"
        wo stack status 2>&1 | tee -a "$WO_DEBUG_LOG" || log_warning "Stack status check failed (normal if no stack installed)"
    else
        log_error "WordOps binary not found after installation"
    fi
fi

# =========================================================================
# ÉTAPE 8: Collecte d'informations système APRÈS installation
# =========================================================================

log_header "ÉTAPE 8: COLLECTE INFORMATIONS SYSTÈME (POST-INSTALLATION)"

if [[ -n "$SYSTEM_INFO_SCRIPT" ]]; then
    run_logged "Collecting post-installation system information" \
        "$SYSTEM_INFO_SCRIPT" "$SYSTEM_INFO_POST_LOG"
else
    log_warning "Skipping post-installation system information collection (script not found)"
fi

# =========================================================================
# ÉTAPE 9: Résumé et recommandations
# =========================================================================

log_header "INSTALLATION TERMINÉE"

log_success "All logs saved in /logs/"
log_info "Log files:"
log_info "  - Installation log: $WO_INSTALL_LOG"
log_info "  - Debug log: $WO_DEBUG_LOG"
log_info "  - APT debug log: $WO_APT_DEBUG_LOG"
log_info "  - System info (pre): $SYSTEM_INFO_LOG"
log_info "  - System info (post): $SYSTEM_INFO_POST_LOG"

if [[ $DRY_RUN -eq 0 ]]; then
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review the logs for any errors or warnings"
    log_info "  2. Test WordOps: wo --version"
    log_info "  3. Check stack status: wo stack status"
    log_info "  4. If errors occurred, analyze the logs and system info"
fi

# Nettoyage de la configuration debug APT
log_step "Cleaning up debug configuration"
rm -f /etc/apt/apt.conf.d/99debug-wordops

log_success "Installation script completed successfully"
exit 0
