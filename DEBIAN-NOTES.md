# Notes spécifiques à Debian 12

## Configuration réussie

Le projet WordOps a été adapté pour fonctionner sur Debian 12 (Bookworm).

### Corrections appliquées

#### Problème de locales (résolu)

**Erreur initiale :**
```
*** update-locale: Error: invalid locale settings:  LANG=en_US.UTF-8
```

**Solution :**
Sur Debian 12, il faut configurer `/etc/locale.gen` avant d'utiliser `locale-gen` :

```dockerfile
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime && \
    echo "Europe/Paris" > /etc/timezone
```

### Test réussi

✅ **Container démarré** : `wordops-debian12-test` (healthy)  
✅ **WordOps installé** : Version 3.22.0  
✅ **Système** : Debian GNU/Linux 12 (bookworm)  
✅ **Logs générés** : ~620 KB de logs de debug

### Comparaison Ubuntu vs Debian

| Aspect | Ubuntu 22.04 | Debian 12 |
|--------|-------------|-----------|
| Base image | `ubuntu:22.04` | `debian:12` |
| Configuration locales | Fonction directe `locale-gen` | Configuration via `/etc/locale.gen` |
| Systemd | ✅ Fonctionnel | ✅ Fonctionnel |
| WordOps v3.22.0 | ✅ Installé | ✅ Installé |
| Ports exposés | 8022, 8080, 8443, 22222 | 9022, 9080, 9443, 22223 |

### Utilisation

**Démarrer le container Debian 12 :**
```powershell
.\scripts\repro.ps1 debian
```

**Accéder au container :**
```powershell
docker exec -it wordops-debian12-test bash
```

**Vérifier WordOps :**
```bash
wo --version
wo stack status
```

**Arrêter le container :**
```powershell
docker compose --profile debian down
```

### Logs disponibles

Les logs sont dans `logs/` avec le timestamp de test :
- `installation-Debian 12-console.log` : Sortie complète de l'installation
- `system-info-pre-install.log` : État système avant installation
- `system-info-post-install.log` : État système après installation
- `wo-debug.log` : Debug WordOps
- `wo-apt-debug.log` : Debug APT

### Installation sur VM Debian 12

**Guide complet disponible :** [VM-INSTALLATION.md](VM-INSTALLATION.md)

#### ✅ Installation réussie sur VM (30 décembre 2025)

**Configuration testée :**
- 🖥️ VM Debian 12 (IP: 192.168.0.25)
- 💾 RAM: 1.9GB / Disque: 20GB
- 🔧 WordOps v3.22.0
- ⚡ Stack: Nginx + PHP 8.2 + MariaDB 11.4 + Redis
- 🌐 Site WordPress créé: `intranet.local`

**Problèmes rencontrés et solutions :**

1. **Clé GPG expirée du dépôt WordOps**
   ```bash
   # Erreur: EXPKEYSIG DA4468F6FB898660
   # Solution: Désactiver temporairement la vérification GPG
   sudo bash -c 'echo "deb [trusted=yes] http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12/ /" > /etc/apt/sources.list.d/wordops.list'
   sudo apt-get update
   ```

2. **Erreur Git safe.directory**
   ```bash
   # Erreur: fatal: propriétaire douteux détecté dans le dépôt à '/etc/redis'
   # Solution: Autoriser tous les répertoires
   sudo bash -c 'cat > /root/.gitconfig << EOF
[user]
	name = WordOps User
	email = wordops@localhost
[safe]
	directory = *
EOF'
   ```

3. **Email non configuré**
   ```bash
   # Erreur: EMail not Valid in config
   # Solution: Configurer l'email dans wo.conf
   sudo sed -i '/^email =$/c\email = admin@intranet.local' /etc/wo/wo.conf
   ```

**Installation complète :**

Pour installer WordOps directement sur une VM Debian 12 (sans Docker) :

1. **Créer une VM** avec Debian 12 (VirtualBox, VMware, Hyper-V)
   - RAM : 2 GB minimum
   - Disque : 20 GB
   - Réseau : Bridge ou NAT avec port forwarding

