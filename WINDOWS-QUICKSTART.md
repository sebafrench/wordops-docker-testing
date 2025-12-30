# Guide de Démarrage - WordOps Docker Testing (Windows)

## 🚀 Démarrage Rapide sur Windows

### Prérequis
- ✅ Docker Desktop installé et démarré
- ✅ PowerShell (intégré à Windows)

### Installation en 2 Commandes

```powershell
# 1. Aller dans le répertoire du projet
cd C:\Users\sebastien\Documents\WordOps

# 2. Lancer le test
.\scripts\repro.ps1 ubuntu
```

## 📊 Modes d'Utilisation

### Test Automatique

```powershell
# Test Ubuntu 22.04
.\scripts\repro.ps1 ubuntu

# Test Debian 12
.\scripts\repro.ps1 debian

# Test des deux distributions
.\scripts\repro.ps1 both
```

### Mode Interactif (Debug Manuel)

```powershell
# Shell interactif dans le container Ubuntu
.\scripts\repro.ps1 ubuntu -Interactive

# Dans le container, vous pouvez :
# - Installer WordOps : /usr/local/bin/install-wordops.sh
# - Collecter infos : /usr/local/bin/system-info.sh /logs/info.log
# - Tester : wo --version
```

### Rebuild Complet

```powershell
# Rebuild les images (efface le cache)
.\scripts\repro.ps1 ubuntu -Rebuild
```

## 📁 Logs

Tous les logs sont dans le dossier `logs\` :

```powershell
# Voir les logs
dir logs\

# Ouvrir le log principal
notepad logs\wo-install-ubuntu.log

# Rechercher des erreurs
Select-String -Path "logs\*.log" -Pattern "error|fail" -CaseSensitive:$false
```

## 🔧 Commandes Docker Utiles

```powershell
# Vérifier Docker
docker --version
docker ps

# Accéder au container
docker exec -it wordops-ubuntu22-test bash

# Voir les logs du container
docker logs wordops-ubuntu22-test

# Arrêter les containers
docker compose --profile ubuntu down

# Tout nettoyer (containers + volumes)
docker compose down -v
```

## ⚠️ Résolution de Problèmes

### Docker Desktop n'est pas démarré

```powershell
# Vérifier
docker ps

# Si erreur : Démarrer Docker Desktop depuis le menu Windows
```

### Erreur "Cannot connect to Docker daemon"

1. Ouvrir Docker Desktop
2. Attendre qu'il soit complètement démarré (icône verte)
3. Relancer le script

### Ports déjà utilisés

```powershell
# Modifier les ports dans docker-compose.yml si nécessaire
# Ou arrêter les services qui utilisent les ports 8080, 8443
```

### Erreur de permissions WSL

Le script PowerShell (`.ps1`) fonctionne directement sur Windows, pas besoin de WSL !

## 📖 Documentation Complète

- [README-TESTING.md](README-TESTING.md) - Guide complet et détaillé
- [QUICKSTART.md](QUICKSTART.md) - Démarrage rapide multi-plateforme

## 🆘 Aide

```powershell
# Afficher l'aide
.\scripts\repro.ps1 -Help

# Collecter les logs pour support
Compress-Archive -Path logs -DestinationPath wordops-logs.zip
```

## ✅ Checklist

- [ ] Docker Desktop installé et démarré
- [ ] Ouvrir PowerShell dans le dossier WordOps
- [ ] Exécuter : `.\scripts\repro.ps1 ubuntu`
- [ ] Vérifier les logs dans `logs\`

**Bon test ! 🎉**
