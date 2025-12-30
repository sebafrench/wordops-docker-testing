# Guide de dépannage - Installation VM Debian 12

## 🔍 Diagnostic automatique

Avant toute chose, exécutez le script de vérification :

```bash
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git
sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh
```

Ce script vérifie **automatiquement** :
- ✓ Privilèges root
- ✓ Distribution (Debian 12)
- ✓ **Configuration Git**
- ✓ Connexion Internet
- ✓ Résolution DNS
- ✓ Espace disque (>5GB)
- ✓ RAM (>1GB)
- ✓ Conflit avec dossier `wo/`

---

## 🚨 Erreurs courantes et solutions

### 1. PermissionError: Permission denied: '/root/.gitconfig'

**Symptôme :**
```
PermissionError: [Errno 13] Permission denied: '/root/.gitconfig'
```

**Cause :** Git n'est pas configuré pour l'utilisateur root.

**Solution complète :**

```bash
# 1. Supprimer l'ancien fichier s'il existe avec de mauvaises permissions
sudo rm -f /root/.gitconfig

# 2. Configurer Git pour root
sudo git config --global user.name "Votre Nom"
sudo git config --global user.email "votre@email.com"

# 3. Vérifier la configuration
sudo git config --global --list

# 4. Vérifier les permissions du fichier
sudo ls -la /root/.gitconfig
# Devrait afficher: -rw-r--r-- 1 root root ... /root/.gitconfig

# 5. Tester WordOps
wo --version
```

**Validation :**
- Le fichier `/root/.gitconfig` doit exister
- Permissions : `644` (rw-r--r--)
- Propriétaire : `root:root`
- Contenu visible avec : `sudo cat /root/.gitconfig`

---

### 2. "wo: est un dossier" lors de l'installation

**Symptôme :**
```bash
wget -qO wo wordops.net/wssl
sudo bash wo
# Erreur: wo: est un dossier
```

**Cause :** Vous êtes dans un répertoire contenant un dossier `wo/` (ex: répertoire du projet Git).

**Solution :**

```bash
# Retourner dans votre répertoire home
cd ~

# Vérifier qu'il n'y a pas de dossier 'wo'
ls -la | grep " wo"

# Réinstaller WordOps
rm -f wo  # Supprimer le fichier téléchargé précédemment
wget -qO wo wordops.net/wssl
sudo bash wo
```

**Prévention :**
- **NE JAMAIS** installer WordOps depuis le répertoire du projet Git
- Toujours faire `cd ~` avant l'installation

---

### 3. Erreur GPG: EXPKEYSIG DA4468F6FB898660

**Symptôme :**
```
W: GPG error: ... EXPKEYSIG DA4468F6FB898660
```

**Cause :** Clé GPG du dépôt WordOps OBS expirée.

**Solution :**

```bash
# 1. Cloner le projet dans /tmp (PAS dans ~)
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git

# 2. Exécuter le script de correction
sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh

# 3. Nettoyer
rm -rf /tmp/wordops-docker-testing

# 4. Réessayer l'installation WordOps
cd ~
wget -qO wo wordops.net/wssl
sudo bash wo
```

**Note :** WordOps installé via PIP n'a pas besoin du dépôt APT.

---

### 4. Git n'est pas installé

**Symptôme :**
```
bash: git: command not found
```

**Solution :**

```bash
# Installer Git
sudo apt-get update
sudo apt-get install -y git

# Configurer Git pour root
sudo git config --global user.name "Votre Nom"
sudo git config --global user.email "votre@email.com"

# Vérifier
git --version
sudo git config --global --list
```

---

### 5. Connexion Internet / DNS

**Symptôme :**
- `wget` ne peut pas télécharger
- `apt-get update` échoue

**Diagnostic :**

```bash
# Test ping
ping -c 3 8.8.8.8

# Test DNS
ping -c 3 google.com

# Vérifier la configuration réseau
ip addr show
ip route show

# Vérifier DNS
cat /etc/resolv.conf
```

**Solution :**

```bash
# Si DNS ne fonctionne pas, ajouter Google DNS
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
```

---

### 6. Espace disque insuffisant

**Symptôme :**
```
No space left on device
```

**Diagnostic :**

```bash
# Vérifier l'espace disque
df -h

# Trouver les gros fichiers
sudo du -sh /* | sort -hr | head -10
```

**Solution :**

```bash
# Nettoyer le cache APT
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove

# Supprimer les logs anciens
sudo journalctl --vacuum-time=7d
```

---

### 7. RAM insuffisante

**Symptôme :**
- Installation très lente
- Processus killed

**Diagnostic :**

```bash
# Vérifier la RAM
free -h

# Vérifier le swap
swapon --show
```

**Solution :**

```bash
# Créer un fichier swap de 2GB
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Rendre permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 📋 Checklist avant installation

Avant d'installer WordOps, vérifiez :

- [ ] Debian 12 (Bookworm) installé
- [ ] Accès root (sudo)
- [ ] Git installé : `git --version`
- [ ] Git configuré pour root : `sudo git config --global --list`
- [ ] Fichier `/root/.gitconfig` existe avec bonnes permissions
- [ ] Connexion Internet : `ping -c 3 google.com`
- [ ] Espace disque >10GB : `df -h /`
- [ ] RAM >1GB : `free -h`
- [ ] Vous êtes dans `~` (PAS dans un répertoire avec `wo/`)
- [ ] Pas de dépôt WordOps OBS obsolète

---

## 🔧 Commandes de diagnostic utiles

```bash
# Informations système
uname -a
lsb_release -a
cat /etc/os-release

# Configuration réseau
ip addr show
ip route show
cat /etc/resolv.conf

# Ressources système
free -h
df -h
lscpu | grep "CPU(s)"

# Configuration Git
sudo git config --global --list
sudo ls -la /root/.gitconfig
sudo cat /root/.gitconfig

# WordOps
wo --version
wo stack status
wo site list

# Services
systemctl status nginx
systemctl status php8.2-fpm
systemctl status mysql
systemctl status redis-server

# Logs
sudo tail -100 /var/log/wo/wordops.log
sudo journalctl -u nginx -n 50
```

---

## 📞 Support

Si le problème persiste après avoir suivi ce guide :

1. **Exécutez le diagnostic complet :**
   ```bash
   sudo bash /tmp/wordops-docker-testing/scripts/check-vm-requirements.sh > ~/diagnostic.txt 2>&1
   ```

2. **Collectez les logs :**
   ```bash
   sudo tar -czf ~/wordops-debug.tar.gz \
       /var/log/wo/ \
       /root/.gitconfig \
       /etc/os-release \
       ~/diagnostic.txt
   ```

3. **Créez une issue GitHub :** https://github.com/sebafrench/wordops-docker-testing/issues

---

## 📚 Documentation complémentaire

- [VM-INSTALLATION.md](VM-INSTALLATION.md) : Guide complet d'installation
- [INSTALL-VM-QUICK.md](INSTALL-VM-QUICK.md) : Guide rapide
- [DEBIAN-NOTES.md](DEBIAN-NOTES.md) : Notes spécifiques Debian 12
- [README-TESTING.md](README-TESTING.md) : Tests et validation

---

*Dernière mise à jour : 30 décembre 2025*
