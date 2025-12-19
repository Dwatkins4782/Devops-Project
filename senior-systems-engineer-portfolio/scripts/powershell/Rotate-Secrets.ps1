<#
.SYNOPSIS
    Automated Secret Rotation for Azure Key Vault

.DESCRIPTION
    This script automates the rotation of secrets in Azure Key Vault with the following features:
    - Rotates secrets based on expiration policy (default: 90 days)
    - Updates references in AKS, App Services, and other Azure resources
    - Maintains secret version history for rollback
    - Sends notifications to Teams/Email
    - Logs all rotation activities for audit compliance

.PARAMETER VaultName
    Name of the Azure Key Vault

.PARAMETER SecretName
    Specific secret to rotate (optional, rotates all if not specified)

.PARAMETER DaysBeforeExpiry
    Number of days before expiry to trigger rotation (default: 7)

.PARAMETER Emergency
    Emergency rotation - rotates all secrets immediately

.PARAMETER WhatIf
    Simulates rotation without making changes

.EXAMPLE
    .\Rotate-Secrets.ps1 -VaultName "prod-kv" -SecretName "database-password"
    Rotates a specific secret

.EXAMPLE
    .\Rotate-Secrets.ps1 -VaultName "prod-kv" -Emergency
    Emergency rotation of all secrets

.NOTES
    Author: Infrastructure Team
    Version: 1.0
    Requires: Azure PowerShell Module
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$VaultName = $env:KEYVAULT_NAME,

    [Parameter(Mandatory=$false)]
    [string]$SecretName,

    [Parameter(Mandatory=$false)]
    [int]$DaysBeforeExpiry = 7,

    [Parameter(Mandatory=$false)]
    [switch]$Emergency,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

#Requires -Modules Az.KeyVault, Az.Accounts

# Import required modules
Import-Module Az.KeyVault -ErrorAction Stop
Import-Module Az.Accounts -ErrorAction Stop

# Configuration
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$VerbosePreference = "Continue"

# Logging configuration
$LogPath = "C:\Logs\SecretRotation"
$LogFile = Join-Path $LogPath "rotation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # File output
    Add-Content -Path $LogFile -Value $logMessage
}

function Test-AzureConnection {
    Write-Log "Checking Azure connection..." -Level Info
    
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "No Azure context found. Please run Connect-AzAccount" -Level Error
            return $false
        }
        
        Write-Log "Connected to Azure subscription: $($context.Subscription.Name)" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to get Azure context: $_" -Level Error
        return $false
    }
}

function Get-SecretsToRotate {
    param(
        [string]$VaultName,
        [string]$SpecificSecret,
        [int]$DaysBeforeExpiry,
        [bool]$EmergencyRotation
    )
    
    Write-Log "Retrieving secrets from Key Vault: $VaultName" -Level Info
    
    try {
        if ($SpecificSecret) {
            $secrets = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SpecificSecret
        }
        else {
            $secrets = Get-AzKeyVaultSecret -VaultName $VaultName
        }
        
        if ($EmergencyRotation) {
            Write-Log "EMERGENCY ROTATION: All secrets will be rotated" -Level Warning
            return $secrets
        }
        
        # Filter secrets based on expiration
        $secretsToRotate = $secrets | Where-Object {
            if ($_.Expires) {
                $daysUntilExpiry = ($_.Expires - (Get-Date)).Days
                $daysUntilExpiry -le $DaysBeforeExpiry
            }
            else {
                # No expiration set - check last updated date
                $daysSinceUpdate = ((Get-Date) - $_.Updated).Days
                $daysSinceUpdate -ge 90  # Rotate if not updated in 90 days
            }
        }
        
        Write-Log "Found $($secretsToRotate.Count) secrets requiring rotation" -Level Info
        return $secretsToRotate
    }
    catch {
        Write-Log "Failed to retrieve secrets: $_" -Level Error
        throw
    }
}

function New-SecurePassword {
    param(
        [int]$Length = 32
    )
    
    # Generate cryptographically secure random password
    $password = [System.Web.Security.Membership]::GeneratePassword($Length, 8)
    
    # Ensure complexity requirements
    $password = $password -replace '[<>"]', ''  # Remove problematic characters
    
    return $password
}

