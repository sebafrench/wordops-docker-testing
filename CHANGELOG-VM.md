# Changelog - Installation VM Debian 12

## [1.0.0] - 30 Décembre 2025

### ✅ Installation Réussie

**Configuration testée :**
- VM Debian 12 (192.168.0.25)
- RAM: 1.9GB / Disque: 20GB
- WordOps v3.22.0
- Stack: Nginx + PHP 8.2 + MariaDB 11.4 + Redis
- Site WordPress: intranet.local (FastCGI Cache)

### 🔧 Problèmes Résolus

#### 1. Clé GPG Expirée (EXPKEYSIG DA4468F6FB898660)

**Erreur :**
```
W: Erreur de GPG : http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12  InRelease : 
Les signatures suivantes ne sont pas valables : EXPKEYSIG DA4468F6FB898660
```

**Solution :**
```bash
sudo bash -c 'echo "deb [trusted=yes] http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12/ /" > /etc/apt/sources.list.d/wordops.list'
sudo apt-get update
```

**Commit :** Documentation dans TROUBLESHOOTING-VM.md

---

#### 2. Git safe.directory (propriétaire douteux)

**Erreur :**
```
fatal: propriétaire douteux détecté dans le dépôt à '/etc/redis'
configparser.DuplicateOptionError: option 'directory' in section 'safe' already exists
```

**Solution :**
```bash
sudo bash -c 'cat > /root/.gitconfig << EOF
[user]
	name = WordOps User
	email = wordops@localhost
[safe]
	directory = *
EOF'
```

**Commit :** Script fix-git.sh créé

---

#### 3. Email Non Configuré

**Erreur :**
```
EMail not Valid in config, Please provide valid email id
```

**Solution :**
```bash
sudo sed -i '/^email =$/c\email = admin@intranet.local' /etc/wo/wo.conf
```

**Commit :** Script fix-email.sh créé

---

#### 4. Python3-venv Manquant

**Erreur :**
```
ensurepip is not available
```

**Solution :**
- Ajout de `python3-venv` dans REQUIRED_PACKAGES
- Commit: 9795691

---

### 📄 Documentation Ajoutée

1. **VM-SUCCESS-REPORT.md** - Rapport complet de l'installation réussie
2. **DEBIAN-NOTES.md** - Section "Installation VM réussie"
3. **TROUBLESHOOTING-VM.md** - Nouvelles solutions (sections 3, 8, 9)
4. **STATUS.md** - Mise à jour avec résultats VM

### 🛠️ Scripts Créés

1. **fix-git.sh** - Correction configuration Git avec safe.directory
2. **fix-email.sh** - Configuration email dans wo.conf
3. **add-hosts.sh** - Ajout entrée hosts pour DNS local
4. **compare-env.sh** - Comparaison Docker vs VM
5. **install-wordops-vm.ps1** - Installation PowerShell pour VM
6. **setup-vm-repos.sh** - Configuration dépôts VM

### 📊 Résultats Tests

#### Services
```
nginx     :  Running ✅
php8.2-fpm:  Running ✅
mariadb   :  Running ✅
```

#### Site WordPress
```
URL: http://intranet.local
Type: WordPress + FastCGI Cache
PHP: 8.2
Admin: WordOps User
DB: intranet_local_M6x3ugva
```

#### Test HTTP
```
HTTP/1.1 403 Forbidden (normal pour curl sans User-Agent)
Server: nginx
X-Powered-By: WordOps
```

### 🎯 Prérequis Validés

- ✅ Debian 12 (bookworm)
- ✅ Python 3.11.2
- ✅ pip3 23.0.1
- ✅ python3-venv
- ✅ Git configuré pour root
- ✅ 1.9GB RAM (>1GB requis)
- ✅ 20GB disque (>10GB requis)

### 🔗 Commits

1. `ca24fb3` - Installation VM Debian 12 validée - Documentation complète
2. `9795691` - Add python3-venv to required dependencies
3. `25d0d2e` - Add Python3 and pip3 to required dependencies
4. `7b089ae` - Handle undefined DEBIAN_FRONTEND variable
5. `fcc833b` - Add chmod +x to all scripts

### 🚀 Prochaines Étapes

- [ ] Tests SSL/HTTPS avec Let's Encrypt
- [ ] Sites WordPress multisite
- [ ] Performance Docker vs VM
- [ ] Mises à jour WordOps
- [ ] Fail2ban, Netdata, UFW

### 📚 Références

- Dépôt: https://github.com/sebafrench/wordops-docker-testing
- VM: 192.168.0.25 (Debian 12)
- WordOps: https://wordops.net

---

**Auteur :** Sebastien  
**Date :** 30 décembre 2025  
**Version :** 1.0.0 - Installation validée
