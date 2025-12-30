#!/bin/bash
################################################################################
# Script de vérification des prérequis pour installation WordOps sur VM
# Usage: sudo bash check-vm-requirements.sh
################################################################################

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
ERRORS=0
WARNINGS=0
SUCCESS=0

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Vérification des prérequis WordOps pour VM Debian 12${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Fonction pour afficher les résultats
print_result() {
    local status=$1
    local message=$2
    local details=$3
    
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ((SUCCESS++))
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            if [ -n "$details" ]; then
                echo -e "  ${RED}→${NC} $details"
            fi
            ((ERRORS++))
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠${NC} $message"
            if [ -n "$details" ]; then
                echo -e "  ${YELLOW}→${NC} $details"
            fi
            ((WARNINGS++))
            ;;
    esac
}

# Vérification 1: Script exécuté en tant que root
echo -e "\n${BLUE}[1/8]${NC} Vérification des privilèges..."
if [ "$EUID" -ne 0 ]; then
    print_result "ERROR" "Script non exécuté en tant que root" "Utilisez: sudo bash $0"
else
    print_result "OK" "Script exécuté avec les privilèges root"
fi

# Vérification 2: Distribution Debian 12
echo -e "\n${BLUE}[2/8]${NC} Vérification du système d'exploitation..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
        print_result "OK" "Debian 12 (Bookworm) détecté"
    else
        print_result "WARNING" "Distribution: $PRETTY_NAME" "WordOps est optimisé pour Debian 12"
    fi
else
    print_result "ERROR" "Impossible de détecter la distribution"
fi

# Vérification 3: Configuration Git pour root
echo -e "\n${BLUE}[3/8]${NC} Vérification de la configuration Git pour root..."
if command -v git &> /dev/null; then
    GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
        print_result "ERROR" "Configuration Git manquante pour root" "WordOps nécessite Git configuré"
        echo -e "  ${RED}Solution:${NC}"
        echo -e "    git config --global user.name \"Votre Nom\""
        echo -e "    git config --global user.email \"votre@email.com\""
    else
        print_result "OK" "Git configuré: $GIT_USER <$GIT_EMAIL>"
        
        # Vérifier les permissions du fichier .gitconfig
        if [ -f /root/.gitconfig ]; then
            GITCONFIG_PERMS=$(stat -c "%a" /root/.gitconfig)
            GITCONFIG_OWNER=$(stat -c "%U:%G" /root/.gitconfig)
            
            if [ "$GITCONFIG_OWNER" = "root:root" ] && [ "$GITCONFIG_PERMS" = "644" -o "$GITCONFIG_PERMS" = "600" ]; then
                print_result "OK" "Permissions .gitconfig correctes ($GITCONFIG_PERMS, $GITCONFIG_OWNER)"
            else
                print_result "WARNING" "Permissions .gitconfig inhabituelles" "$GITCONFIG_PERMS, $GITCONFIG_OWNER (attendu: 644, root:root)"
            fi
        fi
    fi
else
    print_result "ERROR" "Git n'est pas installé" "Installez avec: apt-get install -y git"
fi

# Vérification 4: Connexion Internet
echo -e "\n${BLUE}[4/8]${NC} Vérification de la connexion Internet..."
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    print_result "OK" "Connexion Internet active"
else
    print_result "ERROR" "Pas de connexion Internet" "Nécessaire pour télécharger les paquets"
fi

# Vérification 5: Résolution DNS
echo -e "\n${BLUE}[5/8]${NC} Vérification de la résolution DNS..."
if ping -c 1 -W 2 google.com &> /dev/null; then
    print_result "OK" "Résolution DNS fonctionnelle"
else
    print_result "WARNING" "Problème de résolution DNS" "Vérifiez /etc/resolv.conf"
fi

# Vérification 6: Espace disque disponible
echo -e "\n${BLUE}[6/8]${NC} Vérification de l'espace disque..."
DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$DISK_AVAILABLE > 5" | bc -l) )); then
    print_result "OK" "Espace disque disponible: ${DISK_AVAILABLE}G"
else
    print_result "WARNING" "Espace disque faible: ${DISK_AVAILABLE}G" "Recommandé: >10G"
fi

# Vérification 7: Mémoire RAM
echo -e "\n${BLUE}[7/8]${NC} Vérification de la mémoire RAM..."
RAM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
if [ "$RAM_TOTAL" -gt 1500 ]; then
    print_result "OK" "RAM totale: ${RAM_TOTAL}MB"
elif [ "$RAM_TOTAL" -gt 900 ]; then
    print_result "WARNING" "RAM totale: ${RAM_TOTAL}MB" "Recommandé: ≥2GB pour production"
else
    print_result "ERROR" "RAM insuffisante: ${RAM_TOTAL}MB" "Minimum: 1GB, Recommandé: 2GB"
fi

# Vérification 8: Vérifier si WordOps est déjà installé
echo -e "\n${BLUE}[8/8]${NC} Vérification de WordOps..."
if command -v wo &> /dev/null; then
    WO_VERSION=$(wo --version 2>&1 | grep -oP 'WordOps \K[0-9.]+' || echo "inconnu")
    print_result "WARNING" "WordOps déjà installé (version $WO_VERSION)" "Réinstallation possible"
else
    print_result "OK" "WordOps non installé (prêt pour l'installation)"
fi

# Vérification bonus: Conflit avec le dossier 'wo'
echo -e "\n${BLUE}[Bonus]${NC} Vérification du répertoire courant..."
if [ -d "./wo" ]; then
    print_result "ERROR" "Dossier 'wo/' détecté dans le répertoire courant" "N'installez PAS WordOps depuis le répertoire du projet Git. Utilisez: cd ~"
else
    print_result "OK" "Pas de conflit avec un dossier 'wo'"
fi

# Résumé final
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Résumé de la vérification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Succès:${NC}        $SUCCESS"
echo -e "${YELLOW}Avertissements:${NC} $WARNINGS"
echo -e "${RED}Erreurs:${NC}       $ERRORS"
echo ""

# Conclusion
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Le système est prêt pour l'installation de WordOps${NC}"
    echo ""
    echo -e "${BLUE}Commandes d'installation:${NC}"
    echo -e "  cd ~"
    echo -e "  wget -qO wo wordops.net/wssl"
    echo -e "  sudo bash wo"
    echo ""
    exit 0
elif [ $ERRORS -le 2 ]; then
    echo -e "${YELLOW}⚠ Certains prérequis ne sont pas satisfaits${NC}"
    echo -e "${YELLOW}  Corrigez les erreurs ci-dessus avant d'installer WordOps${NC}"
    echo ""
    exit 1
else
    echo -e "${RED}✗ Plusieurs erreurs critiques détectées${NC}"
    echo -e "${RED}  Le système n'est PAS prêt pour WordOps${NC}"
    echo ""
    exit 2
fi
