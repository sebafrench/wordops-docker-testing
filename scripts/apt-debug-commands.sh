# =========================================================================
# Commandes APT Debug - Guide de Référence
# =========================================================================
# Ce fichier contient toutes les commandes APT avec options de debug
# pour diagnostiquer les problèmes d'installation WordOps
# =========================================================================

# =========================================================================
# 1. CONFIGURATION APT POUR LE DEBUG
# =========================================================================

# Créer un fichier de configuration APT pour activer le debug
sudo tee /etc/apt/apt.conf.d/99debug <<EOF
Debug::pkgProblemResolver "true";
Debug::pkgDepCache::AutoInstall "true";
Debug::Acquire::http "true";
Debug::Acquire::https "true";
Debug::Acquire::gpgv "true";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::Retries "3";
EOF

# Alternative : options en ligne de commande
apt-get update \
    -o Debug::pkgProblemResolver=yes \
    -o Debug::Acquire::http=yes \
    -o Debug::Acquire::https=yes \
    -o Debug::Acquire::gpgv=yes

# =========================================================================
# 2. APT UPDATE AVEC DEBUG
# =========================================================================

# Update basique avec verbosité
apt-get update -V

# Update avec debug complet
apt-get update \
    -o Debug::Acquire::http=true \
    -o Debug::Acquire::https=true \
    -o Debug::Acquire::gpgv=true \
    2>&1 | tee apt-update-debug.log

# Update avec affichage des URLs
apt-get update -o Acquire::http::Dl-Limit=0 -o Debug::Acquire::http=true

# Vérifier uniquement les signatures GPG
apt-get update -o Debug::Acquire::gpgv=true

# =========================================================================
# 3. APT INSTALL AVEC DEBUG
# =========================================================================

# Installation avec résolution de problèmes
apt-get install -y package-name \
    -o Debug::pkgProblemResolver=true \
    -o Debug::pkgDepCache::AutoInstall=true \
    2>&1 | tee apt-install-debug.log

# Installation avec simulation (dry-run)
apt-get install -s package-name

# Installation avec affichage des dépendances
apt-get install --no-install-recommends -s package-name

# Téléchargement uniquement (sans installer)
apt-get install --download-only package-name

# =========================================================================
# 4. DIAGNOSTIC DES SOURCES APT
# =========================================================================

