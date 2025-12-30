# Guide de Démarrage Rapide - WordOps Docker Testing

## 🚀 Démarrage en 3 Commandes

### Sur Windows (PowerShell/CMD)

```powershell
# 1. Aller dans le répertoire du projet
cd C:\Users\sebastien\Documents\WordOps

# 2. Donner les permissions (via WSL)
wsl chmod +x scripts/*.sh

# 3. Lancer le test
wsl bash scripts/repro.sh ubuntu
```

### Sur Linux/macOS

```bash
# 1. Aller dans le répertoire du projet
cd ~/WordOps  # ou le chemin approprié

# 2. Donner les permissions
chmod +x scripts/*.sh

# 3. Lancer le test
./scripts/repro.sh ubuntu
```

## 📊 Voir les Résultats

Les logs sont dans le répertoire `logs/` :

```bash
# Windows
dir logs\

# Linux/macOS/WSL
ls -lh logs/

# Voir le log principal
cat logs/wo-install-ubuntu.log
```

## 🔧 Modes Disponibles

```bash
# Test automatique Ubuntu
./scripts/repro.sh ubuntu

# Test automatique Debian
./scripts/repro.sh debian

# Les deux distributions
./scripts/repro.sh both

# Mode interactif (debug manuel)
./scripts/repro.sh ubuntu --interactive

# Rebuild complet (efface le cache)
./scripts/repro.sh ubuntu --rebuild
```

## 🐛 En Cas de Problème

### Docker n'est pas installé

- **Windows** : Installer [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Linux** : `curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh`
- **macOS** : Installer [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Permission denied sur les scripts

```bash
# Windows (WSL)
wsl chmod +x scripts/*.sh

# Linux/macOS
chmod +x scripts/*.sh
```

### Les containers ne démarrent pas

```bash
# Vérifier que Docker fonctionne
docker ps

# Nettoyer et relancer
docker compose down -v
./scripts/repro.sh ubuntu --rebuild
```

## 📖 Documentation Complète

Pour plus de détails, voir [README-TESTING.md](README-TESTING.md)

## 🆘 Support

En cas de problème, créer une archive avec les logs :

```bash
# Windows PowerShell
Compress-Archive -Path logs -DestinationPath wordops-logs.zip

# Linux/macOS
tar -czf wordops-logs.tar.gz logs/
```

Puis partager cette archive avec les détails du problème.