2. **Installer Debian 12** avec serveur SSH

3. **Configurer Git** (obligatoire) :
   ```bash
   sudo git config --global user.name "Votre Nom"
   sudo git config --global user.email "votre@email.com"
   ```
   
   **⚠️ IMPORTANT :** WordOps s'exécute avec `sudo` (en tant que root), donc Git doit être configuré pour root avec `sudo git config`.

4. **Vérifier les prérequis** (recommandé) :
   ```bash
   # Télécharger et exécuter le script de vérification
   cd /tmp
   git clone https://github.com/sebafrench/wordops-docker-testing.git
   sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh
   ```

5. **Installer WordOps** :
   ```bash
   # Depuis votre répertoire home (PAS depuis le projet Git)
   cd ~
   wget -qO wo wordops.net/wssl
   sudo bash wo
   ```

6. **En cas de problème de clé GPG** (erreur EXPKEYSIG) :
   ```bash
   # Cloner le projet dans /tmp
   cd /tmp
   git clone https://github.com/sebafrench/wordops-docker-testing.git
   
   # Utiliser le script de correction
   sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh
   ```
   
   **⚠️ Note** : N'installez PAS WordOps depuis le répertoire du projet cloné (conflit avec le dossier `wo/`)

7. **Créer un site WordPress** :
   ```bash
   sudo wo stack install --nginx --php82 --mysql --redis
   sudo wo site create test.local --wp --php82 --redis
   ```

### Dépannage VM

**Guide complet disponible :** [TROUBLESHOOTING-VM.md](TROUBLESHOOTING-VM.md)

#### Erreur: PermissionError: '/root/.gitconfig'

**Cause :** Git n'est pas configuré pour root ou mauvaises permissions.

**Solution :**
```bash
# Supprimer et recréer la configuration
sudo rm -f /root/.gitconfig
sudo git config --global user.name "Votre Nom"
sudo git config --global user.email "votre@email.com"

# Vérifier
sudo ls -la /root/.gitconfig
sudo cat /root/.gitconfig

# Tester WordOps
wo --version
```

#### Erreur: "wo: est un dossier"

**Cause :** Installation depuis un répertoire contenant un dossier `wo/`.

**Solution :**
```bash
cd ~
rm -f wo
wget -qO wo wordops.net/wssl
sudo bash wo
```

#### Vérification automatique des prérequis

```bash
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git
sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh
```

Ce script vérifie :
- ✓ Privilèges root
- ✓ Debian 12
- ✓ **Configuration Git pour root**
- ✓ Permissions `/root/.gitconfig`
- ✓ Connexion Internet
- ✓ Espace disque
- ✓ RAM
- ✓ Conflit avec dossier `wo/`

### Tests réalisés

✅ **Stack complète installée** (`wo stack install --nginx --php82 --mysql --redis`)
✅ **Site WordPress créé** (`wo site create intranet.local --wpfc --php82`)
✅ **Services fonctionnels** : Nginx, PHP 8.2-FPM, MariaDB 11.4
✅ **Cache activé** : FastCGI Cache (wpfc) + nginx-helper
✅ **Installation validée sur VM Debian 12**

### Résultats site créé

```
URL: http://intranet.local
Admin: WordOps User
Password: A4kv9sQCjLedJr8NKzaTuYw3
DB_NAME: intranet_local_M6x3ugva
DB_USER: intranetloca8aLi
DB_PASS: G1TNMfw8CV3ODLvQA0IbsJPt
```

### Prochaines étapes

1. ✅ ~~Tester l'installation de la stack complète~~ → **Terminé**
2. ✅ ~~Créer un site de test sur Debian~~ → **Terminé**
3. Comparer les performances Nginx entre Ubuntu et Debian
4. Tester les mises à jour WordOps
5. ✅ ~~Valider l'installation sur VM~~ → **Terminé**
6. Tester SSL/HTTPS avec Let's Encrypt
7. Tester la création de sites avec différentes options (--wpsubdir, --wpsubdomain, etc.)

---
*Dernière mise à jour : 30 décembre 2025 - Installation VM validée*
