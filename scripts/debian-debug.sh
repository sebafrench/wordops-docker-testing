#!/usr/bin/env bash
# =========================================================================
# Script de diagnostic détaillé pour Debian 12
# =========================================================================
# Ce script collecte toutes les informations de debug nécessaires
# pour diagnostiquer les problèmes d'installation WordOps sur Debian
# =========================================================================

set -e

LOG_DIR="/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEBUG_LOG="${LOG_DIR}/debian-debug-${TIMESTAMP}.log"

# =========================================================================
# Fonctions de logging améliorées
# =========================================================================

log_section() {
    echo "" | tee -a "${DEBUG_LOG}"
    echo "=========================================================================" | tee -a "${DEBUG_LOG}"
    echo " $1" | tee -a "${DEBUG_LOG}"
    echo "=========================================================================" | tee -a "${DEBUG_LOG}"
}

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "${DEBUG_LOG}"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${DEBUG_LOG}"
}

log_command() {
    local cmd="$1"
    echo "" | tee -a "${DEBUG_LOG}"
    echo ">>> Command: ${cmd}" | tee -a "${DEBUG_LOG}"
    echo "---" | tee -a "${DEBUG_LOG}"
    eval "${cmd}" 2>&1 | tee -a "${DEBUG_LOG}"
    local exit_code=$?
    echo "Exit code: ${exit_code}" | tee -a "${DEBUG_LOG}"
    return ${exit_code}
}

# =========================================================================
# Début du diagnostic
# =========================================================================

log_section "DIAGNOSTIC DEBIAN 12 - ${TIMESTAMP}"

log_section "1. INFORMATIONS SYSTÈME"
log_command "cat /etc/os-release"
log_command "uname -a"
log_command "hostnamectl"

log_section "2. ÉTAT DES DÉPÔTS APT"
log_info "Fichiers de sources APT:"
log_command "ls -la /etc/apt/sources.list.d/"
log_command "cat /etc/apt/sources.list"

log_info "Contenu des fichiers de dépôts:"
for file in /etc/apt/sources.list.d/*.list; do
    if [ -f "$file" ]; then
        log_info "=== $file ==="
        log_command "cat $file"
    fi
done

log_section "3. CLÉS GPG"
log_command "apt-key list 2>&1 || true"
log_command "ls -la /etc/apt/trusted.gpg.d/"
log_command "ls -la /usr/share/keyrings/ 2>&1 || true"

log_section "4. TEST DE MISE À JOUR APT (VERBOSE)"
log_info "Nettoyage du cache APT..."
log_command "apt-get clean"
log_command "rm -rf /var/lib/apt/lists/*"

log_info "Mise à jour avec verbosité maximale..."
if log_command "apt-get update -o Debug::pkgAcquire::Worker=1 -o Debug::Acquire::http=1 2>&1"; then
    log_info "APT update réussi"
else
    log_error "Échec de apt-get update"
    log_section "4.1. DIAGNOSTIC APPROFONDI DE L'ÉCHEC APT"
    
    log_info "Vérification de la connectivité réseau:"
    log_command "ping -c 3 8.8.8.8 || true"
    log_command "ping -c 3 packages.sury.org || true"
    log_command "ping -c 3 nginx.org || true"
    
    log_info "Test de résolution DNS:"
    log_command "cat /etc/resolv.conf"
    log_command "nslookup packages.sury.org || true"
    log_command "nslookup nginx.org || true"
    
    log_info "Test de connexion HTTPS:"
    log_command "curl -v https://packages.sury.org 2>&1 | head -30 || true"
    log_command "curl -v https://nginx.org 2>&1 | head -30 || true"
    
    log_info "Vérification des certificats CA:"
    log_command "ls -la /etc/ssl/certs/ | head -20"
    log_command "update-ca-certificates -v 2>&1 || true"
fi

log_section "5. ÉTAT DES PACKAGES CRITIQUES"
log_command "dpkg -l | grep -E 'apt|gnupg|ca-certificates|curl|wget' || true"

log_section "6. LOGS APT ET DPKG"
log_info "Dernières lignes de /var/log/apt/term.log:"
log_command "tail -100 /var/log/apt/term.log 2>&1 || echo 'Fichier non trouvé'"

log_info "Dernières lignes de /var/log/dpkg.log:"
log_command "tail -100 /var/log/dpkg.log 2>&1 || echo 'Fichier non trouvé'"

log_section "7. WORDOPS - ÉTAT"
log_info "Version WordOps:"
log_command "wo --version 2>&1 || echo 'WordOps non installé ou erreur'"

log_info "Logs WordOps récents:"
log_command "tail -200 /var/log/wo/wordops.log 2>&1 || echo 'Log WordOps non trouvé'"

log_section "8. ESPACE DISQUE ET MÉMOIRE"
log_command "df -h"
log_command "free -h"
log_command "du -sh /var/cache/apt/*"

log_section "9. PROCESSUS EN COURS"
log_command "ps aux | head -30"

log_section "10. VARIABLES D'ENVIRONNEMENT"
log_command "env | sort"

log_section "11. FICHIERS DE CONFIGURATION WORDOPS"
if [ -d "/etc/wo" ]; then
    log_info "Configuration WordOps présente:"
    log_command "find /etc/wo -type f -exec echo '=== {} ===' \; -exec cat {} \; 2>&1 || true"
else
    log_info "Répertoire /etc/wo non trouvé"
fi

# =========================================================================
# Test spécifique: Ajout manuel des dépôts
# =========================================================================

log_section "12. TEST D'AJOUT MANUEL DES DÉPÔTS"

log_info "Test 1: Ajout du dépôt PHP Sury (méthode manuelle)"
log_command "curl -sSL https://packages.sury.org/php/README.txt 2>&1 | head -20 || true"

log_info "Test 2: Vérification de la clé GPG Sury"
log_command "curl -sSL https://packages.sury.org/php/apt.gpg 2>&1 | wc -c || true"

log_info "Test 3: Ajout du dépôt Nginx (méthode manuelle)"
log_command "curl -sSL https://nginx.org/keys/nginx_signing.key 2>&1 | head -20 || true"

# =========================================================================
# Résumé et recommandations
# =========================================================================

log_section "RÉSUMÉ DU DIAGNOSTIC"

log_info "Fichier de log complet: ${DEBUG_LOG}"
log_info "Taille du log: $(du -h ${DEBUG_LOG} | cut -f1)"

echo ""
echo "========================================================================="
echo " DIAGNOSTIC TERMINÉ"
echo "========================================================================="
echo ""
echo "Le fichier de log détaillé est disponible dans:"
echo "  ${DEBUG_LOG}"
echo ""
echo "Pour copier les logs sur l'hôte:"
echo "  docker cp wordops-debian12-test:${DEBUG_LOG} ./logs/"
echo ""
echo "Pour analyser l'erreur APT spécifique:"
echo "  grep -A 10 'ERROR' ${DEBUG_LOG}"
echo ""
echo "========================================================================="
