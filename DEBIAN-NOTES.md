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

### Prochaines étapes

1. Tester l'installation de la stack complète (`wo stack install`)
2. Créer un site de test sur Debian
3. Comparer les performances Nginx entre Ubuntu et Debian
4. Tester les mises à jour WordOps

---
*Dernière mise à jour : 30 décembre 2024*
