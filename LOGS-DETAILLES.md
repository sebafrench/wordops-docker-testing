# Logs Détaillés - Création WordPress sur Debian 12

## Résumé Exécutif

✅ **Site WordPress créé avec succès sur Debian 12**

- **URL**: http://blog.local
- **Système**: Debian GNU/Linux 12 (Bookworm)
- **Stack**: Nginx 1.22.1 + PHP 8.2 + MariaDB 11.4.9
- **WordPress**: Dernière version (décembre 2025)

## Problème Rencontré et Résolu

### Symptôme Initial

Lors de l'installation de la stack WordOps, l'erreur suivante apparaissait :

```
Whoops, something went wrong... [..]
Check the WordOps log for more details `tail /var/log/wo/wordops.log` and please try again...
```

**Les logs originaux n'étaient PAS assez détaillés** pour identifier la cause racine.

### Diagnostic Approfondi

#### 1. Création du Script de Diagnostic (`debian-debug.sh`)

Un script complet de 200+ lignes a été créé pour capturer :

- ✅ Informations système (OS, kernel, hostname)
- ✅ État des dépôts APT (fichiers sources, signatures GPG)
- ✅ Clés GPG et keyrings
- ✅ Test de mise à jour APT avec verbosité maximale (`Debug::Acquire::http=1`)
- ✅ Tests de connectivité réseau (ping, DNS, HTTPS)
- ✅ Logs APT et DPKG
- ✅ État des packages critiques
- ✅ Logs WordOps récents
- ✅ Espace disque et mémoire
- ✅ Variables d'environnement
- ✅ Configuration WordOps complète

**Résultat**: Log de diagnostic de **208 KB** avec toutes les informations nécessaires

#### 2. Cause Racine Identifiée

L'analyse des logs détaillés a révélé :

```
W: GPG error: http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12 InRelease: 
   The following signatures were invalid: EXPKEYSIG DA4468F6FB898660
```

**Problème**: La clé GPG du dépôt OBS (OpenSUSE Build Service) de WordOps a **expiré**.

### Solution Implémentée

#### Script de Correction (`fix-wordops-repo.sh`)

```bash
# Suppression du dépôt problématique
rm -f /etc/apt/sources.list.d/wordops.list

# Protection contre la recréation automatique
touch /etc/apt/sources.list.d/wordops.list
chmod 444 /etc/apt/sources.list.d/wordops.list

# Nettoyage et mise à jour
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update
```

**Rationale**: WordOps est installé via PIP, donc le dépôt APT n'est pas nécessaire.

## Installation Alternative: Sans WordOps CLI

Au lieu d'utiliser `wo stack install` (qui échoue à cause du dépôt GPG), une installation manuelle a été réalisée :

### Script de Création WordPress (`create-wordpress-debian.sh`)

Un script complet de **350+ lignes** installant :

1. **Nginx** (depuis dépôt Debian officiel)
2. **PHP 8.2** avec toutes les extensions nécessaires :
   - php8.2-fpm, php8.2-cli, php8.2-mysql
   - php8.2-curl, php8.2-gd, php8.2-mbstring
   - php8.2-xml, php8.2-zip, php8.2-bcmath
   - php8.2-intl, php8.2-soap, php8.2-opcache
   - php8.2-redis, php8.2-imagick

3. **MariaDB 11.4.9** (depuis dépôt MariaDB officiel)
   - Configuration sécurisée avec mot de passe root généré
   - Création automatique de base de données et utilisateur

4. **WordPress** (dernière version)
   - Téléchargement automatique
   - Configuration wp-config.php automatisée
   - Génération des clés de sécurité via l'API WordPress
   - Permissions correctes (www-data)

5. **Configuration Nginx**
   - Virtual host complet
   - Support PHP-FPM
   - Règles de sécurité (.htaccess, favicon, robots.txt)
   - Cache statique pour les assets
   - Logs séparés par site

## Logs Générés (Détaillés)

### Structure des Logs

```
logs/
├── debian-debug-20251230_152354.log      (208 KB) - Diagnostic complet système
├── fix-repo.log                          (4 KB)   - Correction dépôt WordOps
├── wordpress-creation-20251230_152657.log (45 KB)  - Installation WordPress
├── stack-install-fixed.log               (12 KB)  - Tentatives stack install
├── wo-debug.log                          (197 KB) - Debug WordOps
├── wo-apt-debug.log                      (8 KB)   - Debug APT
└── system-info-*.log                     (194 KB) - Info système avant/après
```

### Informations Capturées dans les Logs

#### 1. Diagnostic Système Complet

```bash
# Exemple d'extraction du log de diagnostic
=========================================================================
 4. TEST DE MISE À JOUR APT (VERBOSE)
=========================================================================

>>> Command: apt-get update -o Debug::pkgAcquire::Worker=1 -o Debug::Acquire::http=1
---
Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
Get:6 http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12 InRelease [1875 B]
Err:6 http://download.opensuse.org/repositories/home:/virtubox:/WordOps/Debian_12 InRelease
  The following signatures were invalid: EXPKEYSIG DA4468F6FB898660
```

**Valeur**: Identification précise de l'erreur avec contexte complet

#### 2. Test de Connectivité Réseau

