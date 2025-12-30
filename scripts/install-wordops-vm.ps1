#!/usr/bin/env pwsh
# Script d'installation automatique de WordOps sur VM Debian 12

$VM_IP = "192.168.0.25"
$VM_USER = "sebastien"
$VM_PASS = "toor"

Write-Host "=== Installation de WordOps sur VM $VM_IP ===" -ForegroundColor Cyan

# Fonction pour exécuter des commandes SSH avec mot de passe
function Invoke-SSHCommand {
    param(
        [string]$Command
    )
    
    $plink = "echo $VM_PASS | ssh -o StrictHostKeyChecking=no $VM_USER@$VM_IP `"$Command`""
    Write-Host "Executing: $Command" -ForegroundColor Gray
    Invoke-Expression $plink
}

# Étape 1: Cloner le repository
Write-Host "`n[1/4] Clonage du repository..." -ForegroundColor Yellow
$cloneCmd = @"
cd /tmp && rm -rf wordops-docker-testing && git clone https://github.com/sebafrench/wordops-docker-testing.git
"@

# Utiliser plink ou une autre méthode
$securePassword = ConvertTo-SecureString $VM_PASS -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($VM_USER, $securePassword)

# Exécuter via SSH avec expect ou script batch
$script = @"
cd /tmp
rm -rf wordops-docker-testing
git clone https://github.com/sebafrench/wordops-docker-testing.git
echo toor | sudo -S bash /tmp/wordops-docker-testing/scripts/install-wordops.sh
"@

# Sauvegarder le script localement
$script | Out-File -FilePath ".\temp-install.sh" -Encoding ASCII

Write-Host "Script préparé. Veuillez exécuter manuellement sur la VM:" -ForegroundColor Green
Write-Host "ssh $VM_USER@$VM_IP" -ForegroundColor Cyan
Write-Host "Puis copier-coller ces commandes:" -ForegroundColor Cyan
Write-Host $script -ForegroundColor White
