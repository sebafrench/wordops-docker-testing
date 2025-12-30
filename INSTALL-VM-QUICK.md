# Installation Rapide WordOps sur VM Debian 12

## 🚀 Commandes à exécuter après git clone

### Étape 1: Cloner le projet (dans /tmp pour éviter les conflits)

```bash
cd /tmp
git clone https://github.com/sebafrench/wordops-docker-testing.git
```

### Étape 2: Configurer Git (OBLIGATOIRE)

```bash
# WordOps nécessite Git configuré
git config --global user.name "Votre Nom"
git config --global user.email "votre@email.com"
```

### Étape 3: Retourner au répertoire home

```bash
cd ~
```

**⚠️ IMPORTANT** : Ne lancez JAMAIS l'installation WordOps depuis le répertoire du projet !  
Le dossier `wo/` du projet entre en conflit avec le script d'installation.

### Étape 4: Installer WordOps

```bash
wget -qO wo wordops.net/wssl
sudo bash wo
```

### Étape 5: Vérifier l'installation

```bash
wo --version
wo stack status
```

---

## 🔧 Si vous avez l'erreur de clé GPG

```bash
# Utiliser le script de correction
sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh

# Puis nettoyer APT
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt update
```

---

## 📦 Installer la stack complète

```bash
sudo wo stack install --nginx --php82 --mysql --redis
```

---

## 🌐 Créer un site WordPress

```bash
# Site local pour tests
sudo wo site create test.local --wp --php82

# Afficher les identifiants
sudo wo site info test.local
```

---

## 📊 Scripts de diagnostic disponibles

Si vous avez des problèmes, utilisez les scripts du projet :

```bash
# Diagnostic système complet
sudo /tmp/wordops-docker-testing/scripts/debian-debug.sh

# Informations système
sudo /tmp/wordops-docker-testing/scripts/system-info.sh

# Créer un site WordPress automatiquement
sudo /tmp/wordops-docker-testing/scripts/create-wordpress-debian.sh monsite.local
```

---

## ❌ Erreurs Courantes

### Erreur : "copy2(...) FileNotFoundError" ou erreur Git

**Cause** : Git n'est pas configuré  
**Solution** :
```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre@email.com"
wo --version
```

### Erreur : "wo: est un dossier"

**Cause** : Vous êtes dans le répertoire `wordops-docker-testing/`  
**Solution** :
```bash
cd ~
wget -qO wo wordops.net/wssl
sudo bash wo
```

### Erreur : "GPG error EXPKEYSIG"

**Solution** :
```bash
sudo /tmp/wordops-docker-testing/scripts/fix-wordops-repo.sh
```

### Erreur : Locales non configurées

**Solution** :
```bash
echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
sudo locale-gen
```

---

## 🎓 Ressources

- **Guide complet** : [VM-INSTALLATION.md](VM-INSTALLATION.md)
- **Logs détaillés** : [LOGS-DETAILLES.md](LOGS-DETAILLES.md)
- **Notes Debian** : [DEBIAN-NOTES.md](DEBIAN-NOTES.md)

---

**Dernière mise à jour** : 30 décembre 2025
