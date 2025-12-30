# =========================================================================
# check-setup.ps1 - Vérification de l'environnement WordOps Docker Testing
# =========================================================================
# Purpose: Valider que tous les composants sont en place et fonctionnels
# Usage: .\scripts\check-setup.ps1
# =========================================================================

$ErrorActionPreference = "Continue"

# Couleurs
function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Write-Check { param([string]$Msg) Write-ColorOutput "[CHECK] $Msg" "Cyan" }
function Write-OK { param([string]$Msg) Write-ColorOutput "  ✓ $Msg" "Green" }
function Write-FAIL { param([string]$Msg) Write-ColorOutput "  ✗ $Msg" "Red" }
function Write-WARN { param([string]$Msg) Write-ColorOutput "  ⚠ $Msg" "Yellow" }

$script:checks_passed = 0
$script:checks_failed = 0
$script:checks_warned = 0

Write-Host ""
Write-ColorOutput "=========================================================================" "Cyan"
Write-ColorOutput "  WordOps Docker Testing - Vérification de Configuration" "Cyan"
Write-ColorOutput "=========================================================================" "Cyan"
Write-Host ""

# =========================================================================
# 1. Vérifier Docker
# =========================================================================
Write-Check "Docker Installation"

try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker installé: $dockerVersion"
        $script:checks_passed++
    } else {
        Write-FAIL "Docker non trouvé"
        $script:checks_failed++
    }
} catch {
    Write-FAIL "Docker non installé"
    Write-Host "  → Installer: https://www.docker.com/products/docker-desktop/"
    $script:checks_failed++
}

try {
    $null = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker daemon actif"
        $script:checks_passed++
    } else {
        Write-FAIL "Docker daemon non actif"
        Write-Host "  → Démarrer Docker Desktop"
        $script:checks_failed++
    }
} catch {
    Write-FAIL "Docker daemon non accessible"
    $script:checks_failed++
}

try {
    $composeVersion = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Docker Compose disponible: $composeVersion"
        $script:checks_passed++
    } else {
        Write-FAIL "Docker Compose non trouvé"
        $script:checks_failed++
    }
} catch {
    Write-FAIL "Docker Compose non disponible"
    $script:checks_failed++
}

# =========================================================================
# 2. Vérifier les Fichiers Docker
# =========================================================================
Write-Host ""
Write-Check "Fichiers Docker"

$dockerFiles = @(
    "Dockerfile.ubuntu22",
    "Dockerfile.debian12",
    "docker-compose.yml",
    ".dockerignore"
)

foreach ($file in $dockerFiles) {
    if (Test-Path $file) {
        Write-OK "$file existe"
        $script:checks_passed++
    } else {
        Write-FAIL "$file manquant"
        $script:checks_failed++
    }
}

# Valider docker-compose.yml
if (Test-Path "docker-compose.yml") {
    try {
        $null = docker compose config --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "docker-compose.yml est valide"
            $script:checks_passed++
        } else {
            Write-FAIL "docker-compose.yml contient des erreurs"
            $script:checks_failed++
        }
    } catch {
        Write-WARN "Impossible de valider docker-compose.yml"
        $script:checks_warned++
    }
}

# =========================================================================
# 3. Vérifier les Scripts
# =========================================================================
Write-Host ""
Write-Check "Scripts d'Automatisation"

$scripts = @(
    "scripts/repro.ps1",
    "scripts/repro.sh",
    "scripts/install-wordops.sh",
    "scripts/system-info.sh",
    "scripts/apt-debug-commands.sh",
    "scripts/check-setup.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        $size = (Get-Item $script).Length
        Write-OK "$script existe ($size bytes)"
        $script:checks_passed++
    } else {
        Write-FAIL "$script manquant"
        $script:checks_failed++
    }
}

# =========================================================================
# 4. Vérifier la Documentation
# =========================================================================
Write-Host ""
Write-Check "Documentation"

$docs = @(
    "README-TESTING.md",
    "WINDOWS-QUICKSTART.md",
    "QUICKSTART.md",
    "STATUS.md",
    "EXECUTIVE-SUMMARY.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-OK "$doc existe"
        $script:checks_passed++
    } else {
        Write-WARN "$doc manquant (optionnel)"
        $script:checks_warned++
    }
}

# =========================================================================
# 5. Vérifier le Répertoire Logs
# =========================================================================
Write-Host ""
Write-Check "Infrastructure"

