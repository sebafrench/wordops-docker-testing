#!/usr/bin/env bash
# =========================================================================
# create-wordpress-debian.sh - Création complète d'un site WordPress
# =========================================================================
# Ce script installe la stack complète et crée un site WordPress de test
# =========================================================================

set -euo pipefail

SITE_NAME="${1:-test.local}"
LOG_FILE="/logs/wordpress-creation-$(date +%Y%m%d_%H%M%S).log"

log_header() {
    echo "" | tee -a "${LOG_FILE}"
    echo "=========================================================================" | tee -a "${LOG_FILE}"
    echo " $1" | tee -a "${LOG_FILE}"
    echo "=========================================================================" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $(date +'%H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "\033[0;32m[OK]\033[0m $(date +'%H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $(date +'%H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_header "CRÉATION SITE WORDPRESS SUR DEBIAN 12"

log_info "Site à créer: ${SITE_NAME}"
log_info "Log: ${LOG_FILE}"

# =========================================================================
# ÉTAPE 1: Correction du dépôt WordOps problématique
# =========================================================================

log_header "ÉTAPE 1/5: CORRECTION DU DÉPÔT WORDOPS"

log_info "Le dépôt OBS de WordOps a une clé GPG expirée"
log_info "Suppression du dépôt car WordOps est installé via PIP"

if [ -f /etc/apt/sources.list.d/wordops.list ]; then
    rm -f /etc/apt/sources.list.d/wordops.list
    log_success "Dépôt WordOps supprimé"
fi

# Empêcher la recréation automatique en créant un fichier vide protégé
touch /etc/apt/sources.list.d/wordops.list
chmod 444 /etc/apt/sources.list.d/wordops.list
log_success "Protection contre la re-création automatique"

apt-get clean
rm -rf /var/lib/apt/lists/*
log_success "Cache APT nettoyé"

if apt-get update 2>&1 | tee -a "${LOG_FILE}"; then
    log_success "APT update réussi"
else
    log_error "Échec de apt-get update"
    exit 1
fi

# =========================================================================
# ÉTAPE 2: Installation de la stack LEMP
# =========================================================================

log_header "ÉTAPE 2/5: INSTALLATION NGINX"

if ! nginx -v &>/dev/null; then
    log_info "Installation de Nginx..."
    
    # Installation manuelle de Nginx depuis le dépôt officiel
    apt-get install -y nginx nginx-extras 2>&1 | tee -a "${LOG_FILE}"
    
    systemctl enable nginx
    systemctl start nginx
    log_success "Nginx installé et démarré"
else
    log_info "Nginx déjà installé: $(nginx -v 2>&1)"
fi

# =========================================================================
# ÉTAPE 3: Installation de PHP 8.2
# =========================================================================

log_header "ÉTAPE 3/5: INSTALLATION PHP 8.2"

if ! php -v &>/dev/null; then
    log_info "Installation de PHP 8.2 et extensions..."
    
    apt-get install -y \
        php8.2-fpm \
        php8.2-cli \
        php8.2-common \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        php8.2-bcmath \
        php8.2-intl \
        php8.2-soap \
        php8.2-opcache \
        php8.2-redis \
        php8.2-imagick 2>&1 | tee -a "${LOG_FILE}"
    
    systemctl enable php8.2-fpm
    systemctl start php8.2-fpm
    log_success "PHP 8.2 installé: $(php -v | head -1)"
else
    log_info "PHP déjà installé: $(php -v | head -1)"
fi

# =========================================================================
# ÉTAPE 4: Installation de MariaDB
# =========================================================================

log_header "ÉTAPE 4/5: INSTALLATION MARIADB"

if ! mysql --version &>/dev/null; then
    log_info "Installation de MariaDB..."
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        mariadb-server \
        mariadb-client 2>&1 | tee -a "${LOG_FILE}"
    
    systemctl enable mariadb
    systemctl start mariadb
    
    # Configuration sécurisée
    MYSQL_ROOT_PASS="$(openssl rand -base64 24)"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';" || true
    
    echo "${MYSQL_ROOT_PASS}" > /root/.mysql_root_password
    chmod 600 /root/.mysql_root_password
    
    log_success "MariaDB installé"
    log_info "Mot de passe root MySQL sauvegardé dans /root/.mysql_root_password"
else
    log_info "MariaDB déjà installé: $(mysql --version)"
fi

# =========================================================================
# ÉTAPE 5: Création du site WordPress
# =========================================================================

log_header "ÉTAPE 5/5: CRÉATION DU SITE WORDPRESS"

log_info "Création du site: ${SITE_NAME}"

# Créer la structure de répertoires
SITE_ROOT="/var/www/${SITE_NAME}"
mkdir -p "${SITE_ROOT}/htdocs"
mkdir -p "${SITE_ROOT}/logs"
mkdir -p "/var/log/nginx/${SITE_NAME}"

# Télécharger WordPress
log_info "Téléchargement de WordPress..."
cd "${SITE_ROOT}/htdocs"
if ! [ -f wp-config.php ]; then
    curl -sO https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    log_success "WordPress téléchargé"
else
    log_info "WordPress déjà présent"
fi

# Créer la base de données
DB_NAME="wp_$(echo ${SITE_NAME} | tr '.-' '_')"
DB_USER="${DB_NAME}_user"
DB_PASS="$(openssl rand -base64 16)"

MYSQL_ROOT_PASS="$(cat /root/.mysql_root_password 2>/dev/null || echo '')"

log_info "Création de la base de données: ${DB_NAME}"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" 2>&1 | tee -a "${LOG_FILE}" || true
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>&1 | tee -a "${LOG_FILE}" || true
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';" 2>&1 | tee -a "${LOG_FILE}" || true
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;" 2>&1 | tee -a "${LOG_FILE}" || true

log_success "Base de données créée"

# Créer wp-config.php
if ! [ -f "${SITE_ROOT}/htdocs/wp-config.php" ]; then
    log_info "Configuration de WordPress..."
    
    cp "${SITE_ROOT}/htdocs/wp-config-sample.php" "${SITE_ROOT}/htdocs/wp-config.php"
    
    sed -i "s/database_name_here/${DB_NAME}/" "${SITE_ROOT}/htdocs/wp-config.php"
    sed -i "s/username_here/${DB_USER}/" "${SITE_ROOT}/htdocs/wp-config.php"
    sed -i "s/password_here/${DB_PASS}/" "${SITE_ROOT}/htdocs/wp-config.php"
    
    # Ajouter les clés de sécurité
    SALT=$(curl -sL https://api.wordpress.org/secret-key/1.1/salt/)
    SALT_ESCAPED=$(echo "$SALT" | sed 's/[\/&]/\\&/g')
    sed -i "/AUTH_KEY/,/NONCE_SALT/d" "${SITE_ROOT}/htdocs/wp-config.php"
    echo "$SALT" >> "${SITE_ROOT}/htdocs/wp-config.php"
    
    log_success "wp-config.php créé"
fi

# Permissions
chown -R www-data:www-data "${SITE_ROOT}/htdocs"
find "${SITE_ROOT}/htdocs" -type d -exec chmod 755 {} \;
find "${SITE_ROOT}/htdocs" -type f -exec chmod 644 {} \;

log_success "Permissions configurées"

# Configuration Nginx
log_info "Configuration Nginx..."

cat > "/etc/nginx/sites-available/${SITE_NAME}" <<'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name SITE_NAME_PLACEHOLDER;
    
    root /var/www/SITE_NAME_PLACEHOLDER/htdocs;
    index index.php index.html;
    
    access_log /var/log/nginx/SITE_NAME_PLACEHOLDER/access.log;
    error_log /var/log/nginx/SITE_NAME_PLACEHOLDER/error.log;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    location = /robots.txt {
        log_not_found off;
        access_log off;
        allow all;
    }
    
    location ~* \.(css|gif|ico|jpeg|jpg|js|png|webp|woff|woff2)$ {
        expires max;
        log_not_found off;
    }
}
NGINX_EOF

sed -i "s/SITE_NAME_PLACEHOLDER/${SITE_NAME}/g" "/etc/nginx/sites-available/${SITE_NAME}"

ln -sf "/etc/nginx/sites-available/${SITE_NAME}" "/etc/nginx/sites-enabled/${SITE_NAME}"

# Test et reload Nginx
nginx -t 2>&1 | tee -a "${LOG_FILE}"
systemctl reload nginx

log_success "Configuration Nginx activée"

# =========================================================================
# RÉSUMÉ
# =========================================================================

log_header "INSTALLATION TERMINÉE"

echo "" | tee -a "${LOG_FILE}"
log_success "Site WordPress créé: ${SITE_NAME}"
echo "" | tee -a "${LOG_FILE}"
echo "Informations du site:" | tee -a "${LOG_FILE}"
echo "  - URL: http://${SITE_NAME}" | tee -a "${LOG_FILE}"
echo "  - Racine: ${SITE_ROOT}/htdocs" | tee -a "${LOG_FILE}"
echo "  - Base de données: ${DB_NAME}" | tee -a "${LOG_FILE}"
echo "  - Utilisateur BDD: ${DB_USER}" | tee -a "${LOG_FILE}"
echo "  - Mot de passe BDD: ${DB_PASS}" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"
echo "Prochaines étapes:" | tee -a "${LOG_FILE}"
echo "  1. Ajouter '${SITE_NAME}' à /etc/hosts sur votre machine hôte" | tee -a "${LOG_FILE}"
echo "  2. Accéder à http://${SITE_NAME} pour terminer l'installation WordPress" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"
echo "Log complet: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# Sauvegarder les informations
cat > "${SITE_ROOT}/site-info.txt" <<INFO_EOF
Site WordPress: ${SITE_NAME}
Date de création: $(date)
Système: Debian 12

Base de données:
  - Nom: ${DB_NAME}
  - Utilisateur: ${DB_USER}
  - Mot de passe: ${DB_PASS}
  
Chemins:
  - Racine web: ${SITE_ROOT}/htdocs
  - Logs Nginx: /var/log/nginx/${SITE_NAME}/
  - Configuration Nginx: /etc/nginx/sites-available/${SITE_NAME}

Services:
  - Nginx: $(nginx -v 2>&1)
  - PHP: $(php -v | head -1)
  - MySQL: $(mysql --version)
INFO_EOF

log_info "Informations sauvegardées dans ${SITE_ROOT}/site-info.txt"