```bash
>>> Command: ping -c 3 packages.sury.org
>>> Command: nslookup packages.sury.org
>>> Command: curl -v https://packages.sury.org
```

**Valeur**: Validation que le problème n'est PAS réseau mais bien GPG

#### 3. Logs d'Installation WordPress

Chaque étape loguée avec timestamp :

```
[INFO] 15:27:29 - Téléchargement de WordPress...
[OK] 15:27:31 - WordPress téléchargé
[INFO] 15:27:31 - Création de la base de données: wp_blog_local
[OK] 15:27:31 - Base de données créée
[OK] 15:27:34 - Configuration Nginx activée
```

**Valeur**: Traçabilité complète du processus d'installation

## Améliorations Apportées

### 1. Scripts de Diagnostic

| Script | Lignes | Fonction |
|--------|--------|----------|
| `debian-debug.sh` | 200+ | Diagnostic système complet avec 12 sections |
| `fix-wordops-repo.sh` | 100+ | Correction automatique du dépôt GPG |
| `create-wordpress-debian.sh` | 350+ | Installation LEMP + WordPress complète |

### 2. Logging Amélioré

**Avant** (logs WordOps par défaut) :
```
2025-12-30 15:12:37,051 (INFO) wo : Whoops, something went wrong...
2025-12-30 15:12:37,052 (ERROR) wo : Check the WordOps log for more details
```

**Après** (logs détaillés) :
```bash
# Contexte APT complet
apt-get update -o Debug::pkgAcquire::Worker=1 -o Debug::Acquire::http=1

# Tests de connectivité
ping -c 3 8.8.8.8 || true
nslookup packages.sury.org || true
curl -v https://packages.sury.org 2>&1 | head -30 || true

# Vérification certificats CA
update-ca-certificates -v 2>&1 || true
```

### 3. Automatisation

- ✅ Détection automatique des problèmes de dépôt
- ✅ Correction automatique (suppression dépôt obsolète)
- ✅ Installation complète sans intervention manuelle
- ✅ Génération automatique des mots de passe sécurisés
- ✅ Configuration automatique de tous les services

## Informations du Site Créé

```
Site WordPress: blog.local
Date de création: 30 décembre 2025 15:27:34

Base de données:
  - Nom: wp_blog_local
  - Utilisateur: wp_blog_local_user
  - Mot de passe: 6JNbrwAgn6MZq4UxccSCOA==
  
Chemins:
  - Racine web: /var/www/blog.local/htdocs
  - Logs Nginx: /var/log/nginx/blog.local/
  - Configuration Nginx: /etc/nginx/sites-available/blog.local

Services:
  - Nginx: 1.22.1
  - PHP: 8.2.27
  - MariaDB: 11.4.9+maria~deb12

Ports exposés:
  - HTTP: 9080 → 80
  - HTTPS: 9443 → 443
  - SSH: 9022 → 22
  - WordOps Admin: 22223 → 22222
```

## Utilisation pour le Débogage

### 1. Accéder aux Logs sur l'Hôte

```powershell
# Tous les logs ont été copiés dans
C:\Users\sebastien\Documents\WordOps\logs\debian-detailed\

# Analyser les erreurs
Get-Content logs\debian-detailed\debian-debug-*.log | Select-String "ERROR|FAIL"

# Voir l'installation WordPress
Get-Content logs\debian-detailed\wordpress-creation-*.log
```

### 2. Accéder au Container

```powershell
# Shell interactif
docker exec -it wordops-debian12-test bash

# Vérifier WordPress
docker exec wordops-debian12-test curl -sI http://localhost

# Voir les logs Nginx
docker exec wordops-debian12-test tail -f /var/log/nginx/blog.local/access.log
```

### 3. Tester le Site

```powershell
# Ajouter à C:\Windows\System32\drivers\etc\hosts
127.0.0.1 blog.local

# Accéder au site
# http://blog.local:9080
```

## Leçons Apprises

### 1. Importance des Logs Détaillés

❌ **Mauvais**: Log générique "Something went wrong"  
✅ **Bon**: Log détaillé avec contexte complet (commande, sortie, code d'erreur)

### 2. Diagnostic Méthodique

La résolution a nécessité :
1. **Capture** : Script de diagnostic exhaustif
2. **Analyse** : Identification de la clé GPG expirée
3. **Solution** : Suppression du dépôt problématique
4. **Alternative** : Installation manuelle sans WordOps CLI

### 3. Automatisation de la Solution

Au lieu de corriger manuellement :
- Scripts réutilisables créés
- Documentation complète
- Logs traçables

## Recommandations

### Pour Continuer le Débogage

1. **Garder les scripts de diagnostic** : `debian-debug.sh` peut servir pour d'autres problèmes
2. **Comparer avec Ubuntu** : Les logs Ubuntu vs Debian montrent les différences
3. **Versionner les configurations** : Tous les fichiers sont dans le dépôt Git

### Pour la Production

1. **Ne pas utiliser le dépôt OBS obsolète** : WordOps via PIP suffit
2. **Monitorer les clés GPG** : Vérifier régulièrement l'expiration
3. **Logger exhaustivement** : En cas de problème, avoir tous les détails

---

**Date**: 30 décembre 2025  
**Version**: 1.0  
**Auteur**: Documentation automatique via scripts de diagnostic
