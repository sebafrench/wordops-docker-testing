#!/usr/bin/env bash
# Script pour installer WordOps sur une VM Debian 12
# Usage: bash vm-install.sh

set -e

echo "=== Installation de WordOps sur VM Debian 12 ==="

# Créer le répertoire de logs
echo "[1/4] Création du répertoire de logs..."
sudo mkdir -p /logs
sudo chmod 777 /logs

# Cloner le repository dans /tmp
echo "[2/4] Clonage du repository..."
cd /tmp
rm -rf wordops-docker-testing
git clone https://github.com/sebafrench/wordops-docker-testing.git

# Lancer l'installation
echo "[3/4] Lancement de l'installation WordOps..."
cd /tmp/wordops-docker-testing
# Donner les permissions d'exécution aux scripts
sudo chmod +x scripts/*.sh
sudo bash scripts/install-wordops.sh

# Vérifier l'installation
echo "[4/4] Vérification de l'installation..."
if command -v wo &> /dev/null; then
    echo "✓ WordOps installé avec succès!"
    wo --version
    echo ""
    echo "Pour créer un site WordPress :"
    echo "  sudo wo stack install --nginx --php82 --mysql --redis"
    echo "  sudo wo site create test.local --wp --php82 --redis"
else
    echo "✗ Erreur : WordOps n'est pas installé"
    echo "Consultez les logs dans /logs/"
    exit 1
fi