# Lister toutes les sources configurées
cat /etc/apt/sources.list
cat /etc/apt/sources.list.d/*

# Afficher la configuration APT complète
apt-config dump

# Vérifier les préférences de packages
apt-cache policy

# Policy d'un package spécifique
apt-cache policy package-name

# Vérifier les dépendances d'un package
apt-cache depends package-name

# Vérifier les packages qui dépendent d'un package
apt-cache rdepends package-name

# =========================================================================
# 5. DIAGNOSTIC DES CLÉS GPG
# =========================================================================

# Lister les clés APT (méthode dépréciée mais utile)
apt-key list

# Lister les keyrings modernes
ls -la /etc/apt/keyrings/
ls -la /usr/share/keyrings/
ls -la /etc/apt/trusted.gpg.d/

# Vérifier une clé spécifique
gpg --keyring /usr/share/keyrings/keyring-name.gpg --list-keys

# Ajouter une clé GPG (nouvelle méthode)
curl -fsSL https://example.com/key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/example-keyring.gpg

# Ajouter une source avec la clé
echo "deb [signed-by=/usr/share/keyrings/example-keyring.gpg] https://repo.example.com/ distro main" | \
    tee /etc/apt/sources.list.d/example.list

# =========================================================================
# 6. TESTS DE CONNECTIVITÉ RÉSEAU
# =========================================================================

# Tester la résolution DNS
nslookup packages.debian.org
dig packages.debian.org

# Tester la connectivité HTTP
curl -I http://deb.debian.org/debian/
curl -v http://deb.debian.org/debian/ 2>&1 | grep -i "connected"

# Tester la connectivité HTTPS avec détails
curl -v https://packages.sury.org/php/ 2>&1

# Tester avec wget
wget --spider --server-response https://packages.sury.org/php/

# Vérifier les certificats SSL
openssl s_client -connect packages.sury.org:443 -servername packages.sury.org

# =========================================================================
# 7. DIAGNOSTIC DES PROBLÈMES COURANTS
# =========================================================================

# Problème : NO_PUBKEY
# Solution : Identifier la clé manquante
apt-get update 2>&1 | grep NO_PUBKEY
# La sortie affichera : NO_PUBKEY XXXXXXXXXXXXXXXX
# Ajouter la clé :
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys XXXXXXXXXXXXXXXX
# Ou avec la nouvelle méthode :
gpg --keyserver keyserver.ubuntu.com --recv-keys XXXXXXXXXXXXXXXX
gpg --export XXXXXXXXXXXXXXXX | sudo tee /usr/share/keyrings/missing-key.gpg

# Problème : Unmet dependencies
# Solution : Afficher l'arbre de dépendances
apt-cache depends package-name
apt-get install -f  # Tenter de réparer
apt-get install package-name --fix-missing

# Problème : 404 / Repository not found
# Solution : Vérifier les URLs des sources
grep -r "^deb " /etc/apt/sources.list /etc/apt/sources.list.d/
# Tester chaque URL manuellement
curl -I https://repository-url/

# Problème : Hash sum mismatch
# Solution : Nettoyer le cache APT
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update

# Problème : Could not resolve
# Solution : Vérifier DNS
cat /etc/resolv.conf
# Ajouter des DNS publics temporairement
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# =========================================================================
# 8. COMMANDES DE NETTOYAGE ET RÉPARATION
# =========================================================================

# Nettoyer le cache APT
apt-get clean
apt-get autoclean

# Supprimer les listes de packages
rm -rf /var/lib/apt/lists/*
apt-get update

# Réparer les packages cassés
apt-get install -f
dpkg --configure -a

# Reconfigurer tous les packages
dpkg-reconfigure -a

# Forcer la réinstallation d'un package
apt-get install --reinstall package-name

# =========================================================================
# 9. ANALYSE DES LOGS APT
# =========================================================================

# Logs APT
cat /var/log/apt/term.log
cat /var/log/apt/history.log

# Logs dpkg
cat /var/log/dpkg.log

# Rechercher des erreurs dans les logs
grep -i error /var/log/apt/term.log
grep -i "NO_PUBKEY" /var/log/apt/term.log

# =========================================================================
# 10. VÉRIFICATION DE L'ÉTAT DU SYSTÈME
# =========================================================================

# Packages installés
dpkg -l
dpkg -l | grep -E "^ii" | wc -l  # Nombre de packages installés

# Packages avec problèmes
dpkg -l | grep -E "^(rc|iU)"

# Espace disque
df -h /var/cache/apt/
df -h /var/lib/apt/

# Vérifier les processus APT/dpkg en cours
ps aux | grep -E "apt|dpkg"
lsof /var/lib/dpkg/lock-frontend
lsof /var/lib/apt/lists/lock

# =========================================================================
# 11. WORDOPS SPÉCIFIQUE - REPOSITORIES
# =========================================================================

# Test repository PHP Sury
curl -I https://packages.sury.org/php/
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor | \
    sudo tee /usr/share/keyrings/deb.sury.org-php.gpg

# Test repository MariaDB
curl -I https://mariadb.org/mariadb_release_signing_key.pgp
curl -o /etc/apt/keyrings/mariadb-keyring.pgp \
    'https://mariadb.org/mariadb_release_signing_key.pgg'

# Test repository Redis
curl -I https://packages.redis.io/gpg
curl -fsSL https://packages.redis.io/gpg | \
    gpg --dearmor | sudo tee /usr/share/keyrings/redis-archive-keyring.gpg

# Test repository WordOps/Nginx (OpenSUSE Build Service)
DISTRO_VERSION=$(lsb_release -rs | grep -oE '[0-9]+')
DISTRO_NAME=$(lsb_release -is)
curl -I "https://download.opensuse.org/repositories/home:/virtubox:/WordOps/${DISTRO_NAME}_${DISTRO_VERSION}/"

# =========================================================================
# 12. SCRIPT DE DIAGNOSTIC COMPLET
# =========================================================================

# Créer un script de diagnostic complet
cat > /tmp/apt-diagnostic.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail

echo "=== APT DIAGNOSTIC SCRIPT ==="
echo "Date: $(date)"
echo ""

echo "=== DISTRIBUTION ==="
cat /etc/os-release
echo ""

echo "=== APT SOURCES ==="
cat /etc/apt/sources.list
ls -la /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/* 2>/dev/null || true
echo ""

echo "=== APT KEYRINGS ==="
ls -la /etc/apt/keyrings/ 2>/dev/null || true
ls -la /usr/share/keyrings/ 2>/dev/null || true
echo ""

echo "=== APT UPDATE TEST ==="
apt-get update -o Debug::Acquire::http=true 2>&1 | head -100
echo ""

echo "=== DNS TEST ==="
cat /etc/resolv.conf
nslookup google.com
echo ""

echo "=== CONNECTIVITY TEST ==="
curl -I https://packages.sury.org/php/ 2>&1 | head -20
echo ""

echo "=== DISK SPACE ==="
df -h
echo ""

echo "=== APT PROCESSES ==="
ps aux | grep -E "apt|dpkg" | grep -v grep
echo ""

echo "=== DIAGNOSTIC COMPLETE ==="
SCRIPT

chmod +x /tmp/apt-diagnostic.sh
/tmp/apt-diagnostic.sh | tee /tmp/apt-diagnostic.log

# =========================================================================
# FIN
# =========================================================================