if (Test-Path "logs") {
    Write-OK "Répertoire logs/ existe"
    $script:checks_passed++
    
    $logCount = (Get-ChildItem -Path "logs" -File -ErrorAction SilentlyContinue).Count
    if ($logCount -gt 0) {
        Write-WARN "logs/ contient $logCount fichier(s) (anciens tests?)"
        $script:checks_warned++
    } else {
        Write-OK "logs/ est vide (prêt pour nouveaux tests)"
        $script:checks_passed++
    }
} else {
    Write-WARN "Répertoire logs/ manquant (sera créé automatiquement)"
    $script:checks_warned++
}

# =========================================================================
# 6. Vérifier les Images Docker Existantes
# =========================================================================
Write-Host ""
Write-Check "Images Docker"

$images = docker images --format "{{.Repository}}:{{.Tag}}" 2>&1 | Select-String "wordops-test"

if ($images) {
    Write-OK "Images WordOps trouvées:"
    $images | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor Gray
    }
    $script:checks_passed++
} else {
    Write-WARN "Aucune image WordOps (seront créées au premier build)"
    $script:checks_warned++
}

# =========================================================================
# 7. Vérifier les Containers Actifs
# =========================================================================
Write-Host ""
Write-Check "Containers Docker"

$containers = docker ps --format "{{.Names}}" 2>&1 | Select-String "wordops"

if ($containers) {
    Write-WARN "Containers WordOps actifs:"
    $containers | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor Yellow
    }
    Write-Host "  → Utilisez 'docker compose down' pour les arrêter"
    $script:checks_warned++
} else {
    Write-OK "Aucun container actif (prêt pour nouveaux tests)"
    $script:checks_passed++
}

# =========================================================================
# 8. Test de Syntaxe PowerShell
# =========================================================================
Write-Host ""
Write-Check "Syntaxe PowerShell"

try {
    $null = Get-Command .\scripts\repro.ps1 -ErrorAction Stop
    Write-OK "scripts/repro.ps1 a une syntaxe valide"
    $script:checks_passed++
} catch {
    Write-FAIL "scripts/repro.ps1 contient des erreurs de syntaxe"
    $script:checks_failed++
}

try {
    $null = Get-Command .\scripts\check-setup.ps1 -ErrorAction Stop
    Write-OK "scripts/check-setup.ps1 a une syntaxe valide"
    $script:checks_passed++
} catch {
    Write-FAIL "scripts/check-setup.ps1 contient des erreurs de syntaxe"
    $script:checks_failed++
}

# =========================================================================
# Résumé Final
# =========================================================================
Write-Host ""
Write-ColorOutput "=========================================================================" "Cyan"
Write-ColorOutput "  RÉSUMÉ DE LA VÉRIFICATION" "Cyan"
Write-ColorOutput "=========================================================================" "Cyan"
Write-Host ""

Write-ColorOutput "  ✓ Vérifications passées : $script:checks_passed" "Green"
Write-ColorOutput "  ⚠ Avertissements        : $script:checks_warned" "Yellow"
Write-ColorOutput "  ✗ Échecs                : $script:checks_failed" "Red"

Write-Host ""

if ($script:checks_failed -eq 0) {
    Write-ColorOutput "=========================================================================" "Green"
    Write-ColorOutput "  ✓ ENVIRONNEMENT PRÊT !" "Green"
    Write-ColorOutput "=========================================================================" "Green"
    Write-Host ""
    Write-ColorOutput "Vous pouvez maintenant lancer les tests:" "White"
    Write-Host ""
    Write-ColorOutput "  .\scripts\repro.ps1 ubuntu" "Cyan"
    Write-Host ""
    
    if ($script:checks_warned -gt 0) {
        Write-ColorOutput "Note: Les avertissements ci-dessus sont normaux et n'empêchent pas l'utilisation." "Yellow"
        Write-Host ""
    }
    
    exit 0
} else {
    Write-ColorOutput "=========================================================================" "Red"
    Write-ColorOutput "  ✗ CONFIGURATION INCOMPLÈTE" "Red"
    Write-ColorOutput "=========================================================================" "Red"
    Write-Host ""
    Write-ColorOutput "Veuillez corriger les erreurs ci-dessus avant de continuer." "Red"
    Write-Host ""
    Write-ColorOutput "Actions recommandées:" "Yellow"
    
    if ($script:checks_failed -gt 0) {
        Write-Host "  1. Vérifier que Docker Desktop est installé et démarré"
        Write-Host "  2. Vérifier que tous les fichiers sont présents"
        Write-Host "  3. Consulter WINDOWS-QUICKSTART.md pour les instructions"
    }
    
    Write-Host ""
    exit 1
}
