#!/bin/bash
# Script pour configurer les dépôts Debian

# Désactiver le CD-ROM
sed -i 's/^deb cdrom/#deb cdrom/g' /etc/apt/sources.list

# Ajouter les dépôts en ligne s'ils ne sont pas déjà présents
if ! grep -q "deb.debian.org" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list
fi

# Mettre à jour et installer les dépendances
apt update
apt install -y git wget curl sudo

# Ajouter l'utilisateur sebastien au groupe sudo
usermod -aG sudo sebastien

echo "Configuration terminée!"
