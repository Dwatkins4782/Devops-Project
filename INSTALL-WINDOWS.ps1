# Quick Installation Guide - Run as Administrator
# Copy and paste these commands one at a time into Administrator PowerShell

Write-Host "Installing DevOps Prerequisites with winget..." -ForegroundColor Cyan
Write-Host ""

# Docker Desktop
Write-Host "1. Installing Docker Desktop..." -ForegroundColor Yellow
winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements

# kubectl
Write-Host "2. Installing kubectl..." -ForegroundColor Yellow
winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements

# Helm
Write-Host "3. Installing Helm..." -ForegroundColor Yellow
winget install -e --id Helm.Helm --accept-source-agreements --accept-package-agreements

# Terraform
Write-Host "4. Installing Terraform..." -ForegroundColor Yellow
winget install -e --id Hashicorp.Terraform --accept-source-agreements --accept-package-agreements

# Python
Write-Host "5. Installing Python 3.11..." -ForegroundColor Yellow
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements

# KinD (manual download)
Write-Host "6. Installing KinD..." -ForegroundColor Yellow
$kindUrl = "https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64"
$kindDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
Invoke-WebRequest -Uri $kindUrl -OutFile "$kindDir\kind.exe"
Write-Host "   KinD installed to: $kindDir\kind.exe" -ForegroundColor Green

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Start Docker Desktop" -ForegroundColor White
Write-Host "2. Close and reopen PowerShell" -ForegroundColor White
Write-Host "3. Run: docker --version" -ForegroundColor White
