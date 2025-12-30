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

### Prochaines étapes

1. Tester l'installation de la stack complète (`wo stack install`)
2. Créer un site de test sur Debian
3. Comparer les performances Nginx entre Ubuntu et Debian
4. Tester les mises à jour WordOps
5. Valider l'installation sur VM (voir [VM-INSTALLATION.md](VM-INSTALLATION.md))

---
*Dernière mise à jour : 30 décembre 2025*
