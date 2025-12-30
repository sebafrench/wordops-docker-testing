# Installation WordOps sur VM Debian 12

Guide complet pour installer WordOps sur une machine virtuelle Debian 12.

---

## 📋 Table des Matières

- [Prérequis VM](#prérequis-vm)
- [Installation Debian 12](#installation-debian-12)
- [Configuration Système](#configuration-système)
- [Installation WordOps](#installation-wordops)
- [Création d'un Site WordPress](#création-dun-site-wordpress)
- [Dépannage](#dépannage)

---

## 🖥️ Prérequis VM

### Spécifications Minimales

| Ressource | Minimum | Recommandé |
|-----------|---------|------------|
| CPU | 1 core | 2+ cores |
| RAM | 1 GB | 2-4 GB |
| Disque | 10 GB | 20-40 GB |
| Réseau | NAT ou Bridge | Bridge (pour accès externe) |

### Logiciels de Virtualisation

- **VirtualBox** (gratuit) - [Download](https://www.virtualbox.org/)
- **VMware Workstation Player** (gratuit pour usage personnel)
- **Hyper-V** (Windows Pro/Enterprise)
- **QEMU/KVM** (Linux)

---

## 💿 Installation Debian 12

### 1. Télécharger l'ISO

```bash
# ISO Debian 12 (Bookworm) netinstall
https://www.debian.org/CD/netinst/
# Fichier: debian-12.X.X-amd64-netinst.iso (~600 MB)
```

### 2. Créer la VM

**VirtualBox (exemple) :**
1. Nouvelle VM → Nom: "WordOps-Debian12"
2. Type: Linux, Version: Debian (64-bit)
3. RAM: 2048 MB
4. Disque: 20 GB (VDI, dynamique)
5. Réseau: Bridge Adapter (ou NAT avec port forwarding)

**Configuration réseau NAT avec accès HTTP/HTTPS :**
```
VM → Settings → Network → Adapter 1 → NAT
→ Advanced → Port Forwarding:
  - HTTP:  Host 8080 → Guest 80
  - HTTPS: Host 8443 → Guest 443
  - SSH:   Host 2222 → Guest 22
```

### 3. Installation Debian

Démarrer la VM avec l'ISO et suivre l'installateur :

1. **Langue** : Français ou English
2. **Réseau** : Configurer automatiquement (DHCP)
3. **Hostname** : `wordops-vm` (ou votre choix)
4. **Domaine** : laisser vide ou `local`
5. **Mot de passe root** : Définir un mot de passe fort
6. **Utilisateur** : Créer un compte (ex: `admin`)
7. **Partitionnement** : Assisté - utiliser le disque entier
8. **Miroir** : Sélectionner votre pays
9. **Logiciels** :
   - ✅ Utilitaires usuels du système
   - ✅ Serveur SSH
   - ❌ Environnement de bureau (pas nécessaire)
   - ❌ Serveur web (WordOps l'installera)

---

## ⚙️ Configuration Système

### 1. Première Connexion

```bash
# Se connecter en SSH depuis Windows
ssh admin@localhost -p 2222

# Ou directement dans la console VM
# Login: admin
# Password: votre_mot_de_passe
```

### 2. Passer en root

```bash
su -
# Entrer le mot de passe root
```

### 3. Mettre à jour le système

```bash
apt update && apt upgrade -y
```

### 4. Installer les dépendances essentielles

```bash
apt install -y \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    git \
    vim
```

### 5. Configurer Git pour ROOT (OBLIGATOIRE pour WordOps)

```bash
# WordOps s'exécute avec sudo (en tant que root)
# Git doit donc être configuré pour root
sudo git config --global user.name "Votre Nom"
sudo git config --global user.email "votre@email.com"

# Vérifier la configuration pour root
sudo git config --global --list
sudo ls -la /root/.gitconfig
sudo cat /root/.gitconfig
```

**⚠️ IMPORTANT :**
- WordOps s'exécute toujours avec `sudo` (en tant que root)
- Git doit donc être configuré pour root avec `sudo git config`
- Le fichier `/root/.gitconfig` doit exister avec permissions `644` et propriétaire `root:root`
- Cette étape est **OBLIGATOIRE**, sinon WordOps échouera avec: `PermissionError: '/root/.gitconfig'`

### 6. Configurer sudo pour votre utilisateur

```bash
# Ajouter l'utilisateur au groupe sudo
usermod -aG sudo admin

# Ou créer un fichier sudoers spécifique
echo "admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admin
chmod 440 /etc/sudoers.d/admin
```

### 7. Configuration réseau (optionnel)

**Pour une IP statique (au lieu de DHCP) :**

```bash
nano /etc/network/interfaces
```

```
# Interface principale (vérifier le nom avec: ip a)
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

Redémarrer le réseau :
```bash
systemctl restart networking
```

---

## � Vérification des Prérequis

Avant d'installer WordOps, exécutez le script de vérification automatique :

```bash
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git
sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh
```

**Ce script vérifie :**
- ✓ Privilèges root
- ✓ Distribution Debian 12
- ✓ **Configuration Git pour root**
- ✓ **Permissions `/root/.gitconfig`**
- ✓ Connexion Internet
- ✓ Résolution DNS
- ✓ Espace disque (>5GB)
- ✓ RAM (>1GB)
- ✓ Conflit avec dossier `wo/`

**Résultat attendu :**
```
═══════════════════════════════
   Résumé de la vérification
═══════════════════════════════
Succès:        8
Avertissements: 0
Erreurs:       0

✓ Le système est prêt pour l'installation de WordOps
```

---

## �🚀 Installation WordOps

### Méthode 1: Installation Standard (Recommandée)

```bash
# Retourner dans votre répertoire home (IMPORTANT)
cd ~

# Vérifier qu'il n'y a pas de dossier 'wo'
ls -la | grep " wo"

# Installation via le script officiel
wget -qO wo wordops.net/wssl
sudo bash wo
```

**⚠️ IMPORTANT :**
- Assurez-vous d'être dans votre répertoire home (`cd ~`)
- N'installez JAMAIS depuis le répertoire du projet Git (conflit avec dossier `wo/`)
- Si vous voyez l'erreur "wo: est un dossier", vous êtes dans le mauvais répertoire

**Sortie attendue :**
```
Installing wo dependencies...
Installing WordOps...
WordOps installed successfully
```

### Méthode 2: Installation avec Diagnostic (En cas de problème)

Utiliser les scripts de debug de ce projet :

```bash
# 1. Cloner le projet dans /tmp
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git

# 2. IMPORTANT : Sortir du répertoire du projet pour éviter le conflit avec le dossier 'wo/'
cd ~

# 3. Installer WordOps normalement
wget -qO wo wordops.net/wssl
sudo bash wo

# 4. Si problème de clé GPG, utiliser le script de correction
sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh

# 5. Pour un diagnostic complet (optionnel)
sudo /tmp/wordops-docker-testing/scripts/debian-debug.sh
```

**Note importante :** Le projet contient un dossier `wo/` qui entre en conflit avec le script d'installation. Installez toujours WordOps depuis votre répertoire home (`~`) ou `/tmp`.

### 3. Vérifier l'installation

```bash
# Vérifier la version
wo --version
# Sortie: WordOps v3.22.0

# Vérifier le statut
wo stack status
```

---

## 🌐 Création d'un Site WordPress

### 1. Installer la Stack LEMP

```bash
# Installation complète
sudo wo stack install --nginx --php82 --mysql --redis --fail2ban
```

**Si vous rencontrez l'erreur de clé GPG expirée :**

```bash
# Utiliser le script de correction
sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh

# Puis réessayer
sudo wo stack install --nginx --php82 --mysql --redis
```

### 2. Créer un site WordPress

```bash
# Site WordPress avec cache Redis
sudo wo site create example.com --wp --php82 --redis

# Ou site WordPress complet avec Let's Encrypt SSL
sudo wo site create example.com --wp --php82 --redis --letsencrypt
```

**Note:** Pour tester localement sans nom de domaine :
```bash
sudo wo site create test.local --wp --php82
```

### 3. Ajouter le site à votre fichier hosts (Windows)

**Sur Windows (éditeur en admin) :**
```
C:\Windows\System32\drivers\etc\hosts
```

Ajouter :
```
127.0.0.1    test.local
```

**Accès :**
- VM en NAT : `http://localhost:8080` (si port forwarding configuré)
- VM en Bridge : `http://192.168.1.100` (IP de la VM)
- Avec nom de domaine : `http://test.local`

### 4. Obtenir les identifiants WordPress

```bash
# Afficher les informations du site
sudo wo site info example.com
```

---

## 🔧 Dépannage

### Problème: Clé GPG WordOps expirée

**Symptôme :**
```
W: GPG error: http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12 InRelease: 
   The following signatures were invalid: EXPKEYSIG DA4468F6FB898660
```

**Solution :**
```bash
# Supprimer le dépôt problématique
sudo rm -f /etc/apt/sources.list.d/wordops.list

# Nettoyer et mettre à jour
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt update
```

WordOps est installé via PIP, le dépôt APT n'est pas nécessaire.

### Problème: Erreur de locales

**Symptôme :**
```
perl: warning: Setting locale failed.
```

**Solution :**
```bash
# Configurer les locales
echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8
```

### Problème: Services ne démarrent pas

**Vérifier les services :**
```bash
sudo systemctl status nginx
sudo systemctl status php8.2-fpm
sudo systemctl status mysql
sudo systemctl status redis-server
```

**Redémarrer si nécessaire :**
```bash
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
sudo systemctl restart mysql
```

### Problème: Pas d'accès au site web

**Vérifier le firewall :**
```bash
# Vérifier UFW
sudo ufw status

# Si activé, autoriser HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Vérifier Nginx :**
```bash
# Test de configuration
sudo nginx -t

# Voir les logs d'erreur
sudo tail -f /var/log/nginx/error.log
```

### Problème: Connexion SSH perdue

Si vous avez configuré une IP statique et perdu la connexion :

1. Accéder à la console de la VM (VirtualBox)
2. Se connecter localement
3. Vérifier la configuration réseau :
```bash
ip addr show
cat /etc/network/interfaces
```

### PermissionError: '/root/.gitconfig'

**Erreur complète :**
```
PermissionError: [Errno 13] Permission denied: '/root/.gitconfig'
```

**Cause :** Git n'est pas configuré pour root ou mauvaises permissions.

**Solution complète :**
```bash
# 1. Supprimer l'ancien fichier s'il existe
sudo rm -f /root/.gitconfig

# 2. Reconfigurer Git pour root
sudo git config --global user.name "Votre Nom"
sudo git config --global user.email "votre@email.com"

# 3. Vérifier la configuration
sudo git config --global --list
sudo ls -la /root/.gitconfig
sudo cat /root/.gitconfig

# 4. Tester WordOps
wo --version
```

**Validation :**
- Le fichier `/root/.gitconfig` doit exister
- Permissions : `644` (rw-r--r--)
- Propriétaire : `root:root`

### Erreur: "wo: est un dossier"

**Cause :** Vous tentez d'installer depuis un répertoire contenant un dossier `wo/`.

**Solution :**
```bash
cd ~
rm -f wo
wget -qO wo wordops.net/wssl
sudo bash wo
```

**Plus d'aide :** Voir [TROUBLESHOOTING-VM.md](TROUBLESHOOTING-VM.md)

---

## 📊 Scripts de Diagnostic Disponibles

### `check-vm-requirements.sh` ⭐ NOUVEAU
Vérification automatique de tous les prérequis
```bash
sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh
```

Tous les scripts dans `wordops-docker-testing/scripts/` fonctionnent aussi sur VM :

### `debian-debug.sh`
Diagnostic complet du système (200+ lignes de logs)
```bash
sudo ./debian-debug.sh
# Logs dans: /logs/debian-debug-TIMESTAMP.log
```

### `system-info.sh`
Informations système détaillées
```bash
sudo ./system-info.sh
```

### `fix-wordops-repo.sh`
Correction automatique du dépôt GPG
```bash
sudo ./fix-wordops-repo.sh
```

### `create-wordpress-debian.sh`
Installation LEMP + WordPress automatisée
```bash
sudo ./create-wordpress-debian.sh mon-site.local
```

---

## 🎓 Bonnes Pratiques VM

### Snapshots

Créer des snapshots avant modifications importantes :

**VirtualBox :**
- VM → Machine → Take Snapshot
- Nom: "Debian12-Fresh-Install" ou "After-WordOps-Install"

### Sauvegarde

```bash
# Sauvegarder la base de données
sudo mysqldump --all-databases > /backup/all-dbs.sql

# Sauvegarder les sites
sudo tar -czf /backup/www-sites.tar.gz /var/www/

# Sauvegarder les configurations
sudo tar -czf /backup/configs.tar.gz /etc/nginx /etc/php /etc/mysql
```

### Mise à jour régulière

```bash
# Système
sudo apt update && sudo apt upgrade -y

# WordOps
sudo wo update

# Stack
sudo wo stack upgrade --all
```

### Monitoring

```bash
# Installer Netdata (optionnel)
sudo wo stack install --netdata

# Accès: http://your-vm-ip:19999
```

---

## 🔗 Ressources

- **[TROUBLESHOOTING-VM.md](TROUBLESHOOTING-VM.md)** 🔧 Guide complet de dépannage
- [Documentation WordOps](https://wordops.net/)
- [Debian 12 Documentation](https://www.debian.org/releases/bookworm/)
- [Scripts de debug](https://github.com/sebafrench/wordops-docker-testing)
- [LOGS-DETAILLES.md](LOGS-DETAILLES.md) - Guide complet de debugging

---

## 📝 Notes

### Différences Docker vs VM

| Aspect | Docker | VM |
|--------|--------|-----|
| Isolation | Container | Système complet |
| Démarrage | < 5 secondes | 30-60 secondes |
| Ressources | Léger (partage kernel) | Plus lourd (kernel dédié) |
| Utilisation | Tests, dev | Production-like |
| Snapshots | Images Docker | Snapshots VM |
| Réseau | Port mapping simple | Configuration réseau complète |

### Quand utiliser une VM ?

- ✅ Environnement de **production similaire**
- ✅ Tests de **mise à jour système**
- ✅ **Formation** et apprentissage
- ✅ Besoin de **GUI** (interface graphique)
- ✅ Tests de **performance** réalistes

### Quand utiliser Docker ?

- ✅ **Tests rapides** et reproductibles
- ✅ **CI/CD** automatisé
- ✅ **Développement** multi-environnement
- ✅ **Debugging** isolé
- ✅ Ressources limitées

---

**Dernière mise à jour :** 30 décembre 2025