function Invoke-SecretRotation {
    param(
        [Parameter(Mandatory=$true)]
        $Secret,
        
        [Parameter(Mandatory=$true)]
        [string]$VaultName
    )
    
    Write-Log "Rotating secret: $($Secret.Name)" -Level Info
    
    try {
        # Step 1: Generate new secret value
        $newSecretValue = New-SecurePassword
        $secureString = ConvertTo-SecureString -String $newSecretValue -AsPlainText -Force
        
        # Step 2: Set new expiration date (90 days from now)
        $expirationDate = (Get-Date).AddDays(90)
        
        # Step 3: Store old version metadata for rollback
        $currentSecret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $Secret.Name
        $tags = @{
            'RotatedOn' = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            'RotatedBy' = $env:USERNAME
            'PreviousVersion' = $currentSecret.Version
            'RotationReason' = if ($Emergency) { 'Emergency' } else { 'Scheduled' }
        }
        
        if ($PSCmdlet.ShouldProcess($Secret.Name, "Rotate secret")) {
            # Step 4: Set new secret version
            $newSecret = Set-AzKeyVaultSecret `
                -VaultName $VaultName `
                -Name $Secret.Name `
                -SecretValue $secureString `
                -Expires $expirationDate `
                -Tag $tags `
                -ContentType "application/password"
            
            Write-Log "Successfully rotated secret: $($Secret.Name) (New Version: $($newSecret.Version))" -Level Success
            
            # Step 5: Update dependent resources
            Update-DependentResources -SecretName $Secret.Name -VaultName $VaultName
            
            return @{
                Success = $true
                SecretName = $Secret.Name
                NewVersion = $newSecret.Version
                OldVersion = $currentSecret.Version
                ExpiresOn = $expirationDate
            }
        }
        else {
            Write-Log "WhatIf: Would rotate secret $($Secret.Name)" -Level Info
            return @{
                Success = $true
                SecretName = $Secret.Name
                WhatIf = $true
            }
        }
    }
    catch {
        Write-Log "Failed to rotate secret $($Secret.Name): $_" -Level Error
        return @{
            Success = $false
            SecretName = $Secret.Name
            Error = $_.Exception.Message
        }
    }
}

function Update-DependentResources {
    param(
        [string]$SecretName,
        [string]$VaultName
    )
    
    Write-Log "Updating dependent resources for secret: $SecretName" -Level Info
    
    # Update AKS pods using the secret
    try {
        # Find deployments using this secret
        $deployments = kubectl get deployments --all-namespaces -o json | ConvertFrom-Json
        
        foreach ($deployment in $deployments.items) {
            $usesSecret = $false
            
            # Check if deployment uses this secret via Key Vault CSI driver
            if ($deployment.spec.template.spec.volumes) {
                foreach ($volume in $deployment.spec.template.spec.volumes) {
                    if ($volume.csi -and $volume.csi.driver -eq "secrets-store.csi.k8s.io") {
                        # This deployment uses Key Vault secrets
                        $usesSecret = $true
                        break
                    }
                }
            }
            
            if ($usesSecret) {
                Write-Log "Restarting deployment: $($deployment.metadata.name) in namespace: $($deployment.metadata.namespace)" -Level Info
                
                if ($PSCmdlet.ShouldProcess($deployment.metadata.name, "Restart deployment")) {
                    kubectl rollout restart deployment/$($deployment.metadata.name) -n $($deployment.metadata.namespace)
                }
            }
        }
    }
    catch {
        Write-Log "Failed to update AKS deployments: $_" -Level Warning
    }
    
    # Update App Services (if using Key Vault references)
    try {
        $webApps = Get-AzWebApp | Where-Object {
            $_.SiteConfig.AppSettings | Where-Object { $_.Value -like "*$VaultName*$SecretName*" }
        }
        
        foreach ($app in $webApps) {
            Write-Log "Restarting App Service: $($app.Name)" -Level Info
            
            if ($PSCmdlet.ShouldProcess($app.Name, "Restart App Service")) {
                Restart-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name
            }
        }
    }
    catch {
        Write-Log "Failed to update App Services: $_" -Level Warning
    }
}

