# WordOps Installation Testing & Debugging Environment

![Docker](https://img.shields.io/badge/docker-%232496ED.svg?style=flat&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-12-A81D33?logo=debian&logoColor=white)

> **Environnement Docker complet pour reproduire, tester et déboguer l'installation de WordOps de manière isolée.**

---

## 📋 Table des Matières

- [Vue d'ensemble](#-vue-densemble)
- [Prérequis](#-prérequis)
- [Structure du Projet](#-structure-du-projet)
- [Quick Start](#-quick-start)
- [Utilisation Détaillée](#-utilisation-détaillée)
- [Modes d'Exécution](#-modes-dexécution)
- [Analyse des Logs](#-analyse-des-logs)
- [Problèmes Courants](#-problèmes-courants)
- [Debug Manuel](#-debug-manuel)
- [Commandes Utiles](#-commandes-utiles)

---

## 🎯 Vue d'ensemble

Cet environnement permet de :

✅ **Reproduire** l'installation de WordOps dans un container isolé  
✅ **Déboguer** les problèmes d'installation (dépendances, GPG, APT)  
✅ **Capturer** tous les logs et diagnostics système  
✅ **Tester** sur Ubuntu 22.04 LTS et Debian 12  
✅ **Investiguer** en mode interactif avec systemd fonctionnel  

### Caractéristiques

- **Isolation complète** : Aucune modification sur la machine hôte
- **Logs persistants** : Tous les logs sauvegardés dans `./logs/`
- **Mode debug** : APT verbeux, traces bash, diagnostics système
- **Systemd fonctionnel** : Services gérés comme sur un système réel
- **Multi-distribution** : Support Ubuntu et Debian en parallèle

---

## 📦 Prérequis

### Systèmes supportés

- **Windows** : Windows 10/11 avec WSL2 + Docker Desktop
- **macOS** : Docker Desktop pour Mac
- **Linux** : Docker Engine + Docker Compose V2

### Logiciels requis

```bash
# Vérifier Docker
docker --version        # Minimum: 20.10+
docker compose version  # Compose V2 (intégré)

# Vérifier les permissions
docker ps              # Doit fonctionner sans sudo
```

### Installation Docker

<details>
<summary>🪟 Windows (WSL2)</summary>

```powershell
# Installer WSL2
wsl --install

# Télécharger et installer Docker Desktop
# https://www.docker.com/products/docker-desktop/

# Vérifier
docker --version
```
</details>

<details>
<summary>🍎 macOS</summary>

```bash
# Installer Docker Desktop
# https://www.docker.com/products/docker-desktop/

# Ou via Homebrew
brew install --cask docker
```
</details>

<details>
<summary>🐧 Linux (Ubuntu/Debian)</summary>

```bash
# Installation Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Vérifier
docker --version
docker compose version
```
</details>

---

## 📁 Structure du Projet

```
WordOps/
├── docker-compose.yml          # Configuration Docker Compose
├── Dockerfile.ubuntu22         # Image Ubuntu 22.04 LTS
├── Dockerfile.debian12         # Image Debian 12 (Bookworm)
├── logs/                       # 📊 Logs persistants (créé auto)
│   ├── wo-install-ubuntu.log
│   ├── wo-install-debian.log
│   ├── system-info-*.log
│   └── wo-debug.log
├── scripts/
│   ├── repro.sh               # 🚀 Script principal de reproduction
│   ├── install-wordops.sh     # Installation WordOps avec debug
│   └── system-info.sh         # Collecte d'informations système
└── README-TESTING.md          # 📖 Ce fichier
```

---

## 🚀 Quick Start

### Test Automatique - Ubuntu 22.04

```bash
# Depuis Windows PowerShell (dans le répertoire WordOps)
cd c:\Users\sebastien\Documents\WordOps

# Donner les permissions d'exécution (WSL/Linux/macOS)
wsl chmod +x scripts/*.sh

# Lancer le test automatique
wsl bash scripts/repro.sh ubuntu
```

### Test Automatique - Debian 12

```bash
wsl bash scripts/repro.sh debian
```

### Test sur les Deux Distributions

```bash
wsl bash scripts/repro.sh both
```

### Résultat Attendu

```
=========================================================================
  WORDOPS INSTALLATION REPRODUCTION SCRIPT
=========================================================================

[INFO] Configuration:
[INFO]   - Target: ubuntu
[INFO]   - Rebuild: 0
[INFO]   - Interactive: 0
[INFO]   - Logs dir: /mnt/c/Users/sebastien/Documents/WordOps/logs

[STEP] Checking Docker installation
[OK] Docker is installed and running
[OK] Docker Compose is available

[STEP] Setting up logs directory
[OK] Logs directory ready: ./logs

[STEP] Starting container
[OK] Container started

[STEP] Running WordOps installation
...
```

---

## 🎮 Utilisation Détaillée

### Script Principal : `repro.sh`

```bash
./scripts/repro.sh [TARGET] [OPTIONS]
```

#### Targets

| Target | Description |
|--------|-------------|
| `ubuntu` | Test sur Ubuntu 22.04 uniquement (défaut) |
| `debian` | Test sur Debian 12 uniquement |
| `both` | Test sur Ubuntu ET Debian séquentiellement |

#### Options

| Option | Description |
|--------|-------------|
| `--rebuild`, `-r` | Rebuild les images Docker (efface le cache) |
| `--interactive`, `-i` | Lance un shell bash interactif |
| `--help`, `-h` | Affiche l'aide |

#### Exemples

```bash
# Test standard Ubuntu
./scripts/repro.sh ubuntu

# Test avec rebuild complet
./scripts/repro.sh ubuntu --rebuild

# Mode interactif pour debug manuel
./scripts/repro.sh ubuntu --interactive

# Test sur Debian avec rebuild
./scripts/repro.sh debian -r

# Test complet sur les deux distributions
./scripts/repro.sh both
```

---

## 🔧 Modes d'Exécution

### 1. Mode Automatique (Recommandé)

Installation complète avec capture de logs :

```bash
./scripts/repro.sh ubuntu
```

**Ce qui se passe :**
1. Build de l'image Docker Ubuntu 22.04
2. Démarrage du container avec systemd
3. Collecte des informations système (pré-installation)
4. Tests de connectivité réseau
5. Configuration APT en mode debug
6. Installation de WordOps avec logs détaillés
7. Collecte des informations système (post-installation)
8. Analyse des erreurs éventuelles

**Logs générés :**
- `wo-install-ubuntu.log` : Log principal d'installation
- `wo-debug.log` : Logs de debug détaillés
- `wo-apt-debug.log` : Logs APT verbeux
- `system-info-pre-install.log` : État système avant installation
- `system-info-post-install.log` : État système après installation

### 2. Mode Interactif (Debug Manuel)

Pour investiguer manuellement :

```bash
./scripts/repro.sh ubuntu --interactive
```

**Vous obtenez un shell dans le container :**

```bash
root@wordops-ubuntu22:~# 

# Commandes disponibles :
/usr/local/bin/install-wordops.sh     # Installer WordOps
/usr/local/bin/system-info.sh         # Collecter infos système
wo --version                          # Vérifier WordOps (après install)

# Tests manuels
apt-get update                        # Tester APT
curl -I https://wops.cc              # Tester connectivité
systemctl status                      # Vérifier systemd
```

### 3. Mode Docker Compose Direct

Pour un contrôle total :

```bash
# Ubuntu
docker compose --profile ubuntu up --build

# Dans un autre terminal
docker exec -it wordops-ubuntu22-test bash

# Debian
docker compose --profile debian up --build
docker exec -it wordops-debian12-test bash
```

---

## 📊 Analyse des Logs

### Localisation des Logs

Tous les logs sont dans le répertoire `./logs/` sur votre machine hôte :

```bash
# Windows
dir C:\Users\sebastien\Documents\WordOps\logs

# Linux/macOS/WSL
ls -lh ./logs/
```

### Fichiers de Logs Principaux

#### 1. `wo-install-ubuntu.log` / `wo-install-debian.log`
**Log principal d'installation WordOps**

```bash
# Voir les erreurs
cat logs/wo-install-ubuntu.log | grep -i error

# Voir les warnings
cat logs/wo-install-ubuntu.log | grep -i warning

# Voir les problèmes GPG
cat logs/wo-install-ubuntu.log | grep -i "NO_PUBKEY"

# Voir les problèmes de dépendances
cat logs/wo-install-ubuntu.log | grep -i "unmet dependencies"
```

#### 2. `wo-debug.log`
**Logs de debug détaillés (bash set -x)**

```bash
# Voir la séquence complète des commandes
cat logs/wo-debug.log

# Filtrer les commandes apt
cat logs/wo-debug.log | grep "apt-get"
```

#### 3. `wo-apt-debug.log`
**Logs APT verbeux avec debug HTTP/GPG**

```bash
# Voir les problèmes de téléchargement
cat logs/wo-apt-debug.log | grep -i "failed"

# Voir les problèmes de signature
cat logs/wo-apt-debug.log | grep -i "GPG"

# Voir les URLs contactées
cat logs/wo-apt-debug.log | grep "GET"
```

#### 4. `system-info-pre-install.log`
**État complet du système AVANT installation**

Contient :
- Distribution et kernel
- Packages installés
- Configuration réseau
- Sources APT
- Clés GPG
- Variables d'environnement

#### 5. `system-info-post-install.log`
**État complet du système APRÈS installation**

Permet de comparer avec l'état pré-installation.

### Commandes d'Analyse

```bash
# Comparer pré/post installation
diff logs/system-info-pre-install.log logs/system-info-post-install.log

# Rechercher toutes les erreurs
grep -ri error logs/

# Rechercher les problèmes spécifiques
grep -ri "NO_PUBKEY\|unmet dependencies\|404\|failed to fetch" logs/

# Voir le résumé d'installation
tail -100 logs/wo-install-ubuntu.log
```

---

## ⚠️ Problèmes Courants

### 1. Erreur : NO_PUBKEY

**Symptôme :**
```
W: GPG error: ... NO_PUBKEY XXXXXXXXXXXXXXXX
```

**Diagnostic :**
```bash
# Vérifier les clés GPG manquantes
cat logs/wo-install-ubuntu.log | grep NO_PUBKEY
```

**Solution :**
Les clés GPG doivent être téléchargées. Vérifier dans les logs si :
- La connexion aux serveurs de clés fonctionne
- Les URLs sont correctes
- Les keyrings sont créés dans `/usr/share/keyrings/`

### 2. Erreur : Unmet Dependencies

**Symptôme :**
```
The following packages have unmet dependencies:
 package : Depends: other-package (>= version) but it is not installable
```

**Diagnostic :**
```bash
# Voir les dépendances non satisfaites
cat logs/wo-install-ubuntu.log | grep -A 10 "unmet dependencies"

# Vérifier les sources APT
cat logs/system-info-pre-install.log | grep -A 50 "APT SOURCES"
```

**Solution :**
- Vérifier que tous les dépôts sont configurés
- Vérifier que `apt-get update` a réussi
- Vérifier les versions des packages disponibles

### 3. Erreur : 404 / Repository Not Found

**Symptôme :**
```
Err:1 http://repository.example.com/... 404 Not Found
Failed to fetch http://...
```

**Diagnostic :**
```bash
# Voir les URLs en échec
cat logs/wo-apt-debug.log | grep "404\|Failed to fetch"

# Tester manuellement les repositories
docker exec -it wordops-ubuntu22-test bash
curl -I https://packages.sury.org/php/
curl -I https://download.opensuse.org/repositories/home:/virtubox:/WordOps/
```

**Solution :**
- Vérifier la connectivité réseau du container
- Vérifier que les URLs des dépôts sont correctes
- Vérifier les problèmes DNS

### 4. Erreur : Systemd ne démarre pas

**Symptôme :**
```
System has not been booted with systemd
Failed to connect to bus
```

**Diagnostic :**
```bash
# Vérifier le statut systemd
docker exec wordops-ubuntu22-test systemctl is-system-running

# Vérifier les logs systemd
docker exec wordops-ubuntu22-test journalctl -xe
```

**Solution :**
Le container doit être lancé avec :
- `privileged: true`
- Volume `/sys/fs/cgroup` monté
- CMD: `/lib/systemd/systemd`

### 5. Erreur : DNS Resolution Failed

**Symptôme :**
```
Could not resolve host: example.com
Temporary failure in name resolution
```

**Diagnostic :**
```bash
# Tester DNS dans le container
docker exec wordops-ubuntu22-test bash -c "
  cat /etc/resolv.conf
  nslookup google.com
  ping -c 3 8.8.8.8
"
```

**Solution :**
```bash
# Vérifier la configuration réseau Docker
docker network inspect wordops-test-network

# Relancer Docker daemon (si problème persistant)
# Windows: Redémarrer Docker Desktop
# Linux: sudo systemctl restart docker
```

---

## 🔍 Debug Manuel

### Accéder au Container en Cours

```bash
# Ubuntu
docker exec -it wordops-ubuntu22-test bash

# Debian
docker exec -it wordops-debian12-test bash
```

### Commandes de Diagnostic

#### Vérifier le Système

```bash
# Distribution
cat /etc/os-release
lsb_release -a

# Kernel
uname -a

# Ressources
free -h
df -h
```

#### Vérifier le Réseau

```bash
# DNS
cat /etc/resolv.conf
nslookup google.com

# Connectivité
ping -c 3 8.8.8.8
curl -I https://google.com

# Tester les dépôts WordOps
curl -I https://packages.sury.org/php/
curl -I https://mariadb.org/mariadb_release_signing_key.pgp
```

#### Vérifier APT

```bash
# Sources
cat /etc/apt/sources.list
ls -la /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/*

# Clés GPG
ls -la /etc/apt/keyrings/
ls -la /usr/share/keyrings/
apt-key list  # Deprecated mais utile

# Update
apt-get update -o Debug::Acquire::http=true

# Policy
apt-cache policy python3
apt-cache policy nginx
```

#### Vérifier Systemd

```bash
# Status
systemctl status

# Services en échec
systemctl --failed

# Logs
journalctl -xe
journalctl -u nginx -n 50
```

#### Installation Manuelle de WordOps

```bash
# Télécharger
curl -sL -o /tmp/wo-install.sh https://wops.cc

# Voir le script
head -100 /tmp/wo-install.sh

# Installer
bash /tmp/wo-install.sh --force

# Ou utiliser notre script debug
/usr/local/bin/install-wordops.sh --verbose
```

---

## 📝 Commandes Utiles

### Gestion des Containers

```bash
# Démarrer Ubuntu
docker compose --profile ubuntu up --build -d

# Démarrer Debian
docker compose --profile debian up --build -d

# Voir les containers actifs
docker compose ps

# Voir les logs
docker compose logs -f

# Arrêter
docker compose --profile ubuntu down
docker compose --profile debian down

# Tout supprimer (containers + volumes)
docker compose down -v
```

### Gestion des Images

```bash
# Lister les images
docker images | grep wordops

# Rebuild complet (sans cache)
docker compose --profile ubuntu build --no-cache

# Supprimer les images
docker rmi wordops-test:ubuntu22
docker rmi wordops-test:debian12
```

### Gestion des Logs

```bash
# Voir les logs en temps réel
tail -f logs/wo-install-ubuntu.log

# Nettoyer les anciens logs
rm -rf logs/backup-*

# Archiver les logs
tar -czf wordops-logs-$(date +%Y%m%d).tar.gz logs/
```

### Inspection du Container

```bash
# Informations détaillées
docker inspect wordops-ubuntu22-test

# Processus en cours
docker top wordops-ubuntu22-test

# Statistiques ressources
docker stats wordops-ubuntu22-test

# Variables d'environnement
docker exec wordops-ubuntu22-test env
```

---

## 🛠️ Personnalisation

### Modifier les Dockerfiles

Pour ajouter des packages ou modifier la configuration :

```dockerfile
# Éditer Dockerfile.ubuntu22
# Ajouter après les packages existants :
RUN apt-get install -y \
    your-package-here \
    another-package
```

### Modifier les Scripts

Les scripts sont dans `./scripts/` :

- `repro.sh` : Logique de reproduction
- `install-wordops.sh` : Installation avec debug
- `system-info.sh` : Collecte d'informations

Rendez-les exécutables après modification :

```bash
chmod +x scripts/*.sh
```

### Variables d'Environnement

Modifier dans [docker-compose.yml](docker-compose.yml):

```yaml
environment:
  - WO_DEBUG=1
  - WO_INSTALL_LOG=/logs/custom-log.log
  - CUSTOM_VAR=value
```

---

## 🤝 Contribution

Si vous identifiez un problème ou une amélioration :

1. Documentez le problème avec les logs
2. Proposez une solution dans les scripts
3. Testez sur Ubuntu ET Debian
4. Partagez vos résultats

---

## 📞 Support

### Logs à Fournir

En cas de problème, fournir :

```bash
# Créer une archive avec tous les logs
tar -czf wordops-debug-$(date +%Y%m%d).tar.gz logs/

# Inclure aussi :
docker --version > logs/docker-version.txt
docker compose version >> logs/docker-version.txt
uname -a > logs/host-info.txt  # Sur Linux/macOS/WSL
```

### Informations Utiles

- Système d'exploitation hôte
- Version de Docker
- Distribution testée (Ubuntu/Debian)
- Contenu des logs d'erreur

---

## 📄 Licence

Ce projet de test/debug suit la même licence que WordOps (MIT).

---

## ✅ Checklist de Démarrage Rapide

- [ ] Docker et Docker Compose installés
- [ ] Permissions d'exécution sur les scripts (`chmod +x scripts/*.sh`)
- [ ] Lancement du test : `./scripts/repro.sh ubuntu`
- [ ] Vérification des logs dans `./logs/`
- [ ] En cas d'erreur, consulter la section [Problèmes Courants](#-problèmes-courants)
- [ ] Pour debug manuel, utiliser `--interactive`

---

**Bon debug ! 🚀**
