# =========================================================================
# repro.ps1 - Script PowerShell pour Windows
# =========================================================================
# Purpose: Automatiser les tests WordOps sur Windows avec Docker Desktop
# Usage: .\scripts\repro.ps1 [ubuntu|debian|both] [-Rebuild] [-Interactive]
# =========================================================================

param(
    [ValidateSet('ubuntu', 'debian', 'both')]
    [string]$Target = 'ubuntu',
    
    [switch]$Rebuild,
    [switch]$Interactive,
    [switch]$Help
)

# Configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$LogsDir = Join-Path $ProjectDir "logs"

# Couleurs pour la console
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "=========================================================================" "Cyan"
    Write-ColorOutput "  $Title" "Cyan"
    Write-ColorOutput "=========================================================================" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "[STEP] $Message" "Magenta"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[OK] $Message" "Green"
}

function Write-Warn {
    param([string]$Message)
    Write-ColorOutput "[WARN] $Message" "Yellow"
}

function Write-Fail {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Afficher l'aide
if ($Help) {
    Write-Host @"
Usage: .\scripts\repro.ps1 [TARGET] [OPTIONS]

TARGETS:
    ubuntu      Test sur Ubuntu 22.04 uniquement (défaut)
    debian      Test sur Debian 12 uniquement
    both        Test sur Ubuntu ET Debian

OPTIONS:
    -Rebuild        Rebuild les images Docker
    -Interactive    Lance un shell interactif au lieu d'installer
    -Help           Affiche cette aide

EXEMPLES:
    .\scripts\repro.ps1 ubuntu              # Test Ubuntu avec images en cache
    .\scripts\repro.ps1 debian -Rebuild     # Test Debian avec rebuild
    .\scripts\repro.ps1 both                # Test Ubuntu et Debian
    .\scripts\repro.ps1 ubuntu -Interactive # Shell interactif Ubuntu

LOGS:
    Tous les logs sont sauvegardés dans .\logs\
"@
    exit 0
}

# Fonction pour vérifier Docker
function Test-Docker {
    Write-Step "Checking Docker installation"
    
    # Vérifier Docker
    try {
        $null = docker --version
        Write-Success "Docker is installed"
    } catch {
        Write-Fail "Docker is not installed"
        Write-Info "Please install Docker Desktop: https://www.docker.com/products/docker-desktop/"
        exit 1
    }
    
    # Vérifier que Docker fonctionne
    try {
        $null = docker ps 2>&1
        Write-Success "Docker daemon is running"
    } catch {
        Write-Fail "Docker daemon is not running"
        Write-Info "Please start Docker Desktop"
        exit 1
    }
    
    # Vérifier Docker Compose
    try {
        $null = docker compose version
        Write-Success "Docker Compose is available"
    } catch {
        Write-Fail "Docker Compose is not available"
        Write-Info "Please update Docker Desktop"
        exit 1
    }
}

# Fonction pour configurer le répertoire de logs
function Initialize-LogsDirectory {
    Write-Step "Setting up logs directory"
    
    if (-not (Test-Path $LogsDir)) {
        New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
        Write-Success "Created logs directory: $LogsDir"
    } else {
        # Sauvegarder les anciens logs
        $oldLogs = Get-ChildItem -Path $LogsDir -File -ErrorAction SilentlyContinue
        if ($oldLogs.Count -gt 0) {
            Write-Warn "Logs directory is not empty"
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupDir = Join-Path $LogsDir "backup-$timestamp"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            
            $oldLogs | Move-Item -Destination $backupDir -ErrorAction SilentlyContinue
            Write-Info "Previous logs moved to: backup-$timestamp"
        }
    }
    
    Write-Success "Logs directory ready: $LogsDir"
}

# Fonction pour tester une distribution
function Test-Distribution {
    param(
        [string]$Distro,
        [string]$Profile,
        [string]$ContainerName
    )
    
    Write-Header "TESTING: $Distro"
    
    # Changer vers le répertoire du projet
    Push-Location $ProjectDir
    
    try {
        # Options de build
        $buildOpts = @("--build")
        if ($Rebuild) {
            $buildOpts += @("--force-recreate", "--no-cache")
            Write-Info "Rebuilding images from scratch"
        }
        
        # Mode interactif
        if ($Interactive) {
            Write-Info "Starting interactive shell in $Distro container"
            Write-Info "To install WordOps manually, run: /usr/local/bin/install-wordops.sh"
            Write-Info "To collect system info, run: /usr/local/bin/system-info.sh /logs/manual-info.log"
            
            docker compose --profile $Profile run --rm "$ContainerName" bash
            return 0
        }
        
        # Démarrer le container
        Write-Step "Starting container"
        $composeLog = Join-Path $LogsDir "docker-compose-$Distro.log"
        docker compose --profile $Profile up @buildOpts -d 2>&1 | Tee-Object -FilePath $composeLog
        
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Failed to start $Distro container"
            return 1
        }
        
        # Attendre que systemd soit prêt
        Write-Step "Waiting for systemd to be ready"
        $maxWait = 60
        $waited = 0
        
        while ($waited -lt $maxWait) {
            $systemdStatus = docker exec $ContainerName systemctl is-system-running --wait 2>$null
            if ($systemdStatus -match "running|degraded") {
                Write-Success "Systemd is ready"
                break
            }
            
            Start-Sleep -Seconds 2
            $waited += 2
            
            if ($waited -ge $maxWait) {
                Write-Warn "Systemd took too long to start, continuing anyway"
            }
        }
        
        # Exécuter le script d'installation
        Write-Step "Running WordOps installation"
        
        $installConsoleLog = Join-Path $LogsDir "installation-$Distro-console.log"
        docker exec $ContainerName /usr/local/bin/install-wordops.sh 2>&1 | Tee-Object -FilePath $installConsoleLog
        $installStatus = $LASTEXITCODE
        
        if ($installStatus -eq 0) {
            Write-Success "Installation script completed successfully"
        } else {
            Write-Fail "Installation script failed with exit code: $installStatus"
        }
        
        # Copier les logs du container
        Write-Step "Collecting logs from container"
        
        docker exec $ContainerName bash -c @"
if [ -f /var/log/wo/install.log ]; then
    cp /var/log/wo/install.log /logs/wo-install-internal-$Distro.log
fi
if [ -f /var/log/wo/wordops.log ]; then
    cp /var/log/wo/wordops.log /logs/wo-wordops-$Distro.log
fi
"@ 2>$null
        
        Write-Success "Logs collected in: $LogsDir"
        
        # Résumé
        Write-Header "INSTALLATION SUMMARY: $Distro"
        
        if ($installStatus -eq 0) {
            Write-Success "Installation completed successfully"
            
            # Vérifier WordOps
            $versionLog = Join-Path $LogsDir "wo-version-$Distro.log"
            docker exec $ContainerName wo --version 2>&1 | Tee-Object -FilePath $versionLog
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "WordOps is installed and working"
            } else {
                Write-Warn "WordOps binary found but version check failed"
            }
        } else {
            Write-Fail "Installation failed"
            
            # Analyser les erreurs
            Write-Info "Analyzing errors..."
            
            $woLog = Join-Path $LogsDir "wo-install-$Distro.log"
            if (Test-Path $woLog) {
                Write-Info "Common errors found:"
                
                $content = Get-Content $woLog -Raw
                
                if ($content -match "NO_PUBKEY") {
                    Write-Fail "  - GPG key missing"
                    Select-String -Path $woLog -Pattern "NO_PUBKEY" | Select-Object -First 5
                }
                
                if ($content -match "unmet dependencies") {
                    Write-Fail "  - Unmet dependencies"
                    Select-String -Path $woLog -Pattern "unmet dependencies" -Context 0,2 | Select-Object -First 5
                }
                
                if ($content -match "(404|failed to fetch)") {
                    Write-Fail "  - Repository fetch errors"
                    Select-String -Path $woLog -Pattern "(404|failed to fetch)" | Select-Object -First 5
                }
                
                if ($content -match "could not resolve") {
                    Write-Fail "  - DNS resolution errors"
                    Select-String -Path $woLog -Pattern "could not resolve" | Select-Object -First 5
                }
            }
        }
        
        Write-Info "Container $ContainerName is still running for investigation"
        Write-Info "To access it: docker exec -it $ContainerName bash"
        Write-Info "To stop it: docker compose --profile $Profile down"
        
        return $installStatus
        
    } finally {
        Pop-Location
    }
}