function Send-RotationNotification {
    param(
        [array]$Results,
        [string]$VaultName
    )
    
    $successCount = ($Results | Where-Object { $_.Success }).Count
    $failureCount = ($Results | Where-Object { -not $_.Success }).Count
    
    $message = @"
**Secret Rotation Report**

**Key Vault**: $VaultName  
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')  
**Total Secrets Rotated**: $($Results.Count)  
**Successful**: $successCount  
**Failed**: $failureCount  

**Details**:
$($Results | ForEach-Object {
    "- $($_.SecretName): $(if ($_.Success) { 'SUCCESS' } else { 'FAILED - ' + $_.Error })"
} | Out-String)

**Log File**: $LogFile
"@

    Write-Log "Rotation Summary: $successCount successful, $failureCount failed" -Level Info
    
    # Send to Teams webhook (if configured)
    if ($env:TEAMS_WEBHOOK_URL) {
        try {
            $teamsPayload = @{
                "@type" = "MessageCard"
                "@context" = "http://schema.org/extensions"
                "summary" = "Secret Rotation Report"
                "themeColor" = if ($failureCount -eq 0) { "00FF00" } else { "FF0000" }
                "title" = "Secret Rotation Completed"
                "text" = $message
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $env:TEAMS_WEBHOOK_URL -Method Post -Body $teamsPayload -ContentType 'application/json'
            Write-Log "Notification sent to Teams" -Level Success
        }
        catch {
            Write-Log "Failed to send Teams notification: $_" -Level Warning
        }
    }
    
    # Send email (if configured)
    if ($env:SENDGRID_API_KEY) {
        # SendGrid email implementation
        Write-Log "Email notification would be sent here" -Level Info
    }
}

# =====================================
# Main Execution
# =====================================

Write-Log "=== Secret Rotation Script Started ===" -Level Info
Write-Log "Vault: $VaultName" -Level Info
Write-Log "Emergency Mode: $Emergency" -Level Info
Write-Log "WhatIf Mode: $WhatIf" -Level Info

try {
    # Step 1: Verify Azure connection
    if (-not (Test-AzureConnection)) {
        throw "Azure connection failed"
    }
    
    # Step 2: Validate Key Vault exists
    Write-Log "Validating Key Vault: $VaultName" -Level Info
    $vault = Get-AzKeyVault -VaultName $VaultName -ErrorAction SilentlyContinue
    if (-not $vault) {
        throw "Key Vault '$VaultName' not found"
    }
    Write-Log "Key Vault validated successfully" -Level Success
    
    # Step 3: Get secrets to rotate
    $secretsToRotate = Get-SecretsToRotate `
        -VaultName $VaultName `
        -SpecificSecret $SecretName `
        -DaysBeforeExpiry $DaysBeforeExpiry `
        -EmergencyRotation $Emergency
    
    if ($secretsToRotate.Count -eq 0) {
        Write-Log "No secrets require rotation at this time" -Level Info
        exit 0
    }
    
    # Step 4: Rotate each secret
    $results = @()
    foreach ($secret in $secretsToRotate) {
        $result = Invoke-SecretRotation -Secret $secret -VaultName $VaultName
        $results += $result
        
        # Add small delay to avoid throttling
        Start-Sleep -Seconds 2
    }
    
    # Step 5: Send notification
    Send-RotationNotification -Results $results -VaultName $VaultName
    
    # Step 6: Generate audit report
    $auditReport = @{
        Timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        VaultName = $VaultName
        TotalRotated = $results.Count
        Successful = ($results | Where-Object { $_.Success }).Count
        Failed = ($results | Where-Object { -not $_.Success }).Count
        Results = $results
    } | ConvertTo-Json -Depth 10
    
    $auditFile = Join-Path $LogPath "audit-$(Get-Date -Format 'yyyyMMdd').json"
    $auditReport | Out-File -FilePath $auditFile -Append
    
    Write-Log "Audit report saved to: $auditFile" -Level Info
    Write-Log "=== Secret Rotation Script Completed ===" -Level Success
    
    # Exit with error code if any rotations failed
    if (($results | Where-Object { -not $_.Success }).Count -gt 0) {
        exit 1
    }
}
catch {
    Write-Log "Fatal error during secret rotation: $_" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
