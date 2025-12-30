#!/usr/bin/env bash
# =========================================================================
# fix-wordops-repo.sh - Correction du dépôt WordOps avec clé GPG expirée
# =========================================================================

set -euo pipefail

LOG_FILE="/logs/fix-repo.log"

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] OK: $1\033[0m" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "\033[0;31m[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m" | tee -a "${LOG_FILE}"
}

echo "=========================================================================" | tee -a "${LOG_FILE}"
echo " FIX WORDOPS REPOSITORY - DEBIAN 12" | tee -a "${LOG_FILE}"
echo "=========================================================================" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

log_info "Problème détecté: Clé GPG WordOps expirée (EXPKEYSIG DA4468F6FB898660)"

# =========================================================================
# 1. Suppression de l'ancien dépôt WordOps
# =========================================================================

log_info "Étape 1/4: Suppression de l'ancien dépôt WordOps..."

if [ -f /etc/apt/sources.list.d/wordops.list ]; then
    rm -f /etc/apt/sources.list.d/wordops.list
    log_success "Ancien fichier de dépôt supprimé"
else
    log_info "Aucun ancien fichier de dépôt trouvé"
fi

# Supprimer les clés GPG obsolètes
log_info "Suppression des clés GPG obsolètes..."
apt-key del DA4468F6FB898660 2>/dev/null || true

# =========================================================================
# 2. Nettoyage du cache APT
# =========================================================================

log_info "Étape 2/4: Nettoyage du cache APT..."
apt-get clean
rm -rf /var/lib/apt/lists/*
log_success "Cache APT nettoyé"

# =========================================================================
# 3. Mise à jour APT sans le dépôt WordOps
# =========================================================================

log_info "Étape 3/4: Mise à jour APT sans le dépôt WordOps..."
if apt-get update 2>&1 | tee -a "${LOG_FILE}"; then
    log_success "APT update réussi"
else
    log_error "Erreur lors de apt-get update"
    exit 1
fi

# =========================================================================
# 4. Information sur l'installation de WordOps
# =========================================================================

log_info "Étape 4/4: WordOps est déjà installé via PIP"

if command -v wo &>/dev/null; then
    WO_VERSION=$(wo --version 2>/dev/null || echo "unknown")
    log_success "WordOps détecté: ${WO_VERSION}"
    log_info "Le dépôt OBS n'est pas nécessaire car WordOps est installé via PIP"
else
    log_info "WordOps n'est pas encore installé"
fi

echo "" | tee -a "${LOG_FILE}"
echo "=========================================================================" | tee -a "${LOG_FILE}"
echo " RÉSOLUTION TERMINÉE" | tee -a "${LOG_FILE}"
echo "=========================================================================" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

log_success "Le problème de dépôt WordOps est résolu"
log_info "Vous pouvez maintenant installer la stack WordOps:"
echo "" | tee -a "${LOG_FILE}"
echo "  wo stack install --nginx --php82 --mysql --redis" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"
log_info "Log complet: ${LOG_FILE}"
