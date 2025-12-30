#!/usr/bin/env bash
# =========================================================================
# repro.sh - Script de reproduction automatique des tests WordOps
# =========================================================================
# Purpose: Automatiser la création, le test et la collecte de logs
# Usage: ./scripts/repro.sh [ubuntu|debian|both] [--rebuild] [--interactive]
# =========================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_DIR/logs"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables par défaut
TARGET="${1:-ubuntu}"
REBUILD=0
INTERACTIVE=0

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        ubuntu|debian|both)
            TARGET="$1"
            shift
            ;;
        --rebuild|-r)
            REBUILD=1
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=1
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [TARGET] [OPTIONS]

TARGETS:
    ubuntu      Test sur Ubuntu 22.04 uniquement (défaut)
    debian      Test sur Debian 12 uniquement
    both        Test sur Ubuntu ET Debian

OPTIONS:
    --rebuild, -r       Rebuild les images Docker
    --interactive, -i   Lance un shell interactif au lieu d'installer
    --help, -h          Affiche cette aide

EXEMPLES:
    $0 ubuntu              # Test Ubuntu avec images en cache
    $0 debian --rebuild    # Test Debian avec rebuild
    $0 both                # Test Ubuntu et Debian
    $0 ubuntu -i           # Shell interactif Ubuntu

LOGS:
    Tous les logs sont sauvegardés dans ./logs/

EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
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

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# Vérifier que Docker est installé et actif
check_docker() {
    log_step "Checking Docker installation"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        log_info "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Please start Docker daemon"
        exit 1
    fi
    
    log_success "Docker is installed and running"
    
    # Vérifier Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available"
        log_info "Please install Docker Compose V2"
        exit 1
    fi
    
    log_success "Docker Compose is available"
}

# Créer le répertoire de logs
setup_logs_dir() {
    log_step "Setting up logs directory"
    
    mkdir -p "$LOGS_DIR"
    
    # Nettoyer les anciens logs si demandé
    if [[ -n "$(ls -A "$LOGS_DIR" 2>/dev/null)" ]]; then
        log_warning "Logs directory is not empty"
        log_info "Previous logs will be preserved with timestamp"
        
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        BACKUP_DIR="$LOGS_DIR/backup-$TIMESTAMP"
        mkdir -p "$BACKUP_DIR"
        
        # Déplacer les anciens logs
        find "$LOGS_DIR" -maxdepth 1 -type f -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true
        
        log_info "Previous logs moved to: $BACKUP_DIR"
    fi
    
    log_success "Logs directory ready: $LOGS_DIR"
}

# Fonction pour tester une distribution
test_distribution() {
    local distro=$1
    local profile=$2
    local container_name=$3
    
    log_header "TESTING: $distro"
    
    # Changer vers le répertoire du projet
    cd "$PROJECT_DIR"
    
    # Options de build
    local build_opts=""
    if [[ $REBUILD -eq 1 ]]; then
        build_opts="--build --force-recreate --no-cache"
        log_info "Rebuilding images from scratch"
    else
        build_opts="--build"
    fi
    
    # Mode interactif
    if [[ $INTERACTIVE -eq 1 ]]; then
        log_info "Starting interactive shell in $distro container"
        log_info "To install WordOps manually, run: /usr/local/bin/install-wordops.sh"
        log_info "To collect system info, run: /usr/local/bin/system-info.sh /logs/manual-info.log"
        
        docker compose --profile "$profile" run --rm "$container_name" bash
        return $?
    fi
    
    # Démarrer le container
    log_step "Starting container"
    if ! docker compose --profile "$profile" up $build_opts -d 2>&1 | tee "$LOGS_DIR/docker-compose-$distro.log"; then
        log_error "Failed to start $distro container"
        return 1
    fi
    
    # Attendre que systemd soit prêt
    log_step "Waiting for systemd to be ready"
    local max_wait=60
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        if docker exec "$container_name" systemctl is-system-running --wait 2>/dev/null | grep -qE "running|degraded"; then
            log_success "Systemd is ready"
            break
        fi
        
        sleep 2
        waited=$((waited + 2))
        
        if [[ $waited -ge $max_wait ]]; then
            log_warning "Systemd took too long to start, continuing anyway"
        fi
    done
    
    # Exécuter le script d'installation
    log_step "Running WordOps installation"
    
    if docker exec "$container_name" /usr/local/bin/install-wordops.sh 2>&1 | tee "$LOGS_DIR/installation-$distro-console.log"; then
        log_success "Installation script completed successfully"
        local install_status=0
    else
        local exit_code=$?
        log_error "Installation script failed with exit code: $exit_code"
        local install_status=$exit_code
    fi
    
    # Copier tous les logs du container vers l'hôte
    log_step "Collecting logs from container"
    
    # Les logs sont déjà dans ./logs via le volume mount
    # Mais on va aussi copier certains fichiers système
    docker exec "$container_name" bash -c "
        if [ -f /var/log/wo/install.log ]; then
            cp /var/log/wo/install.log /logs/wo-install-internal-$distro.log
        fi
        if [ -f /var/log/wo/wordops.log ]; then
            cp /var/log/wo/wordops.log /logs/wo-wordops-$distro.log
        fi
    " 2>/dev/null || log_warning "Some internal WordOps logs may not be available"
    
    log_success "Logs collected in: $LOGS_DIR"
    
    # Afficher un résumé
    log_header "INSTALLATION SUMMARY: $distro"
    
    if [[ $install_status -eq 0 ]]; then
        log_success "Installation completed successfully"
        
        # Vérifier que WordOps est installé
        if docker exec "$container_name" wo --version 2>&1 | tee "$LOGS_DIR/wo-version-$distro.log"; then
            log_success "WordOps is installed and working"
        else
            log_warning "WordOps binary found but version check failed"
        fi
    else
        log_error "Installation failed"
        
        # Analyser les erreurs
        log_info "Analyzing errors..."
        
        if [[ -f "$LOGS_DIR/wo-install-$distro.log" ]]; then
            log_info "Common errors found:"
            
            if grep -qi "NO_PUBKEY" "$LOGS_DIR/wo-install-$distro.log"; then
                log_error "  - GPG key missing"
                grep -i "NO_PUBKEY" "$LOGS_DIR/wo-install-$distro.log" | head -5
            fi
            
            if grep -qi "unmet dependencies" "$LOGS_DIR/wo-install-$distro.log"; then
                log_error "  - Unmet dependencies"
                grep -i "unmet dependencies" "$LOGS_DIR/wo-install-$distro.log" | head -5
            fi
            
            if grep -qiE "404|failed to fetch" "$LOGS_DIR/wo-install-$distro.log"; then
                log_error "  - Repository fetch errors"
                grep -iE "404|failed to fetch" "$LOGS_DIR/wo-install-$distro.log" | head -5
            fi
            
            if grep -qi "could not resolve" "$LOGS_DIR/wo-install-$distro.log"; then
                log_error "  - DNS resolution errors"
                grep -i "could not resolve" "$LOGS_DIR/wo-install-$distro.log" | head -5
            fi
        fi
    fi
    
    # Garder le container pour investigation ou le supprimer
    log_info "Container $container_name is still running for investigation"
    log_info "To access it: docker exec -it $container_name bash"
    log_info "To stop it: docker compose --profile $profile down"
    
    return $install_status
}

