#!/bin/bash
# Remplacer la ligne vide email = par email = admin@intranet.local
sed -i '/^email =$/c\email = admin@intranet.local' /etc/wo/wo.conf
