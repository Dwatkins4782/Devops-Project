# Continue deployment - Observability and Application
$helmPath = "C:\Users\davon\AppData\Local\Microsoft\WinGet\Packages\Helm.Helm_Microsoft.Winget.Source_8wekyb3d8bbwe\windows-amd64\helm.exe"

Write-Host ""
Write-Host "=== Deploying Observability Stack ===" -ForegroundColor Cyan
Write-Host "This will take 3-5 minutes..." -ForegroundColor Yellow
Write-Host ""

& $helmPath upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false `
  --set grafana.service.type=ClusterIP `
  --wait --timeout 10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Observability deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Prometheus + Grafana deployed!" -ForegroundColor Green
Write-Host ""

# Deploy Application
Write-Host "=== Deploying Flask Application ===" -ForegroundColor Cyan
kubectl create namespace app 2>$null

& $helmPath upgrade --install devops-app ./helm/app `
  --namespace app `
  --set image.repository=localhost:5555/devops-app `
  --set image.tag=latest `
  --set serviceMonitor.enabled=true `
  --wait --timeout 5m

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Application deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Application deployed!" -ForegroundColor Green
Write-Host ""

# Verify
Write-Host "=== Verifying Deployment ===" -ForegroundColor Cyan
kubectl wait --for=condition=available --timeout=300s deployment/devops-app -n app 2>$null
kubectl get pods -n app
kubectl get svc -n app

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n app svc/devops-app 8080:80" -ForegroundColor White
Write-Host "  Then visit: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "Access Grafana:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" -ForegroundColor White
Write-Host "  Then visit: http://localhost:3000" -ForegroundColor White
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: prom-operator" -ForegroundColor White
Write-Host ""
Write-Host "Access Prometheus:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090" -ForegroundColor White
Write-Host "  Then visit: http://localhost:9090" -ForegroundColor White
Write-Host ""
