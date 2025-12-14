# DevOps Project Prerequisites Installer for Windows
# Run this script as Administrator

Write-Host "🚀 Installing DevOps Project Prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell" -ForegroundColor Yellow
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "3. Navigate to: cd C:\Devops-Project" -ForegroundColor Yellow
    Write-Host "4. Run: .\install-prerequisites.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Function to check if a command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Install Docker Desktop
if (Test-CommandExists docker) {
    Write-Host "✅ Docker already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Docker Desktop..." -ForegroundColor Cyan
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
}

# Install kubectl
if (Test-CommandExists kubectl) {
    Write-Host "✅ kubectl already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing kubectl..." -ForegroundColor Cyan
    winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements
}

# Install Helm
if (Test-CommandExists helm) {
    Write-Host "✅ Helm already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Helm..." -ForegroundColor Cyan
    winget install -e --id Helm.Helm --accept-source-agreements --accept-package-agreements
}

# Install KinD
if (Test-CommandExists kind) {
    Write-Host "✅ KinD already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing KinD..." -ForegroundColor Cyan
    # KinD needs to be downloaded manually as winget doesn't have it
    $kindVersion = "v0.20.0"
    $kindUrl = "https://kind.sigs.k8s.io/dl/$kindVersion/kind-windows-amd64"
    $kindPath = "$env:ProgramFiles\kind"
    
    if (-not (Test-Path $kindPath)) {
        New-Item -ItemType Directory -Path $kindPath -Force | Out-Null
    }
    
    Write-Host "  Downloading KinD $kindVersion..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $kindUrl -OutFile "$kindPath\kind.exe"
    
    # Add to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$kindPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$kindPath", "Machine")
        Write-Host "  Added KinD to system PATH" -ForegroundColor Yellow
    }
}

# Install Terraform
if (Test-CommandExists terraform) {
    Write-Host "✅ Terraform already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Terraform..." -ForegroundColor Cyan
    winget install -e --id Hashicorp.Terraform --accept-source-agreements --accept-package-agreements
}

# Install Python 3.11
if (Test-CommandExists python) {
    $pyVersion = python --version 2>&1
    Write-Host "✅ Python already installed: $pyVersion" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Python 3.11..." -ForegroundColor Cyan
    winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
}

Write-Host ""
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Start Docker Desktop from the Start Menu" -ForegroundColor Cyan
Write-Host "2. Wait for Docker to be fully running (whale icon in system tray)" -ForegroundColor Cyan
Write-Host "3. Close and reopen PowerShell (to refresh PATH)" -ForegroundColor Cyan
Write-Host "4. Navigate back to: cd C:\Devops-Project" -ForegroundColor Cyan
Write-Host "5. Verify installation: docker --version" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then you can run: make all (or follow README instructions)" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