# =========================================================================
# MAIN
# =========================================================================

Write-Header "WORDOPS INSTALLATION REPRODUCTION SCRIPT"

Write-Info "Configuration:"
Write-Info "  - Target: $Target"
Write-Info "  - Rebuild: $Rebuild"
Write-Info "  - Interactive: $Interactive"
Write-Info "  - Project dir: $ProjectDir"
Write-Info "  - Logs dir: $LogsDir"

# Vérifications
Test-Docker
Initialize-LogsDirectory

# Exécuter les tests
$exitCode = 0

switch ($Target) {
    'ubuntu' {
        $exitCode = Test-Distribution "Ubuntu 22.04" "ubuntu" "wordops-ubuntu22-test"
    }
    'debian' {
        $exitCode = Test-Distribution "Debian 12" "debian" "wordops-debian12-test"
    }
    'both' {
        Write-Info "Testing both distributions sequentially"
        
        $ubuntuExit = Test-Distribution "Ubuntu 22.04" "ubuntu" "wordops-ubuntu22-test"
        
        # Nettoyer entre les tests
        docker compose --profile ubuntu down
        
        $debianExit = Test-Distribution "Debian 12" "debian" "wordops-debian12-test"
        
        Write-Header "FINAL SUMMARY"
        
        if ($ubuntuExit -eq 0) {
            Write-Success "Ubuntu 22.04: PASSED"
        } else {
            Write-Fail "Ubuntu 22.04: FAILED"
        }
        
        if ($debianExit -eq 0) {
            Write-Success "Debian 12: PASSED"
        } else {
            Write-Fail "Debian 12: FAILED"
        }
        
        $exitCode = if ($ubuntuExit -eq 0 -and $debianExit -eq 0) { 0 } else { 1 }
    }
}

Write-Header "TEST COMPLETED"

if ($exitCode -eq 0) {
    Write-Success "All tests passed"
} else {
    Write-Fail "Some tests failed"
    Write-Info "Review the logs in: $LogsDir"
}

Write-Info "Containers are still running for investigation"
Write-Info "To clean up manually: docker compose down -v"

exit $exitCode
