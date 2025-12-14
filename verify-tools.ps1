# DevOps Tools Verification Script
Write-Host ""
Write-Host "=== DevOps Tools Verification ===" -ForegroundColor Cyan
Write-Host ""

$tools = @(
    @{Name="Docker"; Command="docker --version"},
    @{Name="KinD"; Command="kind version"},
    @{Name="Helm"; Command="helm version --short"},
    @{Name="kubectl"; Command="kubectl version --client --short"},
    @{Name="Terraform"; Command="terraform --version"},
    @{Name="Python"; Command="python --version"}
)

foreach ($tool in $tools) {
    Write-Host "$($tool.Name): " -NoNewline -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $tool.Command 2>&1
        if ($result) {
            Write-Host "OK" -ForegroundColor Green
            Write-Host "  $result" -ForegroundColor Gray
        } else {
            Write-Host "NOT FOUND" -ForegroundColor Red
        }
    } catch {
        Write-Host "NOT FOUND" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "If all tools show OK, run:" -ForegroundColor Yellow
Write-Host "  make all" -ForegroundColor Green
Write-Host ""