# Fonction de nettoyage
cleanup() {
    log_header "CLEANUP"
    
    log_info "Stopping all containers"
    docker compose down 2>/dev/null || true
    
    if [[ $REBUILD -eq 1 ]]; then
        log_info "Removing volumes (--rebuild mode)"
        docker compose down -v 2>/dev/null || true
    fi
    
    log_success "Cleanup completed"
}

# Trap pour nettoyer en cas d'interruption
trap cleanup EXIT INT TERM

# =========================================================================
# MAIN
# =========================================================================

log_header "WORDOPS INSTALLATION REPRODUCTION SCRIPT"

log_info "Configuration:"
log_info "  - Target: $TARGET"
log_info "  - Rebuild: $REBUILD"
log_info "  - Interactive: $INTERACTIVE"
log_info "  - Project dir: $PROJECT_DIR"
log_info "  - Logs dir: $LOGS_DIR"

# Vérifications préalables
check_docker
setup_logs_dir

# Exécuter les tests selon la cible
case "$TARGET" in
    ubuntu)
        test_distribution "Ubuntu 22.04" "ubuntu" "wordops-ubuntu22-test"
        exit_code=$?
        ;;
    debian)
        test_distribution "Debian 12" "debian" "wordops-debian12-test"
        exit_code=$?
        ;;
    both)
        log_info "Testing both distributions sequentially"
        
        test_distribution "Ubuntu 22.04" "ubuntu" "wordops-ubuntu22-test"
        ubuntu_exit=$?
        
        # Nettoyer entre les deux tests
        docker compose --profile ubuntu down
        
        test_distribution "Debian 12" "debian" "wordops-debian12-test"
        debian_exit=$?
        
        # Code de sortie global
        if [[ $ubuntu_exit -eq 0 ]] && [[ $debian_exit -eq 0 ]]; then
            exit_code=0
        else
            exit_code=1
        fi
        
        log_header "FINAL SUMMARY"
        
        if [[ $ubuntu_exit -eq 0 ]]; then
            log_success "Ubuntu 22.04: PASSED"
        else
            log_error "Ubuntu 22.04: FAILED"
        fi
        
        if [[ $debian_exit -eq 0 ]]; then
            log_success "Debian 12: PASSED"
        else
            log_error "Debian 12: FAILED"
        fi
        ;;
    *)
        log_error "Invalid target: $TARGET"
        echo "Valid targets: ubuntu, debian, both"
        exit 1
        ;;
esac

log_header "TEST COMPLETED"

if [[ $exit_code -eq 0 ]]; then
    log_success "All tests passed"
else
    log_error "Some tests failed"
    log_info "Review the logs in: $LOGS_DIR"
fi

# Ne pas nettoyer automatiquement pour permettre l'investigation
trap - EXIT

log_info "Containers are still running for investigation"
log_info "To clean up manually: docker compose down -v"

exit $exit_code
